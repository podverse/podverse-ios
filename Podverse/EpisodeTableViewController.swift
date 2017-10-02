//
//  EpisodeTableViewController.swift
//  Podverse
//
//  Created by Mitchell Downey on 10/1/17.
//  Copyright © 2017 Podverse LLC. All rights reserved.
//

import UIKit

class EpisodeTableViewController: PVViewController {

    var feedUrl: String?
    var mediaRefs = [MediaRef]()
    var mediaUrl: String?
    let moc = CoreDataHelper.createMOCForThread(threadType: .privateThread)
    let reachability = PVReachability.shared
    
    @IBOutlet weak var webView: UIWebView!
    
    var filterTypeSelected: EpisodeFilterType = .showNotes {
        didSet {
            self.filterType.setTitle(filterTypeSelected.text + "\u{2304}", for: .normal)
            
            if filterTypeSelected == .showNotes {
                self.webView.isHidden = false
            } else {
                self.webView.isHidden = true
            }
        }
    }
    
    @IBOutlet weak var episodeTitle: UILabel!
    @IBOutlet weak var headerImageView: UIImageView!

    @IBOutlet weak var localMultiButton: UIButton!
    @IBOutlet weak var streamButton: UIButton!
    
    @IBOutlet weak var filterType: UIButton!
    @IBOutlet weak var sorting: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.filterTypeSelected = .showNotes
        setupNotificationListeners()
        loadHeaderButtons()
        setupWebView()
        loadData()
    }
    
    deinit {
        removeObservers()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.webView.scrollView.contentInset = UIEdgeInsets.zero;
    }
    
    fileprivate func setupNotificationListeners() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.downloadStarted(_:)), name: .downloadStarted, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.downloadResumed(_:)), name: .downloadResumed, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.downloadPaused(_:)), name: .downloadPaused, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.downloadFinished(_:)), name: .downloadFinished, object: nil)
    }
    
    fileprivate func removeObservers() {
        NotificationCenter.default.removeObserver(self, name: .downloadStarted, object: nil)
        NotificationCenter.default.removeObserver(self, name: .downloadResumed, object: nil)
        NotificationCenter.default.removeObserver(self, name: .downloadPaused, object: nil)
        NotificationCenter.default.removeObserver(self, name: .downloadFinished, object: nil)
    }
    
    func setupWebView() {
        
        if let mediaUrl = self.mediaUrl, let episode = Episode.episodeForMediaUrl(mediaUrlString: mediaUrl, managedObjectContext: self.moc) {
            
            if let summary = episode.summary {
                self.webView.loadHTMLString(summary.formatHtmlString(isWhiteBg: true), baseURL: nil)
            }
            
            self.webView.delegate = self
        }
        
    }
    
    @IBAction func downloadPlay(_ sender: Any) {
        
        if let mediaUrl = self.mediaUrl, let episode = Episode.episodeForMediaUrl(mediaUrlString: mediaUrl, managedObjectContext: self.moc) {
            
            if episode.fileName != nil {
                
                let playerHistoryItem: PlayerHistoryItem?
                
                if let mediaUrl = episode.mediaUrl, let item = playerHistoryManager.retrieveExistingPlayerHistoryItem(mediaUrl: mediaUrl) {
                    playerHistoryItem = item
                } else {
                    playerHistoryItem = playerHistoryManager.convertEpisodeToPlayerHistoryItem(episode: episode)
                }
                
                goToNowPlaying()
                
                if let item = playerHistoryItem {
                    self.pvMediaPlayer.loadPlayerHistoryItem(item: item)
                }
                
            } else {
                if reachability.hasWiFiConnection() == false {
                    showInternetNeededAlertWithDesciription(message: "Connect to WiFi to download an episode.")
                    return
                }
                PVDownloader.shared.startDownloadingEpisode(episode: episode)
            }
            
        }
    }
    
    @IBAction func stream(_ sender: Any) {
        
        if let mediaUrl = self.mediaUrl, let episode = Episode.episodeForMediaUrl(mediaUrlString: mediaUrl, managedObjectContext: self.moc) {
            let item = playerHistoryManager.convertEpisodeToPlayerHistoryItem(episode: episode)
            
            goToNowPlaying()
            
            self.pvMediaPlayer.loadPlayerHistoryItem(item: item)
        }

    }
    
    
    @IBAction func updateFilter(_ sender: Any) {
        
        let alert = UIAlertController(title: "From this Episode", message: nil, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Show Notes", style: .default, handler: { action in
            self.filterTypeSelected = .showNotes
            self.loadData()
        }))
        
        alert.addAction(UIAlertAction(title: "Clips", style: .default, handler: { action in
            self.filterTypeSelected = .clips
            self.loadData()
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
        
    }
    
    @IBAction func updateSorting(_ sender: Any) {
    }
    
    func loadData() {
        
        if let feedUrl = feedUrl, let podcast = Podcast.podcastForFeedUrl(feedUrlString: feedUrl, managedObjectContext: moc), let mediaUrl = mediaUrl, let episode = Episode.episodeForMediaUrl(mediaUrlString: mediaUrl, managedObjectContext: moc) {

            episodeTitle.text = episode.title
            
            self.headerImageView.image = Podcast.retrievePodcastImage(podcastImageURLString: podcast.imageUrl, feedURLString: podcast.feedUrl, managedObjectID: podcast.objectID, completion: { _ in
                self.headerImageView.sd_setImage(with: URL(string: podcast.imageUrl ?? ""), placeholderImage: #imageLiteral(resourceName: "PodverseIcon"))
            })
            
            if self.filterTypeSelected == .showNotes {
                print("show notes filter selected")
            } else if self.filterTypeSelected == .clips {
                print("clips filter selected")
            }
            
        }
        
    }
    
    func loadHeaderButtons() {

        if let feedUrl = feedUrl, let podcast = Podcast.podcastForFeedUrl(feedUrlString: feedUrl, managedObjectContext: moc), let mediaUrl = mediaUrl, let episode = Episode.episodeForMediaUrl(mediaUrlString: mediaUrl, managedObjectContext: moc) {
            
            if (DownloadingEpisodeList.shared.downloadingEpisodes.contains(where: {$0.mediaUrl == mediaUrl})) {
                self.streamButton.isHidden = false
                self.streamButton.setTitle("Stream", for: .normal)
                self.localMultiButton.setTitle("Downloading", for: .normal)
                
            } else if episode.fileName == nil {
                self.streamButton.isHidden = false
                self.streamButton.setTitle("Stream", for: .normal)
                self.localMultiButton.setTitle("Download", for: .normal)
            } else {
                self.streamButton.isHidden = true
                self.localMultiButton.setTitle("Play", for: .normal)
            }
        }
        
    }
    
    override func goToNowPlaying () {
        if let mediaPlayerVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MediaPlayerVC") as? MediaPlayerViewController {
            pvMediaPlayer.shouldAutoplayOnce = true
            self.navigationController?.pushViewController(mediaPlayerVC, animated: true)
        }
    }
    
}

extension EpisodeTableViewController:UIWebViewDelegate {
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

extension EpisodeTableViewController {
    
    func updateButtonsByNotification(_ notification:Notification) {
        
        if let downloadingEpisode = notification.userInfo?[Episode.episodeKey] as? DownloadingEpisode, let dlMediaUrl = downloadingEpisode.mediaUrl, let mediaUrl = self.mediaUrl, dlMediaUrl == mediaUrl {
            loadHeaderButtons()
        }

    }
    
    func downloadFinished(_ notification:Notification) {
        updateButtonsByNotification(notification)
    }
    
    func downloadPaused(_ notification:Notification) {
        updateButtonsByNotification(notification)
    }
    
    func downloadResumed(_ notification:Notification) {
        updateButtonsByNotification(notification)
    }
    
    func downloadStarted(_ notification:Notification) {
        updateButtonsByNotification(notification)
    }
        
}

