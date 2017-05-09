//
//  LoginViewController.swift
//  Podverse
//
//  Created by Creon on 12/29/16.
//  Copyright © 2016 Podverse LLC. All rights reserved.
//

import UIKit
import Lock

protocol LoginModalDelegate:class {
    func loginTapped()
}

class LoginViewController: UIViewController {
    
    let reachability = PVReachability()
//    let playlistManager = PlaylistManager.sharedInstance
    weak var delegate:LoginModalDelegate?
    @IBOutlet weak var loginButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loginButton.layer.borderColor = UIColor.white.cgColor
        loginButton.layer.borderWidth = 1.0
    }
    
    @IBAction func login(sender: AnyObject) {
        self.dismiss(animated: false, completion: {
            self.delegate?.loginTapped()
        })
    }
    
    @IBAction func dismissView(sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
        PVAuth.sharedInstance.loginAsAnon()
    }
    
}
