//
//  PVAuth.swift
//  Podverse
//
//  Created by Creon on 12/27/16.
//  Copyright © 2016 Podverse LLC. All rights reserved.
//

import Lock
import CoreData

protocol PVAuthDelegate {
    func authFinished()
}

class PVAuth: NSObject {
    
    var delegate:PVAuthDelegate?
    static let sharedInstance = PVAuth()
    
    func loginAsAnon () {
        
        // user must be signed out to login as anon
        if let _ = UserDefaults.standard.string(forKey: "idToken"), let _ = UserDefaults.standard.string(forKey: "userId") {
            return
        }
    }
    
    func showAuth0LockLoginVC (vc: UIViewController) {
        let lock = A0Lock.shared()
        let controller = lock.newLockViewController()
        controller?.closable = true
        
        controller?.onAuthenticationBlock = {(profile, token) in
            guard let idToken = token?.idToken else {
                return
            }
            
            guard let userId = profile?.userId else {
                return
            }
            
            self.updateOwnedItemsThenSwitchToNewUser(idToken: idToken, userId: userId, completionBlock: { () in
                controller?.dismiss(animated: true, completion: nil)
            })
            
        }
        
        controller?.onUserDismissBlock = {() in
            self.loginAsAnon()
            self.delegate?.authFinished()
        }
        
        lock.present(controller, from: vc, presentationStyle: .custom)
    }
    
    func showAuth0LockSignUpVC (vc: UIViewController) {
        let lock = A0Lock.shared()
        let controller = lock.newSignUpViewController()
        
        controller?.onAuthenticationBlock = {(profile, token) in
            guard let idToken = token?.idToken else {
                return
            }
            
            guard let userId = profile?.userId else {
                return
            }
            
            self.updateOwnedItemsThenSwitchToNewUser(idToken: idToken, userId: userId, completionBlock: { () in
                _ = vc.navigationController?.popToRootViewController(animated: true)
            })
        }
        
        vc.navigationController?.pushViewController(controller!, animated: true)
    }
    
