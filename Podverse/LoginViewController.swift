//
//  LoginViewController.swift
//  Podverse
//
//  Created by Creon on 12/29/16.
//  Copyright © 2016 Podverse LLC. All rights reserved.
//

import UIKit
import Lock

class LoginViewController: PVViewController {
    
    let pvAuth = PVAuth.shared
    
    @IBOutlet weak var textView: UITextView!
    
    @IBAction func login(_ sender: Any) {
        pvAuth.showAuth0Lock(vc: self)
    }
    
    @IBAction func cancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
}
