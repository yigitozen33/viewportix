// Viewportix sync agent.
//
// Injected into every viewport, in an isolated content world: page scripts cannot see or break it,
// and the DOM is shared. The leading viewport reports what the user does (scroll, click); the app
// forwards it to the other viewports, which apply it to their own layout.
//
// Scroll: the leader describes what sits on its reading line (just below pinned headers) as anchor
// candidates, the nearest heading's text, and a percentage. Followers try, in order: stable selectors
// (#id, data-testid), heading text, structural selectors, percentage. Heading text outranks
// structural paths because the DOM can differ between widths or user agents (S3: Wikipedia).
//
// Click: same idea; the target is found by stable selector, then by visible text, then by href, then
// by structural selector. Replayed clicks are untrusted events, so they never echo back.
(() => {
  if (window.__viewportix) return;

  const CHANNEL = 'viewportix';
  const PROBE_GAP = 8;               // reading line sits this far below pinned headers
  const MIN_HEIGHT = 16;             // ignore hairlines and inline fragments
  const MAX_HEIGHT_VIEWPORTS = 3;    // ignore page-sized wrappers; they anchor nothing
  const MAX_CANDIDATES = 4;
  const CHROME = 'nav, header, footer, aside, [role=navigation], [role=banner], [role=complementary], [role=contentinfo]';
  const INTERACTIVE = 'a, button, [role=button], [role=link], [role=tab], [role=menuitem], [role=checkbox], summary, label, input, select, textarea';

  let applying = false;
  let pending = false;

  const post = (message) => window.webkit.messageHandlers[CHANNEL].postMessage(message);
  const scroller = () => document.scrollingElement || document.documentElement;
  const maxScroll = () => Math.max(0, scroller().scrollHeight - innerHeight);
  const normalize = (text) => (text || '').replace(/\s+/g, ' ').trim().slice(0, 120);
  const absoluteTop = (el) => el.getBoundingClientRect().top + scroller().scrollTop;

  function query(selector) {
    try { return document.querySelector(selector); } catch { return null; }
  }

  function isUnique(selector) {
    try { return document.querySelectorAll(selector).length === 1; } catch { return false; }
  }

  function isVisible(el) {
    const rect = el.getBoundingClientRect();
    return rect.width > 0 && rect.height > 0 && getComputedStyle(el).visibility !== 'hidden';
  }

  function pinnedAncestor(el) {
    for (let node = el; node && node !== document.body && node !== document.documentElement; node = node.parentElement) {
      const position = getComputedStyle(node).position;
      if (position === 'fixed' || position === 'sticky') return node;
    }
    return null;
  }

  // Stable-first: unique id, test attributes, then a structural path rooted at the nearest unique id.
  function selectorFor(el) {
    if (el.id && isUnique('#' + CSS.escape(el.id))) return '#' + CSS.escape(el.id);
    for (const attr of ['data-testid', 'data-test', 'data-qa', 'data-cy']) {
      const value = el.getAttribute(attr);
      if (value) {
        const selector = `[${attr}="${CSS.escape(value)}"]`;
        if (isUnique(selector)) return selector;
      }
    }
    const parts = [];
    for (let node = el; node && node.nodeType === 1 && node !== document.documentElement; node = node.parentElement) {
      if (node !== el && node.id && isUnique('#' + CSS.escape(node.id))) {
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

  const isStrong = (selector) => !selector.includes(':nth-of-type');

  // ---------------------------------------------------------------- Scroll

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

  function isAnchorable(el) {
    if (!el || el === document.body || el === document.documentElement || pinnedAncestor(el)) return false;
    const rect = el.getBoundingClientRect();
    return rect.height >= MIN_HEIGHT && rect.height <= innerHeight * MAX_HEIGHT_VIEWPORTS && rect.width > 0;
  }

  function headings() {
    return [...document.querySelectorAll('h1, h2, h3, h4, h5, h6')].filter((h) =>
      !pinnedAncestor(h) && !h.closest(CHROME) && isVisible(h) && normalize(h.textContent).length > 0);
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

  function captureAnchor() {
    const max = maxScroll();
    const y = scroller().scrollTop;
    const percent = max > 0 ? y / max : 0;
    if (y <= 2) return { edge: 'top', percent };
    if (y >= max - 2) return { edge: 'bottom', percent };

    const line = topObstruction() + PROBE_GAP;
    const picked = [];
    for (const x of [innerWidth * 0.5, innerWidth * 0.3, innerWidth * 0.7]) {
      const el = document.elementsFromPoint(x, line).find(isAnchorable);
      if (!el || picked.includes(el)) continue;
      picked.push(el);
      // Ancestors make a fallback chain when the deepest element moves or disappears at other widths.
      for (let parent = el.parentElement; parent && picked.length < MAX_CANDIDATES; parent = parent.parentElement) {
        if (isAnchorable(parent) && !picked.includes(parent)) picked.push(parent);
      }
      if (picked.length >= MAX_CANDIDATES) break;
    }
    const candidates = picked.slice(0, MAX_CANDIDATES).map((el) => {
      const rect = el.getBoundingClientRect();
      const selector = selectorFor(el);
      return { selector, strong: isStrong(selector), ratio: (line - rect.top) / rect.height };
    });
    return { candidates, section: captureSection(line), percent };
  }

  function scrollToY(y) {
    applying = true;
    scroller().scrollTo({ top: y, behavior: 'instant' });
    // Our own scroll events fire asynchronously; stay quiet until they have passed.
    requestAnimationFrame(() => requestAnimationFrame(() => { applying = false; }));
  }

  function applyCandidates(candidates, line) {
    for (const candidate of candidates) {
      const el = query(candidate.selector);
      if (!el || pinnedAncestor(el)) continue;
      const rect = el.getBoundingClientRect();
      if (rect.width === 0 && rect.height === 0) continue; // display: none at this width
      scrollToY(scroller().scrollTop + rect.top + candidate.ratio * rect.height - line);
      return true;
    }
    return false;
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

  function applyAnchor(anchor) {
    if (anchor.edge === 'top') { scrollToY(0); return 'edge:top'; }
    if (anchor.edge === 'bottom') { scrollToY(maxScroll()); return 'edge:bottom'; }
    const line = topObstruction() + PROBE_GAP;
    const candidates = anchor.candidates || [];
    if (applyCandidates(candidates.filter((c) => c.strong), line)) return 'anchor:strong';
    if (anchor.section && applySection(anchor.section, line)) return 'section';
    if (applyCandidates(candidates.filter((c) => !c.strong), line)) return 'anchor:structural';
    scrollToY(anchor.percent * maxScroll());
    return 'percent';
  }

  // ---------------------------------------------------------------- Click

  const labelOf = (el) => normalize(el.innerText || el.value || el.getAttribute('aria-label') || el.getAttribute('title') || '').slice(0, 80);

  function describeTarget(el) {
    const selector = selectorFor(el);
    return {
      selector,
      strong: isStrong(selector),
      tag: el.tagName.toLowerCase(),
      text: labelOf(el),
      href: el.getAttribute('href'),
    };
  }

  function findTarget(target) {
    if (target.strong) {
      const el = query(target.selector);
      if (el && isVisible(el)) return [el, 'selector'];
    }
    if (target.text) {
      const match = [...document.querySelectorAll(target.tag)].find((el) => isVisible(el) && labelOf(el) === target.text);
      if (match) return [match, 'text'];
    }
    if (target.href) {
      const match = [...document.querySelectorAll('a[href]')].find((el) => isVisible(el) && el.getAttribute('href') === target.href);
      if (match) return [match, 'href'];
    }
    if (!target.strong) {
      const el = query(target.selector);
      if (el && isVisible(el) && el.tagName.toLowerCase() === target.tag) return [el, 'structural'];
    }
    return [null, null];
  }

  function applyClick(target) {
    const [el, how] = findTarget(target);
    if (!el) return 'missed';
    el.click();
    return 'click:' + how;
  }

  // ---------------------------------------------------------------- Listeners

  addEventListener('scroll', () => {
    if (applying || pending) return;
    pending = true;
    requestAnimationFrame(() => {
      pending = false;
      post({ kind: 'scroll', anchor: captureAnchor() });
    });
  }, { passive: true });

  addEventListener('click', (event) => {
    if (!event.isTrusted || !(event.target instanceof Element)) return;
    const el = event.target.closest(INTERACTIVE) || event.target;
    post({ kind: 'click', target: describeTarget(el) });
  }, true);

  window.__viewportix = { captureAnchor, applyAnchor, describeTarget, applyClick, maxScroll };
})();
