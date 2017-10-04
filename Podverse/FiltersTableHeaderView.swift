//
//  FiltersTableHeaderView.swift
//  Podverse
//
//  Created by Creon Creonopoulos on 10/3/17.
//  Copyright © 2017 Podverse LLC. All rights reserved.
//

import UIKit

protocol FilterSelectionProtocol {
    func filterButtonTapped()
}

class FiltersTableHeaderView: UIView {

    var delegate:FilterSelectionProtocol?
    var filterTitle = "" {
        didSet {
            filterButton.setTitle(filterTitle, for: .normal)
        }
    }
    
    let filterButton = UIButton()
    let sortingButton = UIButton()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    convenience init(filterTitle:String, presentingViewController:UIViewController) {
        self.init(frame: CGRect.zero)
        self.filterTitle = filterTitle
    }
    
    
    func setupViews() {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.filterButton.translatesAutoresizingMaskIntoConstraints = false
        self.sortingButton.translatesAutoresizingMaskIntoConstraints = false
        
        filterButton.addTarget(self, action: #selector(FiltersTableHeaderView.filterButtonTapped), for: .touchUpInside)
        
        //Add constraints, button titles etc
    }
    
    func filterButtonTapped() {
        delegate?.filterButtonTapped()
    }
}
