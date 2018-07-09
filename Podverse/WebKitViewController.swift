//
//  WebKitViewController.swift
//  Podverse
//
//  Created by Mitchell Downey on 4/28/18.
//  Copyright © 2018 Podverse LLC. All rights reserved.
//

import UIKit
import WebKit

class WebKitViewController: UIViewController, WKUIDelegate, WKNavigationDelegate {

    var urlString: String?

    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.webView.uiDelegate = self
        
        self.webView.navigationDelegate = self
        
        self.activityIndicatorView.hidesWhenStopped = true
        
        if let urlString = urlString, let url = URL(string: urlString) {
            showNetworkActivityIndicator()
            self.activityIndicatorView.startAnimating()
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }

//    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
//        showNetworkActivityIndicator()
//        self.activityIndicatorView.startAnimating()
//    }
    
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        hideNetworkActivityIndicator()
        self.activityIndicatorView.stopAnimating()
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        hideNetworkActivityIndicator()
        self.activityIndicatorView.stopAnimating()
    }

}
