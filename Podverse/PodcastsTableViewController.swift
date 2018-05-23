//
//  PodcastsTableViewController.swift
//  Podverse
//
//  Created by Creon on 12/15/16.
//  Copyright © 2016 Podverse LLC. All rights reserved.
//

import UIKit
import CoreData
import Lock

class PodcastsTableViewController: PVViewController, AutoDownloadProtocol {

    @IBOutlet weak var parseActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var parseStatus: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    let moc = CoreDataHelper.createMOCForThread(threadType: .mainThread)
    
    let parsingPodcasts = ParsingPodcasts.shared
    let reachability = PVReachability.shared
    let refreshControl = UIRefreshControl()
    var subscribedPodcastsArray = [Podcast]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Podcasts"
        
        if UserDefaults.standard.object(forKey: "ONE_TIME_LOGIN") == nil {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginVC") as? LoginViewController {
                self.present(loginVC, animated: false, completion: nil)
            }
            
            UserDefaults.standard.set(NSUUID().uuidString, forKey: "ONE_TIME_LOGIN")
        }
        
        self.parseStatus.text = ""

        self.tabBarController?.tabBar.isTranslucent = false
        
        self.refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh all podcasts")
        self.refreshControl.addTarget(self, action: #selector(refreshPodcastFeeds), for: UIControlEvents.valueChanged)
        self.tableView.addSubview(refreshControl)
        
        self.parseActivityIndicator.hidesWhenStopped = true
        
        
        if let lastParsedDate = UserDefaults.standard.object(forKey: kLastParsedDate) as? Date {
            if let diff = Calendar.current.dateComponents([.hour], from: lastParsedDate, to: Date()).hour, diff > 1 {
                if PVAuth.userIsLoggedIn {
                    DispatchQueue.global().async {
                        Podcast.syncSubscribedPodcastsWithServer()
                    }
                } else {
                    refreshPodcastFeeds()
                }
            } else {
                self.parseStatus.text = "Updated: " + lastParsedDate.toString()
            }
        }
        // Else if it is the first time a user has logged in before anything has been parsed
        else if PVAuth.userIsLoggedIn {
            DispatchQueue.global().async {
                Podcast.syncSubscribedPodcastsWithServer()
            }
            
            self.parseStatus.text = "Syncing with server"
            self.parseActivityIndicator.startAnimating()
        }
        
        loadPodcastData()
        
        
        addObservers()
    }
    
    deinit {
        removeObservers()
    }
    
    fileprivate func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.loggedInSuccessfully), name: .loggedInSuccessfully, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.feedParsingComplete(_:)), name: .feedParsingComplete, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.downloadFinished(_:)), name: .downloadFinished, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.refreshParsingStatus(_:)), name: NSNotification.Name(rawValue: kBeginParsingPodcast), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.refreshParsingStatus(_:)), name: NSNotification.Name(rawValue: kFinishedParsingPodcast), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.refreshParsingStatus(_:)), name: NSNotification.Name(rawValue: kFinishedAllParsingPodcasts), object: nil)
    }
    
    fileprivate func removeObservers() {
        NotificationCenter.default.removeObserver(self, name: .loggedInSuccessfully, object: nil)
        NotificationCenter.default.removeObserver(self, name: .feedParsingComplete, object: nil)
        NotificationCenter.default.removeObserver(self, name: .downloadFinished, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: kBeginParsingPodcast), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: kFinishedParsingPodcast), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: kFinishedAllParsingPodcasts), object: nil)
    }
    
    @objc fileprivate func refreshPodcastFeeds() {
        
        if checkForConnectivity() == false {

            if refreshControl.isRefreshing == true {
                showInternetNeededAlertWithDescription(message:"Connect to the internet to parse podcast feeds.")
                self.refreshControl.endRefreshing()
            }

            return
        }
        
        DispatchQueue.global().async {
            let privateMoc = CoreDataHelper.createMOCForThread(threadType: .privateThread)
            var podcastArray = CoreDataHelper.fetchEntities(className:"Podcast", predicate: nil, moc:privateMoc) as! [Podcast]
            podcastArray = podcastArray.filter { !DeletingPodcasts.shared.podcastKeys.contains($0.feedUrl) }
            
            for podcast in podcastArray {
                let feedUrl = NSURL(string:podcast.feedUrl)
                let podcastId = podcast.id
                
                let pvFeedParser = PVFeedParser(shouldOnlyGetMostRecentEpisode: true, shouldSubscribe:false, podcastId: podcastId)
                if let feedUrlString = feedUrl?.absoluteString {
                    pvFeedParser.parsePodcastFeed(feedUrlString: feedUrlString)
                }
            }
        }

        self.refreshControl.endRefreshing()
        
    }
    
    func updateLastParsedDate() {
        self.parseActivityIndicator.stopAnimating()
        if let lastParsedDate = UserDefaults.standard.object(forKey: kLastParsedDate) as? Date {
            self.parseStatus.text = "Updated: " + lastParsedDate.toString()
        }
    }
    
    func loadPodcastData() {
        self.moc.refreshAllObjects()
        self.subscribedPodcastsArray = CoreDataHelper.fetchEntities(className:"Podcast", predicate: nil, moc:self.moc) as! [Podcast]
        self.subscribedPodcastsArray = self.subscribedPodcastsArray.filter { !DeletingPodcasts.shared.podcastKeys.contains($0.feedUrl) }
        
        guard checkForResults(results: subscribedPodcastsArray) else {
            self.loadNoPodcastsSubscribedMessage()
            return
        }
        
        self.subscribedPodcastsArray.sort(by: { $0.title.removeArticles() < $1.title.removeArticles() } )
        
        self.tableView.isHidden = false
        self.tableView.reloadData()
        
    }

    func podcastAutodownloadChanged(feedUrl: String) {
        if let index = self.subscribedPodcastsArray.index(where: {$0.feedUrl == feedUrl}) {
            self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
        }
    }
    
    func loadNoDataView(message: String, buttonTitle: String?, buttonPressed: Selector?) {
        
        if let noDataView = self.view.subviews.first(where: { $0.tag == kNoDataViewTag}) {
            
            if let messageView = noDataView.subviews.first(where: {$0 is UILabel}), let messageLabel = messageView as? UILabel {
                messageLabel.text = message
            }
            
            if let buttonView = noDataView.subviews.first(where: {$0 is UIButton}), let button = buttonView as? UIButton {
                button.setTitle(buttonTitle, for: .normal)
                button.setTitleColor(.blue, for: .normal)
            }
        }
        else {
            self.addNoDataViewWithMessage(message, buttonTitle: buttonTitle, buttonImage: nil, retryPressed: buttonPressed)
        }
        
        self.tableView.isHidden = true
        
        showNoDataView()
        
    }
    
    func loadNoPodcastsSubscribedMessage() {
        loadNoDataView(message: Strings.Errors.noPodcastsSubscribed, buttonTitle: nil, buttonPressed: nil)
    }
    
}


