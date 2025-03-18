//import UIKit
//import WebKit
//
//class RepViewController: UIViewController {
//    var customWebView: RepViewCustomView!
//    var url: URL?
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        setupView()
//        setupNavigationBar()
//
//        if let url = url {
//            customWebView.loadURL(url)
//        }
//    }
//
//    private func setupView() {
//        view.backgroundColor = .white
//
//        // Tạo custom webview
//        customWebView = RepViewCustomView()
//        customWebView.translatesAutoresizingMaskIntoConstraints = false
//        view.addSubview(customWebView)
//
//        NSLayoutConstraint.activate([
//            customWebView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
//            customWebView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            customWebView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            customWebView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
//        ])
//    }
//
//    private func setupNavigationBar() {
//        navigationItem.title = ""
//
//        let closeButton = UIBarButtonItem(title: "←", style: .plain, target: self, action: #selector(closeView))
//        navigationItem.leftBarButtonItem = closeButton
//
////        let backButton = UIBarButtonItem(title: "←", style: .plain, target: self, action: #selector(goBack))
////        let forwardButton = UIBarButtonItem(title: "→", style: .plain, target: self, action: #selector(goForward))
//
////        navigationItem.rightBarButtonItems = [forwardButton, backButton]
//    }
//
//    @objc private func closeView() {
//        print("Close View button tapped")
//        dismiss(animated: true)
//        if let navigationController = navigationController {
//            print("Closing via popViewController")
//            navigationController.popViewController(animated: true)
//            
//        } else {
//            print("Closing via dismiss")
//            dismiss(animated: true)
//        }
//    }
//
//    @objc private func goBack() {
//        if customWebView.webView.canGoBack {
//            customWebView.webView.goBack()
//        }
//    }
//
//    @objc private func goForward() {
//        if customWebView.webView.canGoForward {
//            customWebView.webView.goForward()
//        }
//    }
//}
//
//

import UIKit
import SafariServices

class RepViewController: UIViewController {
    var url: URL?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
//        setupNavigationBar()

        // Thay thế customWebView.loadURL(url) bằng present SafariViewController
        if let url = url {
            let config = SFSafariViewController.Configuration()
            config.entersReaderIfAvailable = false
            config.barCollapsingEnabled = true
            let safariVC = SFSafariViewController(url: url, configuration: config)
            safariVC.dismissButtonStyle = .close ;
            // Tuỳ biến giao diện nếu muốn
            // safariVC.preferredBarTintColor = .white
            // safariVC.preferredControlTintColor = .black

            // Hiển thị SafariViewController
            present(safariVC, animated: true, completion: nil)
        }
    }

    private func setupNavigationBar() {
        navigationItem.title = ""
        let closeButton = UIBarButtonItem(title: "←", style: .plain, target: self, action: #selector(closeView))
        navigationItem.leftBarButtonItem = closeButton
    }

    @objc private func closeView() {
        print("Close View button tapped")
        if let navigationController = navigationController {
            navigationController.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }
}
