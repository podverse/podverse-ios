//
//  AboutPlayingItemViewController.swift
//  Podverse
//
//  Created by Creon Creonopoulos on 7/14/17.
//  Copyright © 2017 Podverse LLC. All rights reserved.
//

import UIKit

class AboutPlayingItemViewController: UIViewController, UIWebViewDelegate {

    let pvMediaPlayer = PVMediaPlayer.shared
    let playerHistoryManager = PlayerHistory.manager
    
    @IBOutlet weak var webView: UIWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addObservers()
        
        loadWebView()
        
        self.view.backgroundColor = UIColor.black
        self.webView.delegate = self
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.webView.scrollView.contentInset = UIEdgeInsets.zero;
    }
    
    deinit {
        removeObservers()
    }
    
    fileprivate func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(loadWebView), name: .hideClipData, object: nil)
    }
    
    fileprivate func removeObservers() {
        NotificationCenter.default.removeObserver(self, name: .hideClipData, object: nil)
    }
    
    @objc fileprivate func loadWebView() {
        
        if let item = pvMediaPlayer.nowPlayingItem {
            var text = ""
            
            if item.isClip() {
                if let title = item.clipTitle {
                    text += "<strong>" + title + "</strong>" + "<br><br>"
                }
                
                if let time = item.readableStartAndEndTime() {
                    text += "<span class=\"lightGray\">" + time + "</span>"
                }
                
                if let userId = UserDefaults.standard.string(forKey: "userId"), userId == item.ownerId {
                    text += "<a class=\"pull-right\" href=\"podverse://podverse.fm?editClip\">Edit Clip</a>"
                }
                
                text += "<br><br><hr><br>"
            }
            
            if let summary = item.episodeSummary, summary.trimmingCharacters(in: .whitespacesAndNewlines).count >= 1, let enrichedSummary = summary.convertPlaybackTimesToUrlSchemeElements() {
                text += enrichedSummary
            } else {
                text += kNoShowNotesMessage
            }
            
            self.webView.loadHTMLString(text.formatHtmlString(isWhiteBg: false), baseURL: nil)
            
        }
        
    }
    
    func showEditClip() {
        if !self.pvMediaPlayer.isDataAvailable {
            return
        }
        
        if !checkForConnectivity() {
            self.showInternetNeededAlertWithDescription(message: "You must be connected to the internet to edit clips.")
            return
        }
        
        if let item = self.playerHistoryManager.historyItems.first {
            self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"Player", style:.plain, target:nil, action:nil)
            self.performSegue(withIdentifier: "Show Make Clip Time", sender: item)
        }
    }
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if navigationType == UIWebViewNavigationType.linkClicked {
            if let url = request.url, url.scheme == "podverse", let query = url.query {
                if query == "editClip" {
                    DispatchQueue.main.async {
                        self.showEditClip()
                    }
                } else {
                    let playbackTime = query.mediaPlayerTimeToSeconds()
                    pvMediaPlayer.seek(toTime: Double(playbackTime))
                }
            } else if let url = request.url {
                UIApplication.shared.open(url)
            }
            return false
        }
        return true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Show Make Clip Time" {
            if let sender = sender as? PlayerHistoryItem, let makeClipTimeViewController = segue.destination as? MakeClipTimeViewController {
                makeClipTimeViewController.editingItem = sender
            }
        }
    }
    
}
