//
//  ViewController.swift
//  Roam Research
//
//  Created by Miguel Piedrafita on 7/8/21.
//

import UIKit
import WebKit

class ViewController: UIViewController {
	
	let userDefaults: UserDefaults = .standard

	override func viewDidLoad() {
		super.viewDidLoad()
		
		let subgraphSlug = userDefaults.value(forKey: "subgraphSlug") as? String?
		
		if (subgraphSlug ?? nil) != nil {
			loadWebView(subgraphSlug: subgraphSlug!!)
		}
	}
	
	override func viewDidAppear(_ animated: Bool) {
		let subgraphSlug = userDefaults.value(forKey: "subgraphSlug") as? String?
		
		if (subgraphSlug ?? nil) != nil {
			return
		}

		let alertController = UIAlertController(title: "Roam Graph", message: "Enter the slug of your Roam graph", preferredStyle: .alert)

		alertController.addTextField { (textField) in textField.placeholder = "m1guelpf" }

		alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { [self] (action) in
			if let text = alertController.textFields?.first?.text {
				userDefaults.set(text as String?, forKey: "subgraphSlug")
				loadWebView(subgraphSlug: text)
			} else {
				self.closeApp()
			}
		}))

		present(alertController, animated: true, completion: nil)
	}
	
	func loadWebView(subgraphSlug: String) {
		let config = WKWebViewConfiguration()
		let script = WKUserScript(source: "document.body.classList.add('roam-app')", injectionTime: .atDocumentEnd, forMainFrameOnly: true)
		config.userContentController.addUserScript(script)

		let webView = WKWebView(frame: view.frame, configuration: config)
		webView.navigationDelegate = self
		webView.uiDelegate = self
		webView.allowsBackForwardNavigationGestures = true
		webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		view.addSubview(webView)
		
		let url = URL(string: "https://roamresearch.com/#/app/\(subgraphSlug)")!
		let request = URLRequest(url: url)
		webView.load(request)
	}
	
	func closeApp() {
		UIControl().sendAction(#selector(URLSessionTask.suspend), to: UIApplication.shared, for: nil)
		DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: {
			exit(EXIT_SUCCESS)
		})
	}
}

// Handler for external links & loading errors
extension ViewController: WKNavigationDelegate {
	// Open external links on either their specific apps or Safari
	func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
		if navigationAction.navigationType == .linkActivated  {
			if let url = navigationAction.request.url,
				UIApplication.shared.canOpenURL(url) {
					UIApplication.shared.open(url)
					decisionHandler(.cancel)
			} else {
				// Open in web view
				decisionHandler(.allow)
			}
		} else {
			// other navigation type, such as reload, back or forward buttons
			decisionHandler(.allow)
		}
	}
	
	// Close app if loading Roam fails
	func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
		let alertController = UIAlertController(title: nil, message: error.localizedDescription, preferredStyle: .alert)
		alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in self.closeApp() }))

		present(alertController, animated: true, completion: nil)
	}
}

// Render alert(), confirm() & dialog()
extension ViewController: WKUIDelegate {
	func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void)
	{
		let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
		alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in completionHandler() }))

		present(alertController, animated: true, completion: nil)
	}
	
	func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {

		let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)

		alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in completionHandler(true) }))

		alertController.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action) in completionHandler(false) }))

		present(alertController, animated: true, completion: nil)
	}
	
	func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {

		let alertController = UIAlertController(title: nil, message: prompt, preferredStyle: .alert)

		alertController.addTextField { (textField) in textField.text = defaultText }

		alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
			if let text = alertController.textFields?.first?.text {
				completionHandler(text)
			} else {
				completionHandler(defaultText)
			}
		}))

		alertController.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action) in completionHandler(nil) }))

		present(alertController, animated: true, completion: nil)
	}
}
