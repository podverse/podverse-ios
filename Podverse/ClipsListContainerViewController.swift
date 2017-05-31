//
//  ClipsListContainerViewController.swift
//  Podverse
//
//  Created by Creon Creonopoulos on 5/30/17.
//  Copyright © 2017 Podverse LLC. All rights reserved.
//

import UIKit

protocol ClipsListDelegate:class {
    func didSelectClip(clip:Clip)
}

class ClipsListContainerViewController: UIViewController {

    @IBOutlet weak var segmentControl: UISegmentedControl!
    @IBOutlet weak var tableView: UITableView!
    
    var clipsArray = [Clip]()
    weak var delegate:ClipsListDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.separatorColor = .clear
    }
}

extension ClipsListContainerViewController:UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return clipsArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "mediaPlayerClipCell", for:indexPath)        
        let clip = clipsArray[indexPath.row]
        
        cell.textLabel?.text = clip.title
        cell.detailTextLabel?.text = clip.ownerName
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.delegate?.didSelectClip(clip: self.clipsArray[indexPath.row])
    }
}
