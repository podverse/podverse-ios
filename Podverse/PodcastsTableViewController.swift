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

class PodcastsTableViewController: PVViewController {

    @IBOutlet weak var tableView: UITableView!
    
    var subscribedPodcastsArray = [Podcast]()
    let reachability = PVReachability.shared
    let refreshControl = UIRefreshControl()
    
    let moc = CoreDataHelper.createMOCForThread(threadType: .mainThread)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if UserDefaults.standard.object(forKey: "ONE_TIME_LOGIN") == nil {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginVC") as? LoginViewController {
                self.present(loginVC, animated: false, completion: nil)
            }
            
            UserDefaults.standard.set(NSUUID().uuidString, forKey: "ONE_TIME_LOGIN")
        }

        self.navigationItem.title = "Podcasts"
        self.tabBarController?.tabBar.isTranslucent = false
        
        self.refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh all podcasts")
        self.refreshControl.addTarget(self, action: #selector(refreshPodcastFeeds), for: UIControlEvents.valueChanged)
        self.tableView.addSubview(refreshControl)
        
        refreshPodcastFeeds()
        loadPodcastData()
        NotificationCenter.default.addObserver(self, selector: #selector(self.downloadFinished(_:)), name: .downloadFinished, object: nil)
    }
    
    @objc fileprivate func refreshPodcastFeeds() {
        if reachability.hasInternetConnection() == false && refreshControl.isRefreshing == true {
            showInternetNeededAlertWithDesciription(message:"Connect to WiFi or cellular data to parse podcast feeds.")
            self.refreshControl.endRefreshing()
            return
        }
        
        let podcastArray = CoreDataHelper.fetchEntities(className:"Podcast", predicate: nil, moc:moc) as! [Podcast]
        
        for podcast in podcastArray {
            let feedUrl = NSURL(string:podcast.feedUrl)
            
            let pvFeedParser = PVFeedParser(shouldOnlyGetMostRecentEpisode: true, shouldSubscribe:false, shouldOnlyParseChannel: false)
            pvFeedParser.delegate = self
            if let feedUrlString = feedUrl?.absoluteString {
                pvFeedParser.parsePodcastFeed(feedUrlString: feedUrlString)
            }
        }

        refreshControl.endRefreshing()
    }
    
    func loadPodcastData() {
        self.subscribedPodcastsArray = CoreDataHelper.fetchEntities(className:"Podcast", predicate: nil, moc:moc) as! [Podcast]
        self.subscribedPodcastsArray.sort(by: { $0.title.removeArticles() < $1.title.removeArticles() } )
        
        self.tableView.reloadData()
    }
}

extension PodcastsTableViewController:PVFeedParserDelegate {
    func feedParsingComplete(feedUrl:String?) {
        if let url = feedUrl, let index = self.subscribedPodcastsArray.index(where: { url == $0.feedUrl }) {
            let podcast = CoreDataHelper.fetchEntityWithID(objectId: self.subscribedPodcastsArray[index].objectID, moc: moc) as! Podcast
            self.subscribedPodcastsArray[index] = podcast
            self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
        }
        else {
            loadPodcastData()
        }
        
        if let navVCs = self.navigationController?.viewControllers, navVCs.count > 1, 
           let episodesTableVC = self.navigationController?.viewControllers[1] as? EpisodesTableViewController {
            episodesTableVC.loadData()
        }
    }
    
    func feedParsingStarted() { }
    
    func feedParserChannelParsed() { }
}

extension PodcastsTableViewController:UITableViewDelegate, UITableViewDataSource {
    // MARK: - Table view data source
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Subscribed"
        } else {
            return "Following"
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 92
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return subscribedPodcastsArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "podcastCell", for: indexPath) as! PodcastTableViewCell
        
        let podcast = subscribedPodcastsArray[indexPath.row]
        
        cell.title?.text = podcast.title
        
        let episodes = podcast.episodes
        let episodesDownloaded = episodes.filter{ $0.fileName != nil }
        cell.totalEpisodes?.text = "\(episodesDownloaded.count) downloaded"
        
        cell.totalClips?.text = "123 clips"
        
        cell.lastPublishedDate?.text = ""
        if let lastPubDate = podcast.lastPubDate {
            //cell.lastPublishedDate?.text = PVUtility.formatDateToString(lastPubDate)
        }
        
        cell.pvImage.image = Podcast.retrievePodcastImage(managedObjectID: podcast.objectID)
        
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
        let podcastToEdit = subscribedPodcastsArray[indexPath.row]
        
        let deleteAction = UITableViewRowAction(style: .default, title: "Delete", handler: {action, indexpath in
            self.subscribedPodcastsArray.remove(at: indexPath.row)
            self.tableView.deleteRows(at: [indexPath], with: .fade)
            if self.pvMediaPlayer.nowPlayingItem?.podcastFeedUrl == podcastToEdit.feedUrl {
                self.tabBarController?.hidePlayerView()
            }
            PVDeleter.deletePodcast(podcastId: podcastToEdit.objectID)
        })
        
        return [deleteAction]
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let index = tableView.indexPathForSelectedRow {
            if segue.identifier == "Show Episodes" {
                let episodesTableViewController = segue.destination as! EpisodesTableViewController
                episodesTableViewController.selectedPodcastID = subscribedPodcastsArray[index.row].objectID
            }
        }
        
    }

}

extension PodcastsTableViewController {
    func downloadFinished(_ notification:Notification) {
        if let episode = notification.userInfo?[Episode.episodeKey] as? DownloadingEpisode,
            let index = self.subscribedPodcastsArray.index(where: { $0.feedUrl == episode.podcastFeedUrl }), 
            let cell = self.tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? PodcastTableViewCell {
            let episodes = subscribedPodcastsArray[index].episodes
            let episodesDownloaded = episodes.filter{ $0.fileName != nil }
            cell.totalEpisodes?.text = "\(episodesDownloaded.count) downloaded"
        }
    }
    
    override func episodeDeleted(_ notification:Notification) {
        super.episodeDeleted(notification)
        
        if let mediaUrl = notification.userInfo?["mediaUrl"] as? String, let episodes = CoreDataHelper.fetchEntities(className: "Episode", predicate: NSPredicate(format: "mediaUrl == %@", mediaUrl), moc: moc) as? [Episode], let episode = episodes.first, let index = self.subscribedPodcastsArray.index(where: { $0.feedUrl == episode.podcast.feedUrl }) {
            DispatchQueue.main.async {
                self.subscribedPodcastsArray[index] = episode.podcast
                self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
            }
        }
    }
    
    override func podcastDeleted(_ notification:Notification) {
        super.podcastDeleted(notification)
        if let feedUrl = notification.userInfo?["feedUrl"] as? String, let index = self.subscribedPodcastsArray.index(where: { $0.feedUrl == feedUrl }) {
            DispatchQueue.main.async {
                self.tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
            }
        }
    }
}
