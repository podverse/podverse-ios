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
    
    @IBOutlet weak var parsingActivityContainer: UIView!
    
    var subscribedPodcastsArray = [Podcast]()
    let coreDataHelper = CoreDataHelper.shared
    //var playlistManager = PlaylistManager.shared
    let parsingPodcasts = ParsingPodcastsList.shared
    let reachability = PVReachability.shared
    var refreshControl: UIRefreshControl!
    
    override func viewDidAppear(_ animated: Bool) {
        PVAudioSearch.getAudiosearchAccessToken()
    }
    
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

        navigationItem.title = "Podcasts"
        
        tabBarController?.tabBar.isTranslucent = false
        
//        bottomButton.hidden = true
        
        refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh all podcasts")
        refreshControl.addTarget(self, action: #selector(refreshPodcastData), for: UIControlEvents.valueChanged)
        tableView.addSubview(refreshControl)
        
//        NotificationCenter.default.addObserver(self, selector: #selector(loadPodcastData), name: NSNotification.Name(rawValue: kDownloadHasFinished), object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(clearParsingActivity), name: NSNotification.Name(rawValue: kInternetIsUnreachable), object: nil)
        updateParsingActivity()
        
        if isFirstTimeAppOpened != true {
            reloadAllData()
        }
        
//        startCheckSubscriptionsForNewEpisodesTimer()
    }
        
    func refreshPodcastData() {
        if reachability.hasInternetConnection() == false && refreshControl.isRefreshing == true {
            showInternetNeededAlertWithDesciription(message:"Connect to WiFi or cellular data to parse podcast feeds.")
            refreshControl.endRefreshing()
            return
        }
        refreshPodcastFeeds()
    }
    
    fileprivate func refreshPodcastFeeds() {
        let moc = CoreDataHelper.createMOCForThread(threadType: .mainThread)
        
        let podcastsPredicate = NSPredicate(format: "isSubscribed == YES")
        let podcastArray = CoreDataHelper.fetchEntities(className:"Podcast", predicate: podcastsPredicate, moc:moc) as! [Podcast]
        
        for podcast in podcastArray {
            parsingPodcasts.urls.append(podcast.feedUrl)
            let feedUrl = NSURL(string:podcast.feedUrl)
            
            let feedParser = PVFeedParser(shouldOnlyGetMostRecentEpisode: true, shouldSubscribe:false, shouldFollowPodcast: false, shouldOnlyParseChannel: false)
            feedParser.delegate = self
            if let feedUrlString = feedUrl?.absoluteString {
                feedParser.parsePodcastFeed(feedUrlString: feedUrlString)
                self.updateParsingActivity()
            }
        }
        
//        showFindAPodcastIfNoneAreFollowed()
        
        refreshControl.endRefreshing()
    }
    
    func loadPodcastData() {
        let subscribedPredicate = NSPredicate(format: "isSubscribed == YES")
        let moc = CoreDataHelper.createMOCForThread(threadType: .mainThread)
        self.subscribedPodcastsArray = CoreDataHelper.fetchEntities(className:"Podcast", predicate: subscribedPredicate, moc:moc) as! [Podcast]
        self.subscribedPodcastsArray.sort(by: { $0.title.removeArticles() < $1.title.removeArticles() } )
        
        for podcast in self.subscribedPodcastsArray {
            let podcastPredicate = NSPredicate(format: "podcast == %@", podcast)
            if let mostRecentEpisode = CoreDataHelper.fetchEntityWithMostRecentPubDate(className:"Episode", predicate: podcastPredicate, moc:moc) as? Episode {
                podcast.lastPubDate = mostRecentEpisode.pubDate
            }
        }
        
        self.tableView.reloadData()
        moc.saveData(nil)
    }
    
    fileprivate func reloadAllData() {
        loadPodcastData()
        refreshPodcastFeeds()
    }
    
    func clearParsingActivity() {
        parsingPodcasts.itemsParsing = 0
        self.parsingActivityContainer.isHidden = true
    }
    
    func updateParsingActivity() {
//        self.parsingActivityLabel.text = "\(parsingPodcasts.itemsParsing) of \(parsingPodcasts.urls.count) parsed"
//        self.parsingActivityBar.progress = Float(parsingPodcasts.itemsParsing)/Float(parsingPodcasts.urls.count)
//        
//        if parsingPodcasts.itemsParsing >= parsingPodcasts.urls.count {
//            self.parsingActivityContainer.hidden = true
//            self.parsingActivity.stopAnimating()
//        }
//        else {
//            self.parsingActivityContainer.hidden = false
//            self.parsingActivity.startAnimating()
//        }
    }
}

extension PodcastsTableViewController:PVFeedParserDelegate {
    func feedParsingComplete(feedUrl:String?) {
        let moc = CoreDataHelper.createMOCForThread(threadType: .mainThread)
        
        if let url = feedUrl, let index = self.subscribedPodcastsArray.index(where: { url == $0.feedUrl }) {
            let podcast = CoreDataHelper.fetchEntityWithID(objectId: self.subscribedPodcastsArray[index].objectID, moc: moc) as! Podcast
            self.subscribedPodcastsArray[index] = podcast
            self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
        }
        else {
            self.loadPodcastData()
        }
        
        updateParsingActivity()
    }
    
    func feedParsingStarted() {
        updateParsingActivity()
    }
    
    func feedParserChannelParsed() {
        self.loadPodcastData()
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
        cell.episodesDownloadedOrStarted?.text = "\(episodesDownloaded.count) downloaded"
        
        cell.totalClips?.text = "123 clips"
        
        cell.lastPublishedDate?.text = ""
        if let lastPubDate = podcast.lastPubDate {
            //cell.lastPublishedDate?.text = PVUtility.formatDateToString(lastPubDate)
        }
        
        DispatchQueue.global().async {
            Podcast.retrievePodcastUIImage(podcast: podcast) { (podcastImage) -> Void in
                DispatchQueue.main.async {
                    if let visibleRows = self.tableView.indexPathsForVisibleRows, visibleRows.contains(indexPath) {
                        let existingCell = self.tableView.cellForRow(at: indexPath) as! PodcastTableViewCell
                        existingCell.pvImage.image = podcastImage
                    }
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
        var subscribeOrFollow = "Subscribe"
        
        let subscribeOrFollowAction = UITableViewRowAction(style: .default, title: subscribeOrFollow, handler: {action, indexpath in
            if subscribeOrFollow == "Subscribe" {
                //PVSubscriber.subscribeToPodcast(podcastToEdit.feedUrl, podcastTableDelegate: self)
            } else {
                //PVFollower.followPodcast(podcastToEdit.feedUrl, podcastTableDelegate: self)
            }
        })
        
        subscribeOrFollowAction.backgroundColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0);
        
        let deleteAction = UITableViewRowAction(style: .default, title: "Delete", handler: {action, indexpath in
            
            // Remove Player button if the now playing episode was one of the podcast's episodes
//            if let nowPlayingEpisode = PVMediaPlayer.shared.currentlyPlayingItem {
////                if podcastToEdit.episodes.contains(nowPlayingEpisode) {
////                    self.navigationItem.rightBarButtonItem = nil
////                }
//            }
            self.subscribedPodcastsArray.remove(at: indexPath.row)
            self.tableView.deleteRows(at: [indexPath], with: .fade)
            
            //PVFollower.unfollowPodcast(podcastToEdit.objectID, completionBlock: nil)
            
            //self.showFindAPodcastIfNoneAreFollowed()
        })
        
        return [deleteAction, subscribeOrFollowAction]
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
