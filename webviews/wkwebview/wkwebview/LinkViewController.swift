//
//  LinkViewController.swift
//  wkwebview
//
//  Copyright (c) 2016 Plaid Inc. All rights reserved.
//

import UIKit
import WebKit

class LinkViewController: UIViewController, WKNavigationDelegate {

    let webView = WKWebView()

    override func viewDidLoad() {
        super.viewDidLoad()

        // load the link url
        let linkUrl = generateLinkInitializationURL()
        let url = URL(string: linkUrl)
        let request = URLRequest(url: url!)

        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = false

        webView.frame = view.frame
        webView.scrollView.bounces = false
        self.view.addSubview(webView)
        webView.load(request)
    }

    override var prefersStatusBarHidden : Bool {
        return true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // getUrlParams :: parse query parameters into a Dictionary
    func getUrlParams(url: URL) -> Dictionary<String, String> {
        var paramsDictionary = [String: String]()
        let queryItems = URLComponents(string: (url.absoluteString))?.queryItems
        queryItems?.forEach { paramsDictionary[$0.name] = $0.value }
        return paramsDictionary
    }

    // generateLinkInitializationURL :: create the link.html url with query parameters
    func generateLinkInitializationURL() -> String {
        // Create a new link_token via the /link/token/create endpoint. You will be
        // able to configure this link_token to control Link behavior. To learn more
        // about how to create a link_token, visit https://plaid.com/docs/#create-link-token.
        //
        // After creating a link_token, replace <#GENERATED_LINK_TOKEN#> with it below.
        let config = [
            "token": "<#GENERATED_LINK_TOKEN#>"
            "isMobile": "true",
            "isWebview": "true",
        ]

        // Build a dictionary with the Link configuration options
        // See the Link docs (https://plaid.com/docs/quickstart) for full documentation.
        var components = URLComponents()
        components.scheme = "https"
        components.host = "cdn.plaid.com"
        components.path = "/link/v2/stable/link.html"
        components.queryItems = config.map { URLQueryItem(name: $0, value: $1) }
        return components.string!
    }

    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping ((WKNavigationActionPolicy) -> Void)) {

        let linkScheme = "plaidlink";
        let actionScheme = navigationAction.request.url?.scheme;
        let actionType = navigationAction.request.url?.host;
        let queryParams = getUrlParams(url: navigationAction.request.url!)

        if (actionScheme == linkScheme) {
            switch actionType {

            case "connected"?:
                // Close the webview
                _ = self.navigationController?.popViewController(animated: true)

                // Parse data passed from Link into a dictionary
                // This includes the public_token as well as account and institution metadata
                print("Public Token: \(queryParams["public_token"])");
                print("Account ID: \(queryParams["account_id"])");
                print("Institution type: \(queryParams["institution_type"])");
                print("Institution name: \(queryParams["institution_name"])");
                break

            case "exit"?:
                // Close the webview
                _ = self.navigationController?.popViewController(animated: true)

                // Parse data passed from Link into a dictionary
                // This includes information about where the user was in the Link flow
                // any errors that occurred, and request IDs
                print("URL: \(navigationAction.request.url?.absoluteString)")
                // Output data from Link
                print("User status in flow: \(queryParams["status"])");
                // The requet ID keys may or may not exist depending on when the user exited
                // the Link flow.
                print("Link request ID: \(queryParams["link_request_id"])");
                print("Plaid API request ID: \(queryParams["link_request_id"])");
                break

            case "event"?:
                 // The event action is fired as the user moves through the Link flow
                print("Event name: \(queryParams["event_name"])");
                break
            default:
                print("Link action detected: \(actionType)")
                break
            }

            decisionHandler(.cancel)
        } else if (navigationAction.navigationType == WKNavigationType.linkActivated &&
            (actionScheme == "http" || actionScheme == "https")) {
            // Handle http:// and https:// links inside of Plaid Link,
            // and open them in a new Safari page. This is necessary for links
            // such as "forgot-password" and "locked-account"
            UIApplication.shared.open(navigationAction.request.url!, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
            decisionHandler(.cancel)
        } else {
            print("Unrecognized URL scheme detected that is neither HTTP, HTTPS, or related to Plaid Link: \(navigationAction.request.url?.absoluteString)");
            decisionHandler(.allow)
        }
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}
