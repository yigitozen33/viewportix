import EngineCore
import Foundation

/// One page's measurable elements, as seen by one viewport (DESIGN.md §3.4 Farklar). Only elements
/// with a selector that means the same thing at every width are taken: `#id`, `[data-testid]`, or
/// a class that is unique on the page. Structural paths (`main > div:nth-child(3)`) differ between
/// layouts and would pair the wrong elements.
public struct ElementSnapshot: Hashable, Sendable {
    public struct Element: Hashable, Sendable {
        public var selector: String
        /// Page coordinates in CSS px (scroll-independent).
        public var top: Double
        public var left: Double
        public var width: Double
        public var height: Double
        public var isVisible: Bool
        /// Computed values as the page reports them: "16px", "600", "rgb(51, 51, 51)", "normal".
        public var fontSize: String
        public var fontWeight: String
        public var lineHeight: String
        public var color: String

        public init(selector: String, top: Double = 0, left: Double = 0, width: Double = 0, height: Double = 0, isVisible: Bool = true,
                    fontSize: String = "16px", fontWeight: String = "400", lineHeight: String = "normal", color: String = "rgb(0, 0, 0)") {
            self.selector = selector
            self.top = top
            self.left = left
            self.width = width
            self.height = height
            self.isVisible = isVisible
            self.fontSize = fontSize
            self.fontWeight = fontWeight
            self.lineHeight = lineHeight
            self.color = color
        }
    }

    public var viewportWidth: Int
    public var elements: [Element]

    public init(viewportWidth: Int, elements: [Element]) {
        self.viewportWidth = viewportWidth
        self.elements = elements
    }

    /// Reads what `collectScript` returns.
    public init?(json: JSONValue) {
        guard let width = json["width"]?.numberValue, case .array(let items)? = json["elements"] else { return nil }
        viewportWidth = Int(width)
        elements = items.compactMap { item in
            guard let selector = item["selector"]?.stringValue else { return nil }
            return Element(
                selector: selector,
                top: item["top"]?.numberValue ?? 0, left: item["left"]?.numberValue ?? 0,
                width: item["width"]?.numberValue ?? 0, height: item["height"]?.numberValue ?? 0,
                isVisible: item["visible"]?.boolValue ?? false,
                fontSize: item["fontSize"]?.stringValue ?? "", fontWeight: item["fontWeight"]?.stringValue ?? "",
                lineHeight: item["lineHeight"]?.stringValue ?? "", color: item["color"]?.stringValue ?? ""
            )
        }
    }

    /// Runs in the page (any engine, through `EngineSession.evaluate`) and returns
    /// `{ width, elements: [...] }`. At most 400 elements, headings and controls first.
    public static let collectScript = """
    (() => {
      const LIMIT = 400;
      const PRIORITY = 'h1,h2,h3,h4,h5,h6,button,a,input,select,textarea,img,label,[role=button]';
      const esc = (s) => (window.CSS && CSS.escape) ? CSS.escape(s) : s;
      const seen = new Set();
      const picked = [];
      const classCounts = new Map();
      for (const el of document.querySelectorAll('[class]')) {
        for (const c of el.classList) classCounts.set(c, (classCounts.get(c) || 0) + 1);
      }
      function selectorFor(el) {
        if (el.id && document.querySelectorAll('#' + esc(el.id)).length === 1) return '#' + esc(el.id);
        const testid = el.getAttribute('data-testid');
        if (testid) return '[data-testid="' + testid.replace(/"/g, '\\\\"') + '"]';
        for (const c of el.classList) {
          if (classCounts.get(c) === 1 && !/^(is-|has-|js-)|active|open|hover|focus|selected/.test(c)) return '.' + esc(c);
        }
        return null;
      }
      function consider(el) {
        if (picked.length >= LIMIT || seen.has(el)) return;
        seen.add(el);
        const selector = selectorFor(el);
        if (!selector) return;
        const rect = el.getBoundingClientRect();
        const style = getComputedStyle(el);
        const visible = el.getClientRects().length > 0 && style.visibility !== 'hidden' && rect.width > 0 && rect.height > 0;
        picked.push({
          selector,
          top: Math.round(rect.top + scrollY), left: Math.round(rect.left + scrollX),
          width: Math.round(rect.width), height: Math.round(rect.height), visible,
          fontSize: style.fontSize, fontWeight: style.fontWeight, lineHeight: style.lineHeight, color: style.color,
        });
      }
      document.querySelectorAll(PRIORITY).forEach(consider);
      document.querySelectorAll('body [id], body [data-testid], body [class]').forEach(consider);
      return { width: innerWidth, elements: picked };
    })()
    """
}
