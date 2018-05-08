//
//  AboutViewController.swift
//  Podverse
//
//  Created by Mitchell Downey on 7/3/17.
//  Copyright © 2017 Podverse LLC. All rights reserved.
//

import UIKit
import WebKit

class AboutViewController: PVViewController {
    
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var webview: WKWebView!
    var requestUrl:URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.webview.navigationDelegate = self
        if let url = self.requestUrl {
            self.webview.load(URLRequest(url: url))
            self.webview.allowsBackForwardNavigationGestures = false
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.tabBarController?.hidePlayerView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.toggleNowPlayingBar()
    }
}

extension AboutViewController:WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.loadingIndicator.stopAnimating()
    }
}
