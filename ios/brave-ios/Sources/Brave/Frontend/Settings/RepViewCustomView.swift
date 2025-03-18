import UIKit
import WebKit

class RepViewCustomView: UIView, WKNavigationDelegate, WKUIDelegate {
    var webView: WKWebView!
    private var activityIndicator: UIActivityIndicatorView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupWebView()
        setupActivityIndicator()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupWebView()
        setupActivityIndicator()
    }
    
    private func setupWebView() {
        let configuration = WKWebViewConfiguration()

        // 🔥 Dùng chung ProcessPool để giữ Session & LocalStorage khi reload
        configuration.processPool = WKProcessPool()
        
        // 🔥 Bật Cookies và LocalStorage
        configuration.websiteDataStore = WKWebsiteDataStore.default()

        // 🔥 Bật Web Inspector để debug (chỉ khi DEBUG)
        #if DEBUG
        configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")
        #endif
        
        // Inject JavaScript vào tất cả các trang
           let jsScript = """
           (function() {
               document.documentElement.setAttribute('data-rep-social', 'true');
               window.addEventListener('DOMContentLoaded', function() {
                   document.documentElement.setAttribute('data-rep-social', 'true');
               });
           })();
           """
           let userScript = WKUserScript(source: jsScript, injectionTime: .atDocumentStart, forMainFrameOnly: false)
           configuration.userContentController.addUserScript(userScript)
        configuration.applicationNameForUserAgent = "Version/8.0.2 Safari/600.2.5"

        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/97.0.4692.99 Mobile Safari/537.36"
        webView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(webView)

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: self.topAnchor),
            webView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
    }
    
    private func setupActivityIndicator() {
        activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.color = .gray
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    func loadURL(_ url: URL) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
}

// MARK: - WKNavigationDelegate
extension RepViewCustomView {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
//        activityIndicator.startAnimating()
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
//        activityIndicator.stopAnimating()

        // 🛠 Kiểm tra nếu script đã inject
        let checkScript = "document.documentElement.getAttribute('data-rep-social');"
        webView.evaluateJavaScript(checkScript) { result, error in
            if let value = result as? String {
                print("✅ Injected JavaScript Value: \(value)") // Debug
            } else {
                print("❌ JavaScript Injection Failed")
            }
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
//        activityIndicator.stopAnimating()
    }
}
