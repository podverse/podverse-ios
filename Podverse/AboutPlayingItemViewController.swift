//
//  AboutPlayingItemViewController.swift
//  Podverse
//
//  Created by Creon Creonopoulos on 7/14/17.
//  Copyright © 2017 Podverse LLC. All rights reserved.
//

import UIKit

class AboutPlayingItemViewController: UIViewController, UIWebViewDelegate {

    @IBOutlet weak var webView: UIWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let summary = PVMediaPlayer.shared.nowPlayingItem?.episodeSummary {
            self.webView.loadHTMLString(summary.formatHtmlString(), baseURL: nil)
        }
        self.view.backgroundColor = UIColor.black
        self.webView.layer.borderColor = UIColor.lightGray.cgColor
        self.webView.layer.borderWidth = 1.0
        self.webView.delegate = self
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.webView.scrollView.contentInset = UIEdgeInsets.zero;
    }
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if navigationType == UIWebViewNavigationType.linkClicked {
            if let url = request.url {
                UIApplication.shared.openURL(url)
            }
            return false
        }
        return true
    }
}
