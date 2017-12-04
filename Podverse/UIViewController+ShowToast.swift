//
//  UIViewController+ShowToast.swift
//  Podverse
//
//  Created by Mitchell Downey on 11/21/17.
//  Copyright © 2017 Podverse LLC. All rights reserved.
//

import UIKit

// Thanks to Mr. Bean https://stackoverflow.com/a/35130932/2608858
extension UIViewController {
    
    func showToast(message : String) {
        
        let toastLabel = UILabel(frame: CGRect(x: self.view.frame.size.width/2 - 90, y: self.view.frame.size.height/2 - 30, width: 180, height: 40))
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        toastLabel.textColor = UIColor.white
        toastLabel.textAlignment = .center;
        toastLabel.font = UIFont(name: "System", size: 16.0)
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 5;
        toastLabel.clipsToBounds  =  true
        self.view.addSubview(toastLabel)
        UIView.animate(withDuration: 3.0, delay: 0.1, options: .curveEaseOut, animations: {
            toastLabel.alpha = 0.0
        }, completion: {(isCompleted) in
            toastLabel.removeFromSuperview()
        })
        
    }
    
}
