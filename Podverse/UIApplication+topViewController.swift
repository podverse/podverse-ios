//
//  UIApplication+topViewController.swift
//  Podverse
//
//  Created by Mitchell Downey on 7/18/17.
//  Copyright © 2017 Podverse LLC. All rights reserved.
//

import Foundation
import UIKit

extension UIApplication {
    // thanks dianz https://stackoverflow.com/a/30858591/2608858
    class func topViewController(controller: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let navigationController = controller as? UINavigationController, let visibleViewController = navigationController.visibleViewController {
            return topViewController(controller: visibleViewController)
        }
        if let tabController = controller as? UITabBarController {
            if let selected = tabController.selectedViewController {
                return topViewController(controller: selected)
            }
        }
        if let presented = controller?.presentedViewController {
            return topViewController(controller: presented)
        }
        return controller
    }
}
