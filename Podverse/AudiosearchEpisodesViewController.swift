//
//  AudiosearchEpisodesViewController.swift
//  Podverse
//
//  Created by Mitchell Downey on 10/21/17.
//  Copyright © 2017 Podverse LLC. All rights reserved.
//

import UIKit

class AudiosearchEpisodesViewController: PVViewController {

    var audiosearchId:Int64?
    var clipsArray = [MediaRef]()
    var episodesArray = [Episode]()
    let reachability = PVReachability.shared
    
    var filterTypeSelected:AudiosearchEpisodesFilter = .allEpisodes {
        didSet {
//            self.resetClipQuery()
            self.tableViewHeader.filterTitle = self.filterTypeSelected.text
            
            if filterTypeSelected == .clips {
                self.tableViewHeader.sortingButton.isHidden = false
                self.clipQueryStatusView.isHidden = false
            } else {
                self.tableViewHeader.sortingButton.isHidden = true
                self.clipQueryStatusView.isHidden = true
            }
        }
    }
    
    var sortingTypeSelected:ClipSorting = .topWeek {
        didSet {
//            self.resetClipQuery()
            self.tableViewHeader.sortingTitle = sortingTypeSelected.text
        }
    }
    
    var clipQueryPage:Int = 0
    var clipQueryIsLoading:Bool = false
    var clipQueryEndOfResultsReached:Bool = false
    
    @IBOutlet weak var headerActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var headerImageView: UIImageView!
    @IBOutlet weak var headerPodcastTitle: UILabel!
    @IBOutlet weak var headerSubscribe: UIButton!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var statusActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var statusView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewHeader: FiltersTableHeaderView!
    
    @IBOutlet weak var clipQueryActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var clipQueryMessage: UILabel!
    @IBOutlet weak var clipQueryStatusView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.headerActivityIndicator.hidesWhenStopped = true
        
        self.statusActivityIndicator.hidesWhenStopped = true
        
        self.tableViewHeader.delegate = self
        self.tableViewHeader.setupViews()
        
        self.clipQueryActivityIndicator.hidesWhenStopped = true
        self.clipQueryMessage.isHidden = true
        
        loadPodcastHeader()
        
        reloadEpisodeOrClipData()
        
    }
    
    @IBAction func subscribeTapped(_ sender: Any) {
        
    }
    
    func loadPodcastHeader() {
        
        showPodcastHeaderActivity()
        
        AudiosearchPodcast.retrievePodcastFromServer(id: self.audiosearchId, completion:{ podcast in
            
            DispatchQueue.main.async {
                if let podcast = podcast {
                    self.headerPodcastTitle.text = podcast.title
                    
                    self.headerImageView.image = Podcast.retrievePodcastImage(podcastImageURLString: podcast.imageThumbUrl, feedURLString: nil, managedObjectID:nil, completion: { _ in
                        self.headerImageView.sd_setImage(with: URL(string: podcast.imageThumbUrl ?? ""), placeholderImage: #imageLiteral(resourceName: "PodverseIcon"))
                    })
                    
                } else {
                    print("error: show not found message")
                }
                
                self.hidePodcastHeaderActivity()
            }
            
        })
        
    }
    
    func showPodcastHeaderActivity() {
        self.headerImageView.isHidden = true
        self.headerPodcastTitle.isHidden = true
        self.headerSubscribe.isHidden = true
        self.headerActivityIndicator.startAnimating()
    }
    
    func hidePodcastHeaderActivity() {
        self.headerImageView.isHidden = false
        self.headerPodcastTitle.isHidden = false
        self.headerSubscribe.isHidden = false
        self.headerActivityIndicator.stopAnimating()
    }
    
    func reloadEpisodeOrClipData() {
        
    }
    
    func reloadEpisodeData() {
        
    }
    
    func resetClipQuery() {
        self.clipsArray.removeAll()
        self.clipQueryPage = 0
        self.clipQueryIsLoading = true
        self.clipQueryEndOfResultsReached = false
        self.clipQueryMessage.isHidden = true
        self.tableView.reloadData()
    }
    
    func retrieveClips() {
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension AudiosearchEpisodesViewController:FilterSelectionProtocol {
    func filterButtonTapped() {
        
        let alert = UIAlertController(title: "Show", message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: AudiosearchEpisodesFilter.allEpisodes.text, style: .default, handler: { action in
            self.filterTypeSelected = .allEpisodes
            self.reloadEpisodeData()
        }))
        
        alert.addAction(UIAlertAction(title: AudiosearchEpisodesFilter.clips.text, style: .default, handler: { action in
            self.filterTypeSelected = .clips
            self.retrieveClips()
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
        
    }
    
    func sortingButtonTapped() {
        self.tableViewHeader.showSortByMenu(vc: self)
    }
    
    func sortByRecent() {
        self.sortingTypeSelected = .recent
        self.retrieveClips()
    }
    
    func sortByTop() {
        self.tableViewHeader.showSortByTimeRangeMenu(vc: self)
    }
    
    func sortByTopWithTimeRange(timeRange: SortingTimeRange) {
        
        if timeRange == .day {
            self.sortingTypeSelected = .topDay
        } else if timeRange == .week {
            self.sortingTypeSelected = .topWeek
        } else if timeRange == .month {
            self.sortingTypeSelected = .topMonth
        } else if timeRange == .year {
            self.sortingTypeSelected = .topYear
        } else if timeRange == .allTime {
            self.sortingTypeSelected = .topAllTime
        }
        
        self.retrieveClips()
        
    }
    
}
