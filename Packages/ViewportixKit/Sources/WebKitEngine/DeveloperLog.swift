import EngineCore
import Foundation

/// Senkron's developer scope in WebKit: a page-world script that reports console errors and
/// warnings, uncaught errors, failed resources and failed fetch / XMLHttpRequest calls. It runs in
/// the page's own world because that is where the page's console and network calls are; it is only
/// installed while the scope is on (`setDeveloperLogging`), since wrapping them is visible to the page.
enum DeveloperLog {
    static let messageName = "viewportixDeveloper"

    static let source = """
    (() => {
      if (window.__viewportixDeveloper) return;
      window.__viewportixDeveloper = true;
      const handler = window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.\(messageName);
      if (!handler) return;
      const send = (m) => { try { handler.postMessage(m); } catch (e) {} };
      const text = (args) => Array.from(args).map((a) => {
        try { return typeof a === 'string' ? a : (a instanceof Error ? (a.name + ': ' + a.message) : JSON.stringify(a)); }
        catch (e) { return String(a); }
      }).join(' ').slice(0, 300);
      for (const level of ['error', 'warn']) {
        const original = console[level];
        console[level] = function (...args) {
          send({ kind: 'console', level: level === 'warn' ? 'warning' : 'error', text: text(args) });
          return original.apply(this, args);
        };
      }
      addEventListener('error', (e) => {
        const el = e.target;
        if (el && el !== window && (el.src || el.href)) {
          send({ kind: 'network', level: 'error', text: 'yüklenemedi', url: String(el.src || el.href) });
        } else {
          send({ kind: 'console', level: 'error', text: String(e.message || 'Hata') });
        }
      }, true);
      addEventListener('unhandledrejection', (e) => send({ kind: 'console', level: 'error', text: 'Yakalanmamış: ' + text([e.reason]) }));
      const originalFetch = window.fetch;
      if (originalFetch) {
        window.fetch = function (...args) {
          const request = originalFetch.apply(this, args);
          const url = String((args[0] && args[0].url) || args[0]);
          request.then((r) => {
            if (!r.ok) send({ kind: 'network', level: r.status >= 500 ? 'error' : 'warning', text: String(r.status), url: r.url || url });
          }, () => send({ kind: 'network', level: 'error', text: 'ağ hatası', url }));
          return request;
        };
      }
      const open = XMLHttpRequest.prototype.open;
      const sendRequest = XMLHttpRequest.prototype.send;
      XMLHttpRequest.prototype.open = function (method, url, ...rest) {
        this.__viewportixURL = String(url);
        return open.call(this, method, url, ...rest);
      };
      XMLHttpRequest.prototype.send = function (...args) {
        this.addEventListener('loadend', () => {
          if (this.status === 0 || this.status >= 400) {
            send({ kind: 'network', level: this.status === 0 || this.status >= 500 ? 'error' : 'warning',
                   text: this.status ? String(this.status) : 'ağ hatası', url: this.__viewportixURL });
          }
        });
        return sendRequest.apply(this, args);
      };
    })();
    """

    static func message(from body: Any) -> DeveloperMessage? {
        guard let message = JSONValue(any: body),
              let kind = message["kind"]?.stringValue.flatMap(DeveloperMessage.Kind.init(rawValue:)),
              let level = message["level"]?.stringValue.flatMap(DeveloperMessage.Level.init(rawValue:)),
              let text = message["text"]?.stringValue else { return nil }
        return DeveloperMessage(kind: kind, level: level, text: text, url: message["url"]?.stringValue)
    }
}
