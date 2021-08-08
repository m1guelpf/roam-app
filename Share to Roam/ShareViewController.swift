//
//  ShareViewController.swift
//  Share to Roam
//
//  Created by Miguel Piedrafita on 7/8/21.
//

import UIKit
import WebKit

class CustomShareViewController: UIViewController {
	let userDefaults: UserDefaults = UserDefaults.init(suiteName: "group.me.m1guelpf.RoamResearch")!

	private var urlString: String? {
		didSet {
			reloadWebview()
		}
	}

	private var textString: String? {
		didSet {
			reloadWebview()
		}
	}

	private var webViewUrl: String {
		let encodedText = textString?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
		let encodedUrl = urlString?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

		return "https://roamresearch.com/?\(encodedText == "" ? "a" : "text=\(encodedText)")&\(encodedUrl == "" ? "b" : "url=\(encodedUrl)")#quick-capture"
	}

	private var webView: WKWebView?

	override func viewDidLoad() {
		super.viewDidLoad()
		
		ensureConfigured()
		loadShareContent()

		self.view.backgroundColor = .systemGray6
		setupNavBar()
		setupViews()
	}
	
	private func ensureConfigured() {
		let subgraphSlug = userDefaults.value(forKey: "subgraphSlug")

		if (subgraphSlug ?? nil) == nil {
			let alertController = UIAlertController(title: nil, message: "Please select a graph from the Roam app first.", preferredStyle: .alert)
			alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { [self] (action) in self.cancelAction() }))

			present(alertController, animated: true, completion: nil)
		}

	}
	
	private func loadShareContent() {
		let extensionItem = extensionContext?.inputItems[0] as! NSExtensionItem
	
		for attachment in extensionItem.attachments! {
		  if attachment.hasItemConformingToTypeIdentifier("public.url") {
			attachment.loadItem(forTypeIdentifier: "public.url", options: nil, completionHandler: { (results, error) in
			  let url = results as! URL?
			  self.urlString = url!.absoluteString
			})
		  }
		  if attachment.hasItemConformingToTypeIdentifier("public.plain-text") {
			attachment.loadItem(forTypeIdentifier: "public.plain-text", options: nil, completionHandler: { (results, error) in
			  let text = results as! String
			  self.textString = text
			})
		  }
		}
		
		
	}

	// 2: Set the title and the navigation items
	private func setupNavBar() {
		self.navigationItem.title = "Roam Research"

		let itemCancel = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelAction))
		self.navigationItem.setLeftBarButton(itemCancel, animated: false)

		let itemDone = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneAction))
		self.navigationItem.setRightBarButton(itemDone, animated: false)
	}
	
	private func setupViews() {
		self.webView = WKWebView(frame: view.frame)
		self.webView!.navigationDelegate = self
		self.webView!.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		self.view.addSubview(self.webView!)

		let request = URLRequest(url: URL(string: self.webViewUrl)!)
		self.webView!.load(request)
	}
	
	private func reloadWebview() {
		self.webView?.load(URLRequest(url: URL(string: self.webViewUrl)!))
	}

	// 3: Define the actions for the navigation items
	@objc private func cancelAction () {
		let error = NSError(domain: "me.m1guelpf.RoamResearch", code: 0, userInfo: [NSLocalizedDescriptionKey: "User cancelled request"])
		extensionContext?.cancelRequest(withError: error)
	}

	@objc private func doneAction() {
		extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
	}
}

extension CustomShareViewController: WKNavigationDelegate {
	// Close prompt if loading Roam fails
	func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
		let alertController = UIAlertController(title: nil, message: error.localizedDescription, preferredStyle: .alert)
		alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { [self] (action) in self.cancelAction() }))

		present(alertController, animated: true, completion: nil)
	}
}

@objc(CustomShareNavigationController)
class CustomShareNavigationController: UINavigationController {

	override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
		super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

		// 2: set the ViewControllers
		self.setViewControllers([CustomShareViewController()], animated: false)
	}

	@available(*, unavailable)
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
}
