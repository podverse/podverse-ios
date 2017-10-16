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

protocol PVAuthDelegate {
    func loggedInSuccessfully()
}

class PVAuth: NSObject {
    
    static let shared = PVAuth()
    
    var delegate:PVAuthDelegate?
    
    static var userIsLoggedIn:Bool {
        return UserDefaults.standard.value(forKey: "idToken") != nil
    }

    func showAuth0Lock (vc: UIViewController, completion:(() -> ())?) {

        Lock
            .classic()
            .withOptions{
                $0.closable = true
                $0.oidcConformant = false
                $0.customSignupFields = [
                    CustomTextField(name: "Name", placeholder: "your name (optional)")
                ]
                $0.usernameStyle = [.Email]
            }
            .withStyle {
                $0.title = "Podverse Login"
                $0.primaryColor = UIColor(red: 0.15, green: 0.41, blue: 0.70, alpha: 1.0)
                $0.hideTitle = true
            }
            .onAuth {
                
                DispatchQueue.main.async {
                    vc.dismiss(animated: true, completion: nil)
                }
                
                guard let accessToken = $0.accessToken, let idToken = $0.idToken else {
                    return
                }
                
                Auth0
                    .authentication()
                    .userInfo(withAccessToken: accessToken)
                    .start { result in
                        switch result {
                        case .success(let profile):
                            self.populateUserInfoWith(idToken: idToken, userId: profile.sub, userName: profile.nickname)
                        case .failure(let error):
                            self.populateUserInfoWith(idToken: idToken, userId: nil, userName: nil)
                            print(error.localizedDescription)
                        }
                        
                        completion?()

                    }
                
            }
            .onError {
                print("Failed with \($0)")
            }
            .present(from: vc)
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
        
        self.delegate?.loggedInSuccessfully()
    }
    
    func removeUserInfo() {
        UserDefaults.standard.set(nil, forKey: "idToken")
        UserDefaults.standard.set(nil, forKey: "userId")
        UserDefaults.standard.set(nil, forKey: "userName")
    }
}