extension PodcastsTableViewController:UITableViewDelegate, UITableViewDataSource {
    // MARK: - Table view data source
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 96.5
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return subscribedPodcastsArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "podcastCell", for: indexPath) as! PodcastTableViewCell
        
        let podcast = subscribedPodcastsArray[indexPath.row]
        
        cell.title?.text = podcast.title
        
        if podcast.shouldAutoDownload() {
            cell.autoDownloadIndicator?.text = "Auto DL ON"
        } else {
            cell.autoDownloadIndicator?.text = "Auto DL OFF"
        }
        
        // TODO: this slows down scrolling too much. How can we have this info without blocking the main thread?
        
        cell.totalEpisodes?.text = "\(podcast.downloadedEpisodes) downloaded"
        
        cell.lastPublishedDate?.text = ""
        if let lastPubDate = podcast.lastPubDate {
            cell.lastPublishedDate?.text = lastPubDate.toShortFormatString()
        }
        
        cell.pvImage.image = Podcast.retrievePodcastImage(podcastImageURLString: podcast.imageUrl, feedURLString: podcast.feedUrl, completion: { image in
           cell.pvImage.image = image
        })
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.performSegue(withIdentifier: "Show Episodes", sender: nil)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let podcastToEditId = self.subscribedPodcastsArray[indexPath.row].id
        let podcastToEditFeedUrl = self.subscribedPodcastsArray[indexPath.row].feedUrl
        
        let deleteAction = UITableViewRowAction(style: .default, title: "Unsubscribe", handler: {action, indexpath in
            self.subscribedPodcastsArray.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            
            if !checkForResults(results: self.subscribedPodcastsArray) {
                self.loadNoPodcastsSubscribedMessage()
            }
            
            PVSubscriber.unsubscribeFromPodcast(podcastId: podcastToEditId, feedUrl: podcastToEditFeedUrl)
        })
        
        return [deleteAction]
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let index = tableView.indexPathForSelectedRow {
            if segue.identifier == "Show Episodes" {
                let episodesTableViewController = segue.destination as! EpisodesTableViewController
                episodesTableViewController.feedUrl = subscribedPodcastsArray[index.row].feedUrl
                episodesTableViewController.delegate = self
            }
        }
        
    }

}

