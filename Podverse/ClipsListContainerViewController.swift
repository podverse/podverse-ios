//
//  ClipsListContainerViewController.swift
//  Podverse
//
//  Created by Creon Creonopoulos on 5/30/17.
//  Copyright © 2017 Podverse LLC. All rights reserved.
//

import UIKit

protocol ClipsListDelegate:class {
    func didSelectClip(clip:MediaRef)
}

class ClipsListContainerViewController: UIViewController {

    @IBOutlet weak var segmentControl: UISegmentedControl!
    @IBOutlet weak var tableView: UITableView!
    
    let pvMediaPlayer = PVMediaPlayer.shared
    var clipsArray = [MediaRef]()
    weak var delegate:ClipsListDelegate?

    @IBAction func segmentSelect(_ sender: UISegmentedControl) {
        clipsArray.removeAll()
        self.reloadClipData()
        if let item = pvMediaPlayer.currentlyPlayingItem {
            switch sender.selectedSegmentIndex {
            case 0:
                MediaRef.shared.retrieveMediaRefsFromServer(episodeMediaUrl: item.episodeMediaUrl, podcastFeedUrl: nil) { (mediaRefs) -> Void in
                    self.reloadClipData(mediaRefs: mediaRefs)
                }
            case 1:
                MediaRef.shared.retrieveMediaRefsFromServer(episodeMediaUrl: nil, podcastFeedUrl: item.podcastFeedUrl) { (mediaRefs) -> Void in
                    self.reloadClipData(mediaRefs: mediaRefs)
                }
            case 2:
                MediaRef.shared.retrieveMediaRefsFromServer(episodeMediaUrl: nil, podcastFeedUrl: nil) { (mediaRefs) -> Void in
                    self.reloadClipData(mediaRefs: mediaRefs)
                }
            default:
                break
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.separatorColor = .clear
        
        if let item = pvMediaPlayer.currentlyPlayingItem {
            MediaRef.shared.retrieveMediaRefsFromServer(episodeMediaUrl: item.episodeMediaUrl, podcastFeedUrl: nil) { (mediaRefs) -> Void in
                DispatchQueue.main.async {
                    self.reloadClipData(mediaRefs: mediaRefs)
                }
            }
        }
    }
    
    func reloadClipData(mediaRefs: [MediaRef]? = nil) {
        if let mediaRefs = mediaRefs {
            for mediaRef in mediaRefs {
                self.clipsArray.append(mediaRef)
            }
        }
        self.tableView.reloadData()
    }
}

extension ClipsListContainerViewController:UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return clipsArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "mediaPlayerClipCell", for:indexPath) as! MediaPlayerClipTableViewCell
        let clip = clipsArray[indexPath.row]
        
        if let title = clip.title {
            cell.clipTitle.text = title
        }
        
        if let startTime = clip.startTime {
            cell.startTime.text = startTime.toMediaPlayerString()
        }
        
        if let endTime = clip.endTime {
            cell.endTime.text = endTime.toMediaPlayerString()
        }
        
        return cell

    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.delegate?.didSelectClip(clip: self.clipsArray[indexPath.row])
    }
}
