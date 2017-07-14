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
    let coreDataHelper = CoreDataHelper.shared
    let reachability = PVReachability.shared
    let refreshControl = UIRefreshControl()
    
    let moc = CoreDataHelper.createMOCForThread(threadType: .mainThread)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var isFirstTimeAppOpened: Bool = false
        
        if UserDefaults.standard.object(forKey: "ONE_TIME_LOGIN") == nil {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginVC") as? LoginViewController {
                loginVC.delegate = self
                self.present(loginVC, animated: false, completion: nil)
            }
            UserDefaults.standard.set(NSUUID().uuidString, forKey: "ONE_TIME_LOGIN")
            isFirstTimeAppOpened = true
        }

        self.navigationItem.title = "Podcasts"
        self.tabBarController?.tabBar.isTranslucent = false
        
        self.refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh all podcasts")
        self.refreshControl.addTarget(self, action: #selector(refreshPodcastData), for: UIControlEvents.valueChanged)
        self.tableView.addSubview(refreshControl)
        
        if isFirstTimeAppOpened != true {
            refreshPodcastFeeds()
        }
        
//        startCheckSubscriptionsForNewEpisodesTimer()
    }
        
    func refreshPodcastData() {
        if reachability.hasInternetConnection() == false && refreshControl.isRefreshing == true {
            showInternetNeededAlertWithDesciription(message:"Connect to WiFi or cellular data to parse podcast feeds.")
            self.refreshControl.endRefreshing()
            return
        }
        refreshPodcastFeeds()
    }
    
    fileprivate func refreshPodcastFeeds() {
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
    }
    
    func feedParsingStarted() { }
    
    func feedParserChannelParsed() {
        loadPodcastData()
    }
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
        
        Podcast.retrievePodcastUIImage(podcastFeedUrl: podcast.feedUrl, podcastImageUrl: podcast.imageUrl, managedObjectId: podcast.objectID) { (podcastImage) -> Void in
            DispatchQueue.main.async {
                if let visibleRows = self.tableView.indexPathsForVisibleRows, visibleRows.contains(indexPath) {
                    let existingCell = self.tableView.cellForRow(at: indexPath) as! PodcastTableViewCell
                    existingCell.pvImage.image = podcastImage
                }
            }
        }
        
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
            DispatchQueue.global().async {
                PVDeleter.deletePodcast(podcastId: podcastToEdit.objectID, feedUrl: nil)
            }
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

extension PodcastsTableViewController:LoginModalDelegate {
    func loginTapped() {
        PVAuth.sharedInstance.showAuth0LockLoginVC(vc: self)
    }
}
