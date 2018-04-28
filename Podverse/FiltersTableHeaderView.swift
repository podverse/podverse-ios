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
    func sortingButtonTapped()
    func sortByRecent()
    func sortByTop()
    func sortByTopWithTimeRange(timeRange: SortingTimeRange)
}

class FiltersTableHeaderView: UIView {

    var delegate:FilterSelectionProtocol?
    var filterTitle = "" {
        didSet {
            DispatchQueue.main.async {
                self.filterButton.setTitle(self.filterTitle + kDropdownCaret, for: .normal)
            }
        }
    }
    
    var sortingTitle = "" {
        didSet {
            DispatchQueue.main.async {
                self.sortingButton.setTitle(self.sortingTitle + kDropdownCaret, for: .normal)
            }
        }
    }
        
    let filterButton = UIButton()
    let sortingButton = UIButton()
    let topBorder = UIView()
    let bottomBorder = UIView()
        
    func setupViews(isBlackBg: Bool = false) {
        
        let titleColor:UIColor = isBlackBg ? .white : .black
        let borderColor:UIColor = isBlackBg ? .darkGray : .lightGray
        
        self.translatesAutoresizingMaskIntoConstraints = false
        self.filterButton.translatesAutoresizingMaskIntoConstraints = false
        self.sortingButton.translatesAutoresizingMaskIntoConstraints = false
        self.topBorder.translatesAutoresizingMaskIntoConstraints = false
        self.bottomBorder.translatesAutoresizingMaskIntoConstraints = false
        
        self.filterButton.setTitle(filterTitle, for: .normal)
        self.filterButton.setTitleColor(titleColor, for: .normal)
        self.filterButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.semibold)
        self.filterButton.contentHorizontalAlignment = .left
        