    func updateOwnedItemsThenSwitchToNewUser (idToken: String, userId: String, completionBlock: (() -> ())?) {
        // If logging in on first app launch, then a prevUserId will not be defined. In that case there also shouldn't be any clips or playlists created locally yet.
        var ownedItemsPredString = ""
        if let prevUserId = UserDefaults.standard.string(forKey: "userId") {
            ownedItemsPredString = prevUserId
        }
        
        let ownedItemsPred = NSPredicate(format: "ownerId == %@", ownedItemsPredString)
        
        let moc = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        moc.parent = CoreDataHelper.shared.managedObjectContext
        
//        let ownedPlaylistsArray = CoreDataHelper.fetchEntities(className: "Playlist", predicate: ownedItemsPred, moc:moc) as! [Playlist]
//        let ownedClipsArray = CoreDataHelper.fetchEntities(className: "Clip", predicate: ownedItemsPred, moc:moc) as! [Clip]
        
        let dispatchGroup = DispatchGroup()
        
        // TODO: We should create a batch update endpoint in the web app so we don't have to send a request for each individual playlist and clip
//        for var playlist in ownedPlaylistsArray {
//            dispatchGroup.enter()
//            
//            playlist.ownerId = userId
//            
////            SavePlaylistToServer(playlist: playlist, newPlaylist:(playlist.id == nil), addMediaRefId: nil, completionBlock: { (response) -> Void in
////                
////                guard let dictResponse = response as? Dictionary<String,AnyObject> else {
////                    return
////                }
////                
////                playlist = PlaylistManager.sharedInstance.syncLocalPlaylistFieldsWithResponse(playlist, dictResponse: dictResponse)
////                
////                CoreDataHelper.saveCoreData(moc, completionBlock: { (saved) in
////                    dispatch_group_leave(dispatchGroup)
////                })
////            }) { (error) -> Void in
////                print("Not saved to server. Error: ", error?.localizedDescription)
////                CoreDataHelper.saveCoreData(moc, completionBlock: nil)
////                }.call()
//        }
//        
//        for clip in ownedClipsArray {
//            dispatchGroup.enter()
//            
//            clip.ownerId = userId
//            
////            SaveClipToServer(clip: clip, completionBlock: { (response) -> Void in
////                
////                guard let dictResponse = response as? Dictionary<String,AnyObject> else {
////                    return
////                }
////                
////                // TODO: this has a lot repeated code shared in PVClipperAddInfoController.swift
////                // Should be cleaned up!
////                if let mediaRefId = dictResponse["id"] as? String {
////                    clip.mediaRefId = mediaRefId
////                }
////                
////                if let podverseURL = dictResponse["podverseURL"] as? String {
////                    clip.podverseURL = podverseURL
////                }
////                
////                if let ownerId = dictResponse["ownerId"] as? String {
////                    clip.ownerId = ownerId
////                }
////                
////                if let ownerName = dictResponse["ownerName"] as? String {
////                    clip.ownerName = ownerName
////                }
////                
////                if let title = dictResponse["title"] as? String {
////                    clip.title = title
////                }
////                
////                if let startTime = dictResponse["startTime"] as? NSNumber {
////                    clip.startTime = startTime
////                }
////                
////                if let endTime = dictResponse["endTime"] as? NSNumber {
////                    clip.endTime = endTime
////                }
////                
////                if let dateCreated = dictResponse["dateCreated"] as? String {
////                    clip.dateCreated = PVUtility.formatStringToDate(dateCreated)
////                }
////                
////                if let lastUpdated = dictResponse["lastUpdated"] as? String {
////                    clip.lastUpdated = PVUtility.formatStringToDate(lastUpdated)
////                }
////                
////                if let serverEpisodeId = dictResponse["episodeId"] as? NSNumber {
////                    clip.serverEpisodeId = serverEpisodeId
////                }
////                
////                CoreDataHelper.saveCoreData(moc, completionBlock: { (saved) in
////                    dispatch_group_leave(dispatchGroup)
////                })
////            }) { (error) -> Void in
////                print("Not saved to server. Error: ", error?.localizedDescription)
////                CoreDataHelper.saveCoreData(moc, completionBlock: nil)
////                }.call()
//            
//        }
//        
//        if ownedPlaylistsArray.count < 1 && ownedClipsArray.count < 1 {
//            dispatchGroup.enter()
//            dispatchGroup.leave()
//        }
        
        dispatchGroup.notify(queue: DispatchQueue.main) {
            UserDefaults.standard.set(idToken, forKey: "idToken")
            UserDefaults.standard.set(userId, forKey: "userId")
//            TODO:
//            PlaylistManager.shared.getMyPlaylistsFromServer({
//                PlaylistManager.shared.createDefaultPlaylists()
//            })
//            
            self.delegate?.authFinished()
            if let cBlock = completionBlock {
                cBlock()
            }
        }
    }
    
    func setUserNameAndUpdateOwnedItems(userName: String?) {
        guard let idToken = UserDefaults.standard.string(forKey: "idToken") else {
            return
        }
        
        guard let userId = UserDefaults.standard.string(forKey: "userId") else {
            return
        }
        
        UserDefaults.standard.set(userName, forKey: "userName")

        self.updateOwnedItemsThenSwitchToNewUser(idToken: idToken, userId: userId, completionBlock: nil)
    }
    
    static func isAnonymousUser () -> Bool {
        if let userId = UserDefaults.standard.string(forKey: "userId"),  userId.contains("auth0|") {
            return true
        } else {
            return false
        }
    }
    
    static func validateEmail(enteredEmail:String) -> Bool {
        let emailFormat = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailFormat)
        return emailPredicate.evaluate(with:enteredEmail)
    }
}
