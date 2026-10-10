// Viewportix sync agent (S3 draft): anchor-based scroll sync.
//
// Runs in an isolated content world, so page scripts cannot see or break it; the DOM is shared.
// The leader viewport describes "what is at the top of my screen" as anchor candidates
// (selector + how far through the element the reading line is). Followers scroll so the same
// point of the same element sits on their own reading line, which adapts to their own
// sticky/fixed header height. Falls back to scroll percentage when no candidate resolves.
(() => {
  if (window.__viewportix) return;

  const PROBE_GAP = 8;          // reading line sits this far below fixed/sticky headers
  const MIN_HEIGHT = 16;        // ignore hairlines and inline fragments
  const MAX_HEIGHT_VIEWPORTS = 3; // ignore page-sized wrappers; they anchor nothing
  const MAX_CANDIDATES = 4;

  let applying = false;
  let pending = false;

  const scroller = () => document.scrollingElement || document.documentElement;
  const maxScroll = () => Math.max(0, scroller().scrollHeight - innerHeight);

  function pinnedAncestor(el) {
    for (let node = el; node && node !== document.body && node !== document.documentElement; node = node.parentElement) {
      const position = getComputedStyle(node).position;
      if (position === 'fixed' || position === 'sticky') return node;
    }
    return null;
  }

  // Bottom edge of fixed/sticky bars covering the top of the viewport (headers, nav).
  function topObstruction() {
    let bottom = 0;
    for (const x of [innerWidth * 0.25, innerWidth * 0.5, innerWidth * 0.75]) {
      for (const el of document.elementsFromPoint(x, 1)) {
        const pinned = pinnedAncestor(el);
        if (!pinned) continue;
        const rect = pinned.getBoundingClientRect();
        if (rect.top <= 1 && rect.bottom < innerHeight * 0.4) bottom = Math.max(bottom, rect.bottom);
      }
    }
    return bottom;
  }

  function uniqueSelector(selector) {
    try { return document.querySelectorAll(selector).length === 1; } catch { return false; }
  }

  // Stable-first: unique id, test attributes, then a structural path rooted at the nearest unique id.
  function selectorFor(el) {
    if (el.id && uniqueSelector('#' + CSS.escape(el.id))) return '#' + CSS.escape(el.id);
    for (const attr of ['data-testid', 'data-test', 'data-qa', 'data-cy']) {
      const value = el.getAttribute(attr);
      if (value) {
        const selector = `[${attr}="${CSS.escape(value)}"]`;
        if (uniqueSelector(selector)) return selector;
      }
    }
    const parts = [];
    for (let node = el; node && node.nodeType === 1 && node !== document.documentElement; node = node.parentElement) {
      if (node !== el && node.id && uniqueSelector('#' + CSS.escape(node.id))) {
        parts.unshift('#' + CSS.escape(node.id));
        return parts.join(' > ');
      }
      let index = 1;
      for (let sibling = node.previousElementSibling; sibling; sibling = sibling.previousElementSibling) {
        if (sibling.tagName === node.tagName) index++;
      }
      parts.unshift(`${node.tagName.toLowerCase()}:nth-of-type(${index})`);
    }
    return 'html > ' + parts.join(' > ');
  }

  function isUsable(el) {
    if (!el || el === document.body || el === document.documentElement) return false;
    if (pinnedAncestor(el)) return false;
    const rect = el.getBoundingClientRect();
    return rect.height >= MIN_HEIGHT && rect.height <= innerHeight * MAX_HEIGHT_VIEWPORTS && rect.width > 0;
  }

  function captureAnchor() {
    const max = maxScroll();
    const y = scroller().scrollTop;
    const percent = max > 0 ? y / max : 0;
    if (y <= 2) return { edge: 'top', percent };
    if (y >= max - 2) return { edge: 'bottom', percent };

    const line = topObstruction() + PROBE_GAP;
    const picked = [];
    for (const x of [innerWidth * 0.5, innerWidth * 0.3, innerWidth * 0.7]) {
      const el = document.elementsFromPoint(x, line).find(isUsable);
      if (!el || picked.includes(el)) continue;
      picked.push(el);
      // Ancestors make a fallback chain when the deepest element moves or disappears at other widths.
      for (let parent = el.parentElement; parent && picked.length < MAX_CANDIDATES; parent = parent.parentElement) {
        if (isUsable(parent) && !picked.includes(parent)) picked.push(parent);
      }
      if (picked.length >= MAX_CANDIDATES) break;
    }

    const candidates = picked.slice(0, MAX_CANDIDATES).map((el) => {
      const rect = el.getBoundingClientRect();
      const selector = selectorFor(el);
      return { selector, ratio: (line - rect.top) / rect.height, strong: !selector.includes(':nth-of-type') };
    });
    return { candidates, section: captureSection(line), percent };
  }

  // --- Section anchor: nearest heading above the reading line, matched by text ---
  // Survives a different DOM at another width or user agent (m. sites, collapsed sections,
  // re-rendered React trees), as long as the headings read the same.

  const CHROME = 'nav, header, footer, aside, [role=navigation], [role=banner], [role=complementary], [role=contentinfo]';
  const normalize = (text) => text.replace(/\s+/g, ' ').trim().slice(0, 120);
  const absoluteTop = (el) => el.getBoundingClientRect().top + scroller().scrollTop;

  function headings() {
    return [...document.querySelectorAll('h1, h2, h3, h4, h5, h6')].filter((h) => {
      if (pinnedAncestor(h) || h.closest(CHROME)) return false;
      const rect = h.getBoundingClientRect();
      return rect.width > 0 && rect.height > 0 && normalize(h.textContent).length > 0;
    });
  }

  function sectionBounds(list, index) {
    const start = absoluteTop(list[index]);
    const end = index + 1 < list.length ? absoluteTop(list[index + 1]) : scroller().scrollHeight;
    return [start, Math.max(start + 1, end)];
  }

  function captureSection(line) {
    const list = headings();
    const lineY = scroller().scrollTop + line;
    let index = -1;
    list.forEach((h, i) => { if (absoluteTop(h) <= lineY) index = i; });
    if (index < 0) return null;
    const text = normalize(list[index].textContent);
    const occurrence = list.slice(0, index).filter((h) => normalize(h.textContent) === text).length;
    const [start, end] = sectionBounds(list, index);
    return { text, occurrence, ratio: (lineY - start) / (end - start) };
  }

  function applySection(section, line) {
    const list = headings();
    const matches = list.filter((h) => normalize(h.textContent) === section.text);
    const heading = matches[section.occurrence] || matches[0];
    if (!heading) return false;
    const [start, end] = sectionBounds(list, list.indexOf(heading));
    scrollToY(start + section.ratio * (end - start) - line);
    return true;
  }

  function scrollToY(y) {
    applying = true;
    scroller().scrollTo({ top: y, behavior: 'instant' });
    // Our own scroll events fire asynchronously; stay quiet until they have passed.
    requestAnimationFrame(() => requestAnimationFrame(() => { applying = false; }));
  }

  function applyAnchor(anchor) {
    if (anchor.edge === 'top') { scrollToY(0); return 'edge:top'; }
    if (anchor.edge === 'bottom') { scrollToY(maxScroll()); return 'edge:bottom'; }

    const line = topObstruction() + PROBE_GAP;
    const candidates = anchor.candidates || [];
    // Stable selectors first; a structural path may resolve to the wrong element in a different DOM,
    // so the heading match outranks it.
    if (applyCandidates(candidates.filter((c) => c.strong), line)) return 'anchor:strong';
    if (anchor.section && applySection(anchor.section, line)) return 'section';
    if (applyCandidates(candidates.filter((c) => !c.strong), line)) return 'anchor:structural';
    scrollToY(anchor.percent * maxScroll());
    return 'percent';
  }

  function applyCandidates(candidates, line) {
    for (const candidate of candidates) {
      let el;
      try { el = document.querySelector(candidate.selector); } catch { continue; }
      if (!el || pinnedAncestor(el)) continue;
      const rect = el.getBoundingClientRect();
      if (rect.width === 0 && rect.height === 0) continue; // display: none at this width
      scrollToY(scroller().scrollTop + rect.top + candidate.ratio * rect.height - line);
      return true;
    }
    return false;
  }

  function applyPercent(percent) {
    scrollToY(percent * maxScroll());
    return 'percent';
  }

  // --- Measurement helpers for the spike's self-test ---

  // What the user is reading: content blocks down the middle column, in the top 40% of the screen.
  // Site chrome (nav, header, sidebars) is excluded: it lives elsewhere or nowhere at other widths.
  function landmarks() {
    const top = topObstruction();
    const band = top + (innerHeight - top) * 0.4;
    const found = [];
    for (let y = top + 4; y <= band && found.length < 8; y += 24) {
      for (const el of document.elementsFromPoint(innerWidth / 2, y)) {
        const block = el.closest('h1, h2, h3, h4, h5, h6, p, li, img, figure, pre, blockquote, td');
        if (!block || pinnedAncestor(block) || block.closest(CHROME)) continue;
        const selector = selectorFor(block);
        if (!found.includes(selector)) found.push(selector);
        break;
      }
    }
    return found;
  }

  function visibleCount(selectors) {
    const top = topObstruction();
    let count = 0;
    for (const selector of selectors) {
      let el;
      try { el = document.querySelector(selector); } catch { continue; }
      if (!el) continue;
      const rect = el.getBoundingClientRect();
      if (rect.width > 0 && rect.height > 0 && rect.top < innerHeight && rect.bottom > top) count++;
    }
    return count;
  }

  addEventListener('scroll', () => {
    if (applying || pending) return;
    pending = true;
    requestAnimationFrame(() => {
      pending = false;
      window.webkit.messageHandlers.viewportix.postMessage({ kind: 'scroll', anchor: captureAnchor() });
    });
  }, { passive: true });

  window.__viewportix = { captureAnchor, applyAnchor, applyPercent, landmarks, visibleCount, maxScroll };
})();
