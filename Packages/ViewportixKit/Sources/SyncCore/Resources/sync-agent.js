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
// by structural selector. Replayed clicks are untrusted events, so they never echo back. Clicks on form
// fields and labels are not mirrored: a label click also clicks its control, so mirroring both would
// toggle twice. Field state travels as `input` instead.
//
// Input: text, select, checkbox and radio state. Fields are found by stable selector, name, label text,
// placeholder, then structural selector. Values are set from this isolated world and announced with
// input/change events, which frameworks such as React pick up. Password and file fields are skipped.
//
// Hover: the leader reports the element under the pointer when it changes. CSS :hover only follows a
// real pointer and WebKit ignores synthetic native pointer events (S4), so followers emulate it: :hover
// rules from readable stylesheets are cloned onto a [data-viewportix-hover] attribute set on the target
// and its ancestors, and enter/over events are dispatched for script-driven menus. Cross-origin
// stylesheets served without CORS cannot be read, so their :hover rules are not emulated.
(() => {
  if (window.__viewportix) return;

  const CHANNEL = 'viewportix';
  const PROBE_GAP = 8;               // reading line sits this far below pinned headers
  const MIN_HEIGHT = 16;             // ignore hairlines and inline fragments
  const MAX_HEIGHT_VIEWPORTS = 3;    // ignore page-sized wrappers; they anchor nothing
  const MAX_CANDIDATES = 4;
  const CHROME = 'nav, header, footer, aside, [role=navigation], [role=banner], [role=complementary], [role=contentinfo]';
  const INTERACTIVE = 'a, button, [role=button], [role=link], [role=tab], [role=menuitem], [role=checkbox], summary, label, input, select, textarea';
  const FIELD = 'input, textarea, select';
  const BUTTON_INPUT = 'input[type=button], input[type=submit], input[type=reset], input[type=image]';
  const UNSYNCED_FIELD_TYPES = ['password', 'file', 'hidden'];

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

  // Labels and fields (except button-like inputs) sync their state through `input`, not clicks.
  const syncsByInput = (el) => el.matches('label, option') || (el.matches(FIELD) && !el.matches(BUTTON_INPUT));

  // ---------------------------------------------------------------- Input

  function fieldLabel(el) {
    if (el.labels && el.labels.length) return normalize(el.labels[0].innerText);
    return normalize(el.getAttribute('aria-label') || '');
  }

  function describeField(el) {
    const selector = selectorFor(el);
    return {
      selector,
      strong: isStrong(selector),
      tag: el.tagName.toLowerCase(),
      type: el.type || '',
      name: el.getAttribute('name'),
      label: fieldLabel(el),
      placeholder: el.getAttribute('placeholder') || '',
      // Radios share a name; the value tells them apart.
      option: el.type === 'radio' ? el.value : null,
    };
  }

  function findField(field) {
    const sameKind = [...document.querySelectorAll(field.tag)]
      .filter((el) => (el.type || '') === field.type && isVisible(el));
    if (field.strong) {
      const el = query(field.selector);
      if (el && isVisible(el)) return [el, 'selector'];
    }
    if (field.name) {
      const match = sameKind.find((el) => el.getAttribute('name') === field.name && (field.option == null || el.value === field.option));
      if (match) return [match, 'name'];
    }
    if (field.label) {
      const match = sameKind.find((el) => fieldLabel(el) === field.label);
      if (match) return [match, 'label'];
    }
    if (field.placeholder) {
      const match = sameKind.find((el) => el.getAttribute('placeholder') === field.placeholder);
      if (match) return [match, 'placeholder'];
    }
    if (!field.strong) {
      const el = query(field.selector);
      if (el && isVisible(el) && el.tagName.toLowerCase() === field.tag) return [el, 'structural'];
    }
    return [null, null];
  }

  function setValue(el, value) {
    const prototype = el instanceof HTMLTextAreaElement ? HTMLTextAreaElement.prototype
      : el instanceof HTMLSelectElement ? HTMLSelectElement.prototype
      : HTMLInputElement.prototype;
    Object.getOwnPropertyDescriptor(prototype, 'value').set.call(el, value);
    el.dispatchEvent(new Event('input', { bubbles: true }));
    el.dispatchEvent(new Event('change', { bubbles: true }));
  }

  function applyInput(payload) {
    const [el, how] = findField(payload.field);
    if (!el) return 'missed';
    if (el.type === 'checkbox' || el.type === 'radio') {
      // A replayed click toggles like a user would, with the events frameworks expect.
      if (el.checked !== payload.checked) el.click();
    } else if (el.value !== payload.value) {
      setValue(el, payload.value);
    }
    return 'input:' + how;
  }

  // ---------------------------------------------------------------- Hover

  const HOVER_ATTR = 'data-viewportix-hover';
  let hoverStyle = null;
  let hoverSheetCount = -1;
  let hoverChain = [];  // target first, then its ancestors

  function collectHoverRules(rules, out) {
    for (const rule of rules) {
      if (rule instanceof CSSStyleRule) {
        if (!rule.selectorText.includes(':hover')) continue;
        const selectors = rule.selectorText.split(',')
          .filter((selector) => selector.includes(':hover'))
          .map((selector) => selector.replaceAll(':hover', `[${HOVER_ATTR}]`));
        out.push(`${selectors.join(',')}{${rule.style.cssText}}`);
      } else if (rule.cssRules) {  // @media, @supports, @layer, @container
        const inner = [];
        collectHoverRules(rule.cssRules, inner);
        if (!inner.length) continue;
        const prelude = rule instanceof CSSMediaRule ? `@media ${rule.conditionText}`
          : rule instanceof CSSSupportsRule ? `@supports ${rule.conditionText}` : null;
        out.push(prelude ? `${prelude}{${inner.join('')}}` : inner.join(''));
      }
    }
  }

  // Rebuilt when the page adds or removes stylesheets.
  function ensureHoverStyle() {
    const sheets = [...document.styleSheets].filter((sheet) => sheet.ownerNode !== hoverStyle);
    if (hoverStyle && hoverStyle.isConnected && sheets.length === hoverSheetCount) return;
    hoverSheetCount = sheets.length;
    const rules = [];
    for (const sheet of sheets) {
      try { collectHoverRules(sheet.cssRules, rules); } catch { /* cross-origin without CORS */ }
    }
    hoverStyle = hoverStyle || document.createElement('style');
    hoverStyle.setAttribute('data-viewportix', 'hover');
    hoverStyle.textContent = rules.join('\n');
    if (!hoverStyle.isConnected) (document.head || document.documentElement).appendChild(hoverStyle);
  }

  function fire(node, type, bubbles) {
    const Event = type.startsWith('pointer') ? PointerEvent : MouseEvent;
    node.dispatchEvent(new Event(type, { bubbles, cancelable: true, view: window }));
  }

  // Moves the emulated pointer to `el` (or off the page for null), with the events a real move fires.
  function setHoverChain(el) {
    const next = [];
    for (let node = el; node && node.nodeType === 1; node = node.parentElement) next.push(node);
    const previous = hoverChain[0];
    if (previous && previous !== el) { fire(previous, 'pointerout', true); fire(previous, 'mouseout', true); }
    for (const node of hoverChain) {
      if (next.includes(node)) continue;
      node.removeAttribute(HOVER_ATTR);
      fire(node, 'pointerleave', false);
      fire(node, 'mouseleave', false);
    }
    for (const node of [...next].reverse()) {  // enter events run outermost first
      if (hoverChain.includes(node)) continue;
      node.setAttribute(HOVER_ATTR, '');
      fire(node, 'pointerenter', false);
      fire(node, 'mouseenter', false);
    }
    if (el && previous !== el) { fire(el, 'pointerover', true); fire(el, 'mouseover', true); }
    hoverChain = next;
  }

  function applyHover(target) {
    if (!target) { setHoverChain(null); return 'hover:clear'; }
    const [el] = findTarget(target);
    // A hover target missing at this width is normal (no hover menus on phones); not a "sync missed".
    if (!el) { setHoverChain(null); return 'hover:none'; }
    ensureHoverStyle();
    setHoverChain(el);
    return 'hover';
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
    if (syncsByInput(el)) return;
    post({ kind: 'click', target: describeTarget(el) });
  }, true);

  const onFieldEvent = (event) => {
    const el = event.target;
    if (!event.isTrusted || !(el instanceof Element) || !el.matches(FIELD) || el.matches(BUTTON_INPUT)) return;
    if (UNSYNCED_FIELD_TYPES.includes(el.type)) return;
    post({ kind: 'input', field: describeField(el), value: el.value, checked: !!el.checked });
  };
  addEventListener('input', onFieldEvent, true);
  addEventListener('change', onFieldEvent, true);  // some controls only fire change

  let hovered = null;
  let lastMove = null;
  let hoverPending = false;
  addEventListener('mousemove', (event) => {
    if (!event.isTrusted) return;
    lastMove = event;
    if (hoverPending) return;
    hoverPending = true;
    requestAnimationFrame(() => {
      hoverPending = false;
      const under = lastMove.target instanceof Element ? lastMove.target : null;
      const el = under && under !== document.body && under !== document.documentElement
        ? (under.closest(INTERACTIVE) || under) : null;
      if (el === hovered) return;
      hovered = el;
      post({ kind: 'hover', target: el ? describeTarget(el) : null });
    });
  }, { capture: true, passive: true });
  addEventListener('mouseout', (event) => {
    if (!event.isTrusted || event.relatedTarget || hovered === null) return;
    hovered = null;  // pointer left the page
    post({ kind: 'hover', target: null });
  }, true);

  window.__viewportix = { captureAnchor, applyAnchor, describeTarget, applyClick, describeField, applyInput, applyHover, maxScroll };
})();
