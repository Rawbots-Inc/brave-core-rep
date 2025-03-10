import UIKit
import WebKit

class RepViewController: UIViewController {
    var customWebView: RepViewCustomView!
    var url: URL?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupNavigationBar()

        if let url = url {
            customWebView.loadURL(url)
        }
    }

    private func setupView() {
        view.backgroundColor = .white

        // Tạo custom webview
        customWebView = RepViewCustomView()
        customWebView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(customWebView)

        NSLayoutConstraint.activate([
            customWebView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            customWebView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            customWebView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            customWebView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupNavigationBar() {
        navigationItem.title = ""

        let closeButton = UIBarButtonItem(title: "←", style: .plain, target: self, action: #selector(closeView))
        navigationItem.leftBarButtonItem = closeButton

//        let backButton = UIBarButtonItem(title: "←", style: .plain, target: self, action: #selector(goBack))
//        let forwardButton = UIBarButtonItem(title: "→", style: .plain, target: self, action: #selector(goForward))

//        navigationItem.rightBarButtonItems = [forwardButton, backButton]
    }

    @objc private func closeView() {
        print("Close View button tapped")
        dismiss(animated: true)
        if let navigationController = navigationController {
            print("Closing via popViewController")
            navigationController.popViewController(animated: true)
            
        } else {
            print("Closing via dismiss")
            dismiss(animated: true)
        }
    }

    @objc private func goBack() {
        if customWebView.webView.canGoBack {
            customWebView.webView.goBack()
        }
    }

    @objc private func goForward() {
        if customWebView.webView.canGoForward {
            customWebView.webView.goForward()
        }
    }
}
