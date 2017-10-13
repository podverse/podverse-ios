//
//  UITableView+NotAvailableView.swift
//  Podverse
//
//  Created by Creon Creonopoulos on 9/19/17.
//  Copyright © 2017 Podverse LLC. All rights reserved.
//

import UIKit

extension UIViewController {
    
    func showNoDataView() {
        let noDataView = self.view.viewWithTag(kNoDataViewTag)
        noDataView?.isHidden = false
    }
    
    func hideNoDataView() {
        let noDataView = self.view.viewWithTag(kNoDataViewTag)
        noDataView?.isHidden = true
    }
    
    func addNoDataViewWithMessage(_ message:String, buttonTitle:String? = nil, buttonImage:UIImage? = nil, retryPressed:Selector? = nil) {
        let noDataView = UIView()
        let noDataTextLabel = UILabel()
        let actionButton = UIButton()
        
        noDataView.translatesAutoresizingMaskIntoConstraints = false
        noDataView.backgroundColor = .white
        noDataView.tag = kNoDataViewTag
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        noDataTextLabel.translatesAutoresizingMaskIntoConstraints = false
        
        noDataTextLabel.text = message
        noDataTextLabel.numberOfLines = 5
        actionButton.setTitle(buttonTitle, for: .normal)
        actionButton.setTitleColor(.black, for: .normal)
        
        if let image = buttonImage {
            actionButton.setImage(image, for: .normal)
        }
        
        if let retryAction = retryPressed {
            actionButton.addTarget(self, action: retryAction, for: .touchUpInside)
        }
        
        self.view.addSubview(noDataView)
        
        let containerLeading = NSLayoutConstraint(  item:self.view,
                                                    attribute:.leading,
                                                    relatedBy:.equal,
                                                    toItem:noDataView,
                                                    attribute:.leading,
                                                    multiplier:1,
                                                    constant:0)
            
        let containerTrailing = NSLayoutConstraint(  item:self.view,
                                                     attribute:.trailing,
                                                     relatedBy:.equal,
                                                     toItem:noDataView,
                                                     attribute:.trailing,
                                                     multiplier:1,
                                                     constant:0)
        
        let containerTop = NSLayoutConstraint(  item:self.view,
                                                attribute:.top,
                                                relatedBy:.equal,
                                                toItem:noDataView,
                                                attribute:.top,
                                                multiplier:1,
                                                constant:0)
        
        let containerBottom = NSLayoutConstraint(  item:self.view,
                                                   attribute:.bottom,
                                                   relatedBy:.equal,
                                                   toItem:noDataView,
                                                   attribute:.bottom,
                                                   multiplier:1,
                                                   constant:0)
        
        self.view.addConstraints([containerTop, containerBottom, containerLeading, containerTrailing])
        
        noDataView.addSubview(actionButton)
        noDataView.addSubview(noDataTextLabel)

        
        var allConstraints = [NSLayoutConstraint]()
        
        let buttonHorizontalConstraint = NSLayoutConstraint(  item:noDataView,
                                                              attribute:.centerY,
                                                              relatedBy:.equal,
                                                              toItem:actionButton,
                                                              attribute:.centerY,
                                                              multiplier:1,
                                                              constant:0)
        
        let buttonVerticalConstraint = NSLayoutConstraint(  item:noDataView,
                                                            attribute:.centerX,
                                                            relatedBy:.equal,
                                                            toItem:actionButton,
                                                            attribute:.centerX,
                                                            multiplier:1,
                                                            constant:0)
        
        let labelVerticalConstraint = NSLayoutConstraint(  item:actionButton,
                                                              attribute:.top,
                                                              relatedBy:.equal,
                                                              toItem:noDataTextLabel,
                                                              attribute:.bottom,
                                                              multiplier:1,
                                                              constant:20)
        
        let labelHorizontalConstraint = NSLayoutConstraint(  item:noDataView,
                                                            attribute:.centerX,
                                                            relatedBy:.equal,
                                                            toItem:noDataTextLabel,
                                                            attribute:.centerX,
                                                            multiplier:1,
                                                            constant:0)
        
        let labelWidthConstraint = NSLayoutConstraint(item: noDataTextLabel, attribute: .width, relatedBy: .lessThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 300)

        allConstraints.append(labelVerticalConstraint)
        allConstraints.append(labelHorizontalConstraint)
        allConstraints.append(labelWidthConstraint)
        allConstraints.append(buttonHorizontalConstraint)
        allConstraints.append(buttonVerticalConstraint)

        noDataView.addConstraints(allConstraints) 
        
        self.view.sendSubview(toBack: noDataView)
    }
}