        self.filterButton.addTarget(self, action: #selector(FiltersTableHeaderView.filterButtonTapped), for: .touchUpInside)
        
        self.addSubview(filterButton)
        
        let filterLeading = NSLayoutConstraint(item: self.filterButton,
                                               attribute: .leading,
                                               relatedBy: .equal,
                                               toItem: self,
                                               attribute: .leading,
                                               multiplier: 1,
                                               constant: 12)
        
        let filterTop = NSLayoutConstraint(item: self.filterButton,
                                               attribute: .top,
                                               relatedBy: .equal,
                                               toItem: self,
                                               attribute: .top,
                                               multiplier: 1,
                                               constant: 0)
        
        let filterHeight = NSLayoutConstraint(item: self.filterButton,
                                              attribute: .height,
                                              relatedBy: .equal,
                                              toItem: nil,
                                              attribute: .notAnAttribute,
                                              multiplier: 1,
                                              constant: 44)
        
        let filterWidth = NSLayoutConstraint(item: self.filterButton,
                                              attribute: .width,
                                              relatedBy: .equal,
                                              toItem: nil,
                                              attribute: .notAnAttribute,
                                              multiplier: 1,
                                              constant: 140)
        
        self.sortingButton.setTitle(sortingTitle, for: .normal)
        self.sortingButton.setTitleColor(titleColor, for: .normal)
        self.sortingButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        self.sortingButton.contentHorizontalAlignment = .right
        
        self.sortingButton.addTarget(self, action: #selector(FiltersTableHeaderView.sortingButtonTapped), for: .touchUpInside)
        
        
        let sortingLeading = NSLayoutConstraint(item: self,
                                               attribute: .trailing,
                                               relatedBy: .equal,
                                               toItem: self.sortingButton,
                                               attribute: .trailing,
                                               multiplier: 1,
                                               constant: 12)
        
        let sortingTop = NSLayoutConstraint(item: self.sortingButton,
                                           attribute: .top,
                                           relatedBy: .equal,
                                           toItem: self,
                                           attribute: .top,
                                           multiplier: 1,
                                           constant: 0)
        
        let sortingHeight = NSLayoutConstraint(item: self.sortingButton,
                                              attribute: .height,
                                              relatedBy: .equal,
                                              toItem: nil,
                                              attribute: .notAnAttribute,
                                              multiplier: 1,
                                              constant: 44)
        
        let sortingWidth = NSLayoutConstraint(item: self.sortingButton,
                                             attribute: .width,
                                             relatedBy: .equal,
                                             toItem: nil,
                                             attribute: .notAnAttribute,
                                             multiplier: 1,
                                             constant: 140)
        
        self.addSubview(self.sortingButton)
        
        self.topBorder.backgroundColor = borderColor
        
        let topBorderLeading = NSLayoutConstraint(item: self.topBorder,
                                                attribute: .leading,
                                                relatedBy: .equal,
                                                toItem: self,
                                                attribute: .leading,
                                                multiplier: 1,
                                                constant: 0)
        
        let topBorderTop = NSLayoutConstraint(item: self.topBorder,
                                            attribute: .top,
                                            relatedBy: .equal,
                                            toItem: self,
                                            attribute: .top,
                                            multiplier: 1,
                                            constant: 0)
        
        let topBorderTrailing = NSLayoutConstraint(item: self.topBorder,
                                              attribute: .trailing,
                                              relatedBy: .equal,
                                              toItem: self,
                                              attribute: .trailing,
                                              multiplier: 1,
                                              constant: 0)
        
        let topBorderHeight = NSLayoutConstraint(item: self.topBorder,
                                               attribute: .height,
                                               relatedBy: .equal,
                                               toItem: nil,
                                               attribute: .notAnAttribute,
                                               multiplier: 1,
                                               constant: 0.5)
        
        self.addSubview(self.topBorder)
        
        self.bottomBorder.backgroundColor = borderColor
        
        let bottomBorderLeading = NSLayoutConstraint(item: self.bottomBorder,
                                                  attribute: .leading,
                                                  relatedBy: .equal,
                                                  toItem: self,
                                                  attribute: .leading,
                                                  multiplier: 1,
                                                  constant: 0)
        
        let bottomBorderBottom = NSLayoutConstraint(item: self,
                                              attribute: .bottom,
                                              relatedBy: .equal,
                                              toItem: self.bottomBorder,
                                              attribute: .bottom,
                                              multiplier: 1,
                                              constant: 0)
        
        let bottomBorderTrailing = NSLayoutConstraint(item: self.bottomBorder,
                                                   attribute: .trailing,
                                                   relatedBy: .equal,
                                                   toItem: self,
                                                   attribute: .trailing,
                                                   multiplier: 1,
                                                   constant: 0)
        
        let bottomBorderHeight = NSLayoutConstraint(item: self.bottomBorder,
                                                 attribute: .height,
                                                 relatedBy: .equal,
                                                 toItem: nil,
                                                 attribute: .notAnAttribute,
                                                 multiplier: 1,
                                                 constant: 0.5)
        
        self.addSubview(self.bottomBorder)
        
        self.addConstraints([filterLeading, filterTop, filterHeight, filterWidth, sortingLeading, sortingTop, sortingHeight, sortingWidth, topBorderLeading, topBorderTop, topBorderTrailing, topBorderHeight, bottomBorderLeading, bottomBorderBottom, bottomBorderTrailing, bottomBorderHeight])
        
    }
    
    func showSortByMenu(vc: Any) {
        let alert = UIAlertController(title: "Sort By", message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: SortByOptions.top.text, style: .default, handler: { action in
            self.delegate?.sortByTop()
        }))
        
        alert.addAction(UIAlertAction(title: SortByOptions.recent.text, style: .default, handler: { action in
            self.delegate?.sortByRecent()
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        if let vc = vc as? UIViewController {
            vc.present(alert, animated: true, completion: nil)
        }
    }
    
    func showSortByTimeRangeMenu(vc: Any) {
        
        let alert = UIAlertController(title: "Time Range", message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: SortingTimeRange.day.text, style: .default, handler: { action in
            self.sortByTopWithTimeRange(timeRange: .day)
        }))
        
        alert.addAction(UIAlertAction(title: SortingTimeRange.week.text, style: .default, handler: { action in
            self.sortByTopWithTimeRange(timeRange: .week)
        }))
        
        alert.addAction(UIAlertAction(title: SortingTimeRange.month.text, style: .default, handler: { action in
            self.sortByTopWithTimeRange(timeRange: .month)
        }))
        
        alert.addAction(UIAlertAction(title: SortingTimeRange.year.text, style: .default, handler: { action in
            self.sortByTopWithTimeRange(timeRange: .year)
        }))
        
        alert.addAction(UIAlertAction(title: SortingTimeRange.allTime.text, style: .default, handler: { action in
            self.sortByTopWithTimeRange(timeRange: .allTime)
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        if let vc = vc as? UIViewController {
            vc.present(alert, animated: true, completion: nil)
        }
        
    }
    
    func sortByRecent() {
        self.delegate?.sortByRecent()
    }
    
    func sortByTop() {
        self.delegate?.sortByTop()
    }
    
    func sortByTopWithTimeRange(timeRange: SortingTimeRange) {
        self.delegate?.sortByTopWithTimeRange(timeRange: timeRange)
    }
    
    @objc func filterButtonTapped() {
        self.delegate?.filterButtonTapped()
    }
    
    @objc func sortingButtonTapped() {
        self.delegate?.sortingButtonTapped()
    }
}
