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


class PVAuth: NSObject {
    
    static let shared = PVAuth()
    
    func showAuth0LockLoginVC (vc: UIViewController) {
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
            }
            .onAuth {
                
                vc.dismiss(animated: true, completion: nil)
                
                guard let accessToken = $0.accessToken, let idToken = $0.idToken else {
                    return
                }
                
                Auth0
                    .authentication()
                    .userInfo(withAccessToken: accessToken)
                    .start { result in
                        switch result {
                        case .success(let profile):
                            self.setUserInfo(idToken: idToken, userName: profile.nickname)
                        case .failure(let error):
                            self.setUserInfo(idToken: idToken, userName: nil)
                            print(error)
                        }
                    }
            }
            .onError {
                print("Failed with \($0)")
            }
            .present(from: vc)
    }
    
    func setUserInfo(idToken: String, userName: String?) {
        UserDefaults.standard.set(idToken, forKey: "idToken")

        if let userName = userName {
            UserDefaults.standard.set(userName, forKey: "userName")
        }
    }

}