extension PodcastsTableViewController {
    
    @objc func downloadFinished(_ notification:Notification) {
        self.moc.refreshAllObjects()

        if let episode = notification.userInfo?[Episode.episodeKey] as? DownloadingEpisode,
            let index = self.subscribedPodcastsArray.index(where: { $0.feedUrl == episode.podcastFeedUrl }) {
            self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
        }        
    }
    
    override func episodeDeleted(_ notification:Notification) {
        super.episodeDeleted(notification)
        self.moc.refreshAllObjects()
        if let feedUrl = notification.userInfo?["feedUrl"] as? String, let podcasts = CoreDataHelper.fetchEntities(className: "Podcast", predicate: NSPredicate(format: "feedUrl == %@", feedUrl), moc: self.moc) as? [Podcast], let podcast = podcasts.first, let index = self.subscribedPodcastsArray.index(where: { $0.feedUrl == podcast.feedUrl }) {
            DispatchQueue.main.async {
                self.subscribedPodcastsArray[index] = podcast
                self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
            }
        }
    }
    
    @objc func feedParsingComplete(_ notification:Notification) {
        self.moc.refreshAllObjects()
        if let url = notification.userInfo?["feedUrl"] as? String, let index = self.subscribedPodcastsArray.index(where: { url == $0.feedUrl }) {
            
            if let podcast = Podcast.podcastForFeedUrl(feedUrlString: url, managedObjectContext: self.moc) {
                self.subscribedPodcastsArray[index] = podcast
                DispatchQueue.main.async {
                    self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
                }
            }
        }
        else {
            DispatchQueue.main.async {
                self.loadPodcastData()
            }
        }
    }
    
    @objc func loggedInSuccessfully() {
        DispatchQueue.global().async {
            Podcast.syncSubscribedPodcastsWithServer()
        }
        self.parseStatus.text = "Syncing with server"
        self.parseActivityIndicator.startAnimating()
    }
    
    override func podcastDeleted(_ notification:Notification) {
        super.podcastDeleted(notification)
        
        if let podcastId = notification.userInfo?["podcastId"] as? String, let index = self.subscribedPodcastsArray.index(where: { $0.id == podcastId }) {
            
            self.subscribedPodcastsArray.remove(at: index)
            
            DispatchQueue.main.async {
                self.tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .fade)
            }
        } else if let feedUrl = notification.userInfo?["feedUrl"] as? String, let index = self.subscribedPodcastsArray.index(where: { $0.feedUrl == feedUrl }) {
            self.subscribedPodcastsArray.remove(at: index)

            DispatchQueue.main.async {
                self.tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .fade)
            }
        }
    }
    
    @objc func refreshParsingStatus(_ notification:Notification) {
        let total = self.parsingPodcasts.podcastKeys.count
        let currentItem = self.parsingPodcasts.currentlyParsingItem
        
        DispatchQueue.main.async {
            if total > 0 && currentItem < total {
                self.parseActivityIndicator.startAnimating()
                self.parseStatus.text = String(currentItem) + "/" + String(total) + " parsing"
            } else {
                self.updateLastParsedDate()
            }
        }
    }
    
}
