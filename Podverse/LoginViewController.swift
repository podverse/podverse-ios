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
    
    @IBOutlet weak var loginToLabel: UILabel!
    @IBOutlet weak var loginToText: UITextView!
    @IBOutlet weak var noLoginNeededToLabel: UILabel!
    @IBOutlet weak var noLoginNeededToText: UITextView!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var noThanksButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var loggingInLabel: UILabel!
    
    @IBAction func login(_ sender: Any) {
        pvAuth.showAuth0Lock(vc: self)
    }
    
    @IBAction func cancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    fileprivate func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.loggingIn(_:)), name: .loggingIn, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.loggedInSuccessfully(_:)), name: .loggedInSuccessfully, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.loginFailed(_:)), name: .loginFailed, object: nil)
    }
    
    fileprivate func removeObservers() {
        NotificationCenter.default.removeObserver(self, name: .loggingIn, object: nil)
        NotificationCenter.default.removeObserver(self, name: .loggedInSuccessfully, object: nil)
        NotificationCenter.default.removeObserver(self, name: .loginFailed, object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addObservers()
        self.activityIndicator.hidesWhenStopped = true
        self.loggingInLabel.isHidden = true
    }
    
    deinit {
        removeObservers()
    }
    
}

extension LoginViewController {
    @objc func loggingIn(_ notification:Notification) {
        DispatchQueue.main.async {
            self.loginToLabel.isHidden = true
            self.loginToText.isHidden = true
            self.noLoginNeededToLabel.isHidden = true
            self.noLoginNeededToText.isHidden = true
            self.loginButton.isHidden = true
            self.noThanksButton.isHidden = true
            self.loggingInLabel.isHidden = false
            self.activityIndicator.startAnimating()
        }
    }

    @objc func loggedInSuccessfully(_ notification:Notification) {
        DispatchQueue.main.async {
            self.activityIndicator.stopAnimating()
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @objc func loginFailed(_ notification:Notification) {
        DispatchQueue.main.async {
            self.loginToLabel.isHidden = false
            self.loginToText.isHidden = false
            self.noLoginNeededToLabel.isHidden = false
            self.noLoginNeededToText.isHidden = false
            self.loginButton.isHidden = false
            self.noThanksButton.isHidden = false
            self.loggingInLabel.isHidden = true
            self.activityIndicator.stopAnimating()
        }
    }
}
