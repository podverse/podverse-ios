//
//  PVAuth.swift
//  Podverse
//
//  Created by Creon on 12/27/16.
//  Copyright © 2016 Podverse LLC. All rights reserved.
//

import Lock
import Auth0
import CoreData

extension Notification.Name {
    static let loggedInSuccessfully = Notification.Name(kLoggedInSuccessfully)
    static let loggedOutSuccessfully = Notification.Name(kLoggedOutSuccessfully)
    static let loggingIn = Notification.Name(kLoggingIn)
    static let loginFailed = Notification.Name(kLoginFailed)
}

class PVAuth: NSObject {
    
    static let shared = PVAuth()
    
    static var userIsLoggedIn:Bool {
        return UserDefaults.standard.value(forKey: "idToken") != nil
    }

    func showAuth0Lock (vc: UIViewController) {

        Lock
            .classic()
            .withOptions{
                $0.closable = true
                $0.oidcConformant = false
                $0.customSignupFields = [
                    CustomTextField(name: "Name", placeholder: "Nickname")
                ]
                $0.usernameStyle = [.Email]
            }
            .withStyle {
                $0.title = "Podverse"
                $0.headerColor = UIColor(red: 0.15, green: 0.41, blue: 0.70, alpha: 1.0)
                $0.primaryColor = UIColor(red: 0.15, green: 0.41, blue: 0.70, alpha: 1.0)
                $0.titleColor = UIColor.white
            }
            .onAuth {
                
                self.notifyLoggingIn()
                
                guard let accessToken = $0.accessToken, let idToken = $0.idToken else {
                    return
                }
                
                Auth0
                    .authentication()
                    .userInfo(withAccessToken: accessToken)
                    .start { result in
                        switch result {
                        // Attempt to access the user profile object
                        case .success(let profile):
                            
                            self.findOrCreateUserOnServer(profile: profile, idToken: idToken) { wasSuccessful in
                                if (!wasSuccessful) {
                                    self.handleLoginFailure(profile: profile, idToken: idToken, vc: vc)
                                } else {
                                    self.populateUserInfoWith(idToken: idToken, userId: profile.sub, userName: profile.nickname)
                                    self.notifyLoggedInSuccessfully()
                                }
                            }
                            
                        case .failure(let error):
                            // Is there something we need to handle when it fails to access the user profile object? We should have a valid idToken already, so I can't think of anything.
                            print(error.localizedDescription)
                        }
                    }
                
            }
            .onError {
                print("Failed with \($0)")
                self.handleLoginFailure(profile: nil, idToken: nil, vc: vc)
            }
            .present(from: vc)
    }
    
    func findOrCreateUserOnServer(profile:UserInfo?, idToken:String, completion:@escaping(_ wasSuccessful:Bool) -> Void) {
        
        if let url = URL(string: BASE_URL + "users/"), let profile = profile {
            
            var request = URLRequest(url: url, cachePolicy: NSURLRequest.CachePolicy.reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 30)
            request.httpMethod = "POST"
            
            request.setValue(idToken, forHTTPHeaderField: "Authorization")

            var postString = ""

            if let name = profile.name {
                postString += "name=" + name
            }
            
            if let nickname = profile.nickname {
                postString += "&nickname=" + nickname
            }

            request.httpBody = postString.data(using: .utf8)

            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                
                guard error == nil else {
                    self.notifyLoginFailed()
                    DispatchQueue.main.async {
                        completion(false)
                    }
                    return
                }

                completion(true)

            }
            
            task.resume()
            
        } else {
            self.notifyLoginFailed()
            DispatchQueue.main.async {
                completion(false)
            }
        }
        
    }
    
    func syncUserInfoWithServer () {
        if let idToken = UserDefaults.standard.string(forKey: "idToken"), let userId = UserDefaults.standard.string(forKey: "userId") {
            Auth0
                .users(token: idToken)
                .get(userId, fields: ["nickname"], include: true)
                .start { result in
                    switch result {
                    case .success(let user):
                        let nickname = user["nickname"] as? String
                        self.populateUserInfoWith(idToken: idToken, userId: userId, userName: nickname)
                    case .failure(let error):
                        print(error.localizedDescription)
                    }
                }
            
        }
    }
    
    func populateUserInfoWith(idToken: String, userId: String?, userName: String?) {
        UserDefaults.standard.set(idToken, forKey: "idToken")
        
        if let userId = userId {
            UserDefaults.standard.set(userId, forKey: "userId")
        }

        if let userName = userName {
            UserDefaults.standard.set(userName, forKey: "userName")
        }
    }
    
    func removeUserInfo() {
        UserDefaults.standard.set(nil, forKey: "idToken")
        UserDefaults.standard.set(nil, forKey: "userId")
        UserDefaults.standard.set(nil, forKey: "userName")
        DispatchQueue.main.async {
            NotificationCenter.default.post(name:NSNotification.Name(rawValue: kLoggedOutSuccessfully), object: self, userInfo: nil)
        }
    }
    
    fileprivate func notifyLoggedInSuccessfully() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name:NSNotification.Name(rawValue: kLoggedInSuccessfully), object: self, userInfo: nil)
        }
    }
    
    fileprivate func notifyLoggingIn() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name:NSNotification.Name(rawValue: kLoggingIn), object: self, userInfo: nil)
        }
    }
    
    fileprivate func notifyLoginFailed() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name:NSNotification.Name(rawValue: kLoginFailed), object: self, userInfo: nil)
        }
    }
    
    func handleLoginFailure(profile:UserInfo?, idToken:String?, vc:UIViewController) {
        removeUserInfo()
        notifyLoginFailed()
        
        DispatchQueue.main.async {
            
            if let profile = profile, let idToken = idToken {
                let actions = UIAlertController(title: "Login Failed", message: "Please check your internet connection and try again.", preferredStyle: .alert)
                
                actions.addAction(UIAlertAction(title: "Retry", style: .default, handler: { action in
                    self.notifyLoggingIn()
                    self.findOrCreateUserOnServer(profile: profile, idToken: idToken) { wasSuccessful in
                        if (!wasSuccessful) {
                            self.handleLoginFailure(profile: profile, idToken: idToken, vc: vc)
                        } else {
                            self.populateUserInfoWith(idToken: idToken, userId: profile.sub, userName: profile.nickname)
                            
                            self.notifyLoggedInSuccessfully()
                        }
                    }
                }))
                
                actions.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                
                vc.present(actions, animated: true, completion: nil)
            } else {
                let actions = UIAlertController(title: "Login Failed", message: "Please check your internet connection and try again.", preferredStyle: .alert)
                actions.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                vc.present(actions, animated: true, completion: nil)
            }
            
            
        }
    }
    
    
    
}
