//
//  SearchPodcastViewController.swift
//  Podverse
//
//  Created by Mitchell Downey on 10/21/17.
//  Copyright © 2017 Podverse LLC. All rights reserved.
//

import UIKit

class SearchPodcastViewController: PVViewController {

    var id:String?
    var feedUrl:String?
    var clipsArray = [MediaRef]()
    var episodesArray = [Episode]()
    var filterTypeOverride:SearchPodcastFilter = .about
    let reachability = PVReachability.shared
    
    var filterTypeSelected:SearchPodcastFilter = .about {
        didSet {
//            self.resetClipQuery()
            self.tableViewHeader.filterTitle = self.filterTypeSelected.text
            
            if filterTypeSelected == .clips {
                self.webView.isHidden = true
                self.tableViewHeader.sortingButton.isHidden = false
                self.clipQueryStatusView.isHidden = false
            } else {
                self.webView.isHidden = false
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
    @IBOutlet weak var statusActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var statusView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewHeader: FiltersTableHeaderView!
    @IBOutlet weak var webView: UIWebView!
    
    @IBOutlet weak var clipQueryActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var clipQueryMessage: UILabel!
    @IBOutlet weak var clipQueryStatusView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Preview Page"
        
        self.filterTypeSelected = self.filterTypeOverride
        self.sortingTypeSelected = .topWeek
        
        self.headerActivityIndicator.hidesWhenStopped = true
        
        self.statusActivityIndicator.hidesWhenStopped = true
        
        self.tableViewHeader.delegate = self
        self.tableViewHeader.setupViews()
        
        self.clipQueryActivityIndicator.hidesWhenStopped = true
        self.clipQueryMessage.isHidden = true
        
        let isSubscribed = PVSubscriber.checkIfSubscribed(feedUrlString: self.feedUrl)
        
        loadSubscribeButton(isSubscribed)
        
        loadPodcastData()
        
        if self.filterTypeSelected == .clips {
            retrieveClips()
        }
        
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.webView.scrollView.contentInset = UIEdgeInsets.zero
    }
    
    @IBAction func subscribeTapped(_ sender: Any) {
        
        
        let isSubscribed = PVSubscriber.checkIfSubscribed(feedUrlString: self.feedUrl)
        
        if isSubscribed {
            PVSubscriber.unsubscribeFromPodcast(feedUrlString: self.feedUrl)
        } else {
            DispatchQueue.global().async {
                PVSubscriber.subscribeToPodcast(feedUrlString: self.feedUrl)
            }
        }
        
        loadSubscribeButton(!isSubscribed)
        
    }
    
    func loadPodcastData() {
        if let id = self.id {
            showPodcastHeaderActivity()
            
            SearchPodcast.retrievePodcastFromServer(id: id, completion:{ podcast in
                self.loadPodcastHeader(podcast)
                self.loadAbout(podcast)
            })

        }
    }
    
    func loadSubscribeButton(_ isSubscribed:Bool) {
        if isSubscribed {
            self.headerSubscribe.setTitle("Unsubscribe", for: .normal)
        } else {
            self.headerSubscribe.setTitle("Subscribe", for: .normal)
        }
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
    
    func loadPodcastHeader(_ podcast: SearchPodcast?) {
        
        DispatchQueue.main.async {
            if let podcast = podcast {
                self.headerPodcastTitle.text = podcast.title
                
                self.headerImageView.image = Podcast.retrievePodcastImage(podcastImageURLString: podcast.imageThumbUrl, feedURLString: nil, completion: { image in
                    self.headerImageView.image = image
                })
                
            } else {
                print("error: show not found message")
            }
            
            self.hidePodcastHeaderActivity()
        }

    }
    
    
    func loadAbout(_ podcast: SearchPodcast?) {
        
        DispatchQueue.main.async {
            if let podcast = podcast {
                
                self.webView.delegate = self
                
                var htmlString = ""
                
                if let title = podcast.title {
                    htmlString += "<strong>" + title + "</strong>"
                    htmlString += "<br><br>"
                }
                
                if let categories = podcast.categories {
                    htmlString += "<i>" + categories + "</i>"
                    htmlString += "<br><br>"
                }
                
//                if let hosts = podcast.hosts {
//                    htmlString += "Hosts: " + hosts
//                    htmlString += "<br><br>"
//                }
//
//                if let network = podcast.network {
//                    htmlString += "Network: " + network
//                    htmlString += "<br><br>"
//                }
                
                if let description = podcast.description {
                    
                    if description.trimmingCharacters(in: .whitespacesAndNewlines).count == 0 {
                        htmlString += kNoPodcastAboutMessage
                    } else {
                        htmlString += description
                    }
                    
                    htmlString += "<br><br>"
                    
                }
                
                htmlString += "<br><br>" // add extra line breaks so NowPlayingBar doesn't cover the about text
                
                self.webView.loadHTMLString(htmlString.formatHtmlString(isWhiteBg: true), baseURL: nil)
                
                if self.filterTypeSelected == .about {
                    self.showAbout()
                }
                
            }
        }
        
    }

    func showAbout() {
        DispatchQueue.main.async {
            self.hideNoDataView()
            self.webView.isHidden = false
            self.tableView.isHidden = true
            self.statusView.isHidden = true
        }
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
        
        guard checkForConnectivity() else {
            loadNoInternetMessage()
            return
        }
        
        self.episodesArray.removeAll()
        self.tableView.reloadData()
        
        self.hideNoDataView()
        
        if self.clipQueryPage == 0 {
            showActivityIndicator()
        }
        
        self.clipQueryPage += 1
        
        if let feedUrl = feedUrl {
            MediaRef.retrieveMediaRefsFromServer(podcastFeedUrls: [feedUrl], sortingType: self.sortingTypeSelected, page: self.clipQueryPage) { (mediaRefs) -> Void in
                self.reloadClipData(mediaRefs)
            }
        }
        
    }
    
    func reloadClipData(_ mediaRefs: [MediaRef]? = nil) {
        
        hideActivityIndicator()
        self.clipQueryIsLoading = false
        self.clipQueryActivityIndicator.stopAnimating()
        
        guard checkForResults(results: mediaRefs) || checkForResults(results: self.clipsArray), let mediaRefs = mediaRefs else {
            loadNoClipsMessage()
            return
        }
        
        guard checkForResults(results: mediaRefs) else {
            self.clipQueryEndOfResultsReached = true
            self.clipQueryMessage.isHidden = false
            return
        }
        
        for mediaRef in mediaRefs {
            self.clipsArray.append(mediaRef)
        }
        
        self.tableView.isHidden = false
        self.tableView.reloadData()
        
    }
    
    func loadNoDataView(message: String, buttonTitle: String?, buttonPressed: Selector?) {
        
        if let noDataView = self.view.subviews.first(where: { $0.tag == kNoDataViewTag}) {
            
            if let messageView = noDataView.subviews.first(where: {$0 is UILabel}), let messageLabel = messageView as? UILabel {
                messageLabel.text = message
            }
            
            if let buttonView = noDataView.subviews.first(where: {$0 is UIButton}), let button = buttonView as? UIButton {
                button.setTitle(buttonTitle, for: .normal)
            }
        }
        else {
            self.addNoDataViewWithMessage(message, buttonTitle: buttonTitle, buttonImage: nil, retryPressed: buttonPressed)
        }
        
        self.tableView.isHidden = true
        
        showNoDataView()
        
    }
    
    func loadNoInternetMessage() {
        loadNoDataView(message: Strings.Errors.noClipsInternet, buttonTitle: "Retry", buttonPressed: #selector(SearchPodcastViewController.retrieveClips))
    }
    
    func loadNoClipsMessage() {
        loadNoDataView(message: Strings.Errors.noPodcastClipsAvailable, buttonTitle: nil, buttonPressed: nil)
    }
    
    func showActivityIndicator() {
        self.tableView.isHidden = true
        self.statusActivityIndicator.startAnimating()
        self.statusView.isHidden = false
    }
    
    func hideActivityIndicator() {
        self.statusActivityIndicator.stopAnimating()
        self.statusView.isHidden = true
    }
    
    override func goToNowPlaying () {
        if let mediaPlayerVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MediaPlayerVC") as? MediaPlayerViewController {
            pvMediaPlayer.shouldAutoplayOnce = true
            self.navigationController?.pushViewController(mediaPlayerVC, animated: true)
        }
    }
    
}

extension SearchPodcastViewController:UIWebViewDelegate {
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

extension SearchPodcastViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.clipsArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "clipCell", for: indexPath as IndexPath) as! ClipPodcastTableViewCell
        
        let clip = clipsArray[indexPath.row]
        
        cell.clipTitle.text = clip.readableClipTitle()
        cell.episodeTitle.text = clip.episodeTitle
        cell.episodePubDate.text = clip.episodePubDate?.toShortFormatString()
        cell.time.text = clip.readableStartAndEndTime()
        
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let clip = clipsArray[indexPath.row]
        let playerHistoryItem = self.playerHistoryManager.convertMediaRefToPlayerHistoryItem(mediaRef: clip)
        self.goToNowPlaying()
        self.pvMediaPlayer.loadPlayerHistoryItem(item: playerHistoryItem)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Bottom Refresh
        if scrollView == self.tableView && self.filterTypeSelected == .clips {
            if ((scrollView.contentOffset.y + scrollView.frame.size.height) >= scrollView.contentSize.height) && !self.clipQueryIsLoading && !self.clipQueryEndOfResultsReached {
                self.clipQueryIsLoading = true
                self.clipQueryActivityIndicator.startAnimating()
                self.retrieveClips()
            }
        }
    }
    
}

extension SearchPodcastViewController:FilterSelectionProtocol {
    func filterButtonTapped() {
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: SearchPodcastFilter.about.text, style: .default, handler: { action in
            self.filterTypeSelected = .about
            self.showAbout()
        }))
        
        alert.addAction(UIAlertAction(title: SearchPodcastFilter.clips.text, style: .default, handler: { action in
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
