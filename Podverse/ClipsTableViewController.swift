//
//  ClipsTableViewController.swift
//  Podverse
//
//  Created by Mitchell Downey on 6/6/17.
//  Copyright © 2017 Podverse LLC. All rights reserved.
//

import UIKit

class ClipsTableViewController: UIViewController {

    var clipsArray = [MediaRef]()
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        MediaRef.retrieveMediaRefsFromServer() { (mediaRefs) -> Void in
            self.reloadClipData(mediaRefs: mediaRefs)
        }

    }
    
    func reloadClipData(mediaRefs: [MediaRef]? = nil) {
        for mediaRef in mediaRefs ?? [] {
            self.clipsArray.append(mediaRef)
        }
        self.tableView.reloadData()
    }
    

}

extension ClipsTableViewController:UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return clipsArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let clip = clipsArray[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "clipCell", for: indexPath) as! ClipTableViewCell
        
        cell.podcastTitle?.text = clip.podcastTitle
        cell.episodeTitle?.text = clip.episodeTitle
        cell.clipTitle?.text = clip.title
        
        var time: String?
        
        if let startTime = clip.startTime {
            if let endTime = clip.endTime {
                if endTime > 0 {
                    time = startTime.toMediaPlayerString() + " to " + endTime.toMediaPlayerString()
                }
            } else {
                time = "Starts:" + startTime.toMediaPlayerString()
            }
        }
        
        if let time = time {
            cell.time?.text = time
        }
        
        if let episodePubDate = clip.episodePubDate {
            cell.episodePubDate?.text = episodePubDate.toShortFormatString()
        }
        
        DispatchQueue.global().async {
            var cellImage:UIImage?
            // TODO: remotely retrieve cell image, if it isn't saved with a podcast locally
            cellImage = UIImage(named: "PodverseIcon")

            DispatchQueue.main.async {
                if let visibleRows = self.tableView.indexPathsForVisibleRows, visibleRows.contains(indexPath) {
                    let existingCell = self.tableView.cellForRow(at: indexPath) as! ClipTableViewCell
                    existingCell.podcastImage.image = cellImage
                }
            }
        }
        
        return cell
    }
    
}

//extension PodcastsTableViewController:UITableViewDelegate, UITableViewDataSource {
//    // MARK: - Table view data source


//    
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        self.performSegue(withIdentifier: "Show Episodes", sender: nil)
//        tableView.deselectRow(at: indexPath, animated: true)
//    }
//    
//    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
//        return true
//    }
//    
//    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
//        let podcastToEdit = subscribedPodcastsArray[indexPath.row]
//        var subscribeOrFollow = "Subscribe"
//        
//        let subscribeOrFollowAction = UITableViewRowAction(style: .default, title: subscribeOrFollow, handler: {action, indexpath in
//            if subscribeOrFollow == "Subscribe" {
//                //PVSubscriber.subscribeToPodcast(podcastToEdit.feedUrl, podcastTableDelegate: self)
//            } else {
//                //PVFollower.followPodcast(podcastToEdit.feedUrl, podcastTableDelegate: self)
//            }
//        })
//        
//        subscribeOrFollowAction.backgroundColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0);
//        
//        let deleteAction = UITableViewRowAction(style: .default, title: "Delete", handler: {action, indexpath in
//            
//            // Remove Player button if the now playing episode was one of the podcast's episodes
//            //            if let nowPlayingEpisode = PVMediaPlayer.shared.currentlyPlayingItem {
//            ////                if podcastToEdit.episodes.contains(nowPlayingEpisode) {
//            ////                    self.navigationItem.rightBarButtonItem = nil
//            ////                }
//            //            }
//            self.subscribedPodcastsArray.remove(at: indexPath.row)
//            self.tableView.deleteRows(at: [indexPath], with: .fade)
//            
//            //PVFollower.unfollowPodcast(podcastToEdit.objectID, completionBlock: nil)
//            
//            //self.showFindAPodcastIfNoneAreFollowed()
//        })
//        
//        return [deleteAction, subscribeOrFollowAction]
//    }
//    
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        let episodesTableViewController = segue.destination as! EpisodesTableViewController
//        
//        if let index = tableView.indexPathForSelectedRow {
//            if segue.identifier == "Show Episodes" {
//                episodesTableViewController.selectedPodcastID = subscribedPodcastsArray[index.row].objectID
//            }
//        }
//        
//    }
//}
