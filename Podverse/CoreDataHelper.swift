//
//  CoreDataHelper.swift
//  Podverse
//
//  Created by Creon on 12/24/16.
//  Copyright © 2016 Podverse LLC. All rights reserved.
//

import Foundation
import UIKit
import CoreData

enum ThreadType {
    case privateThread
    case mainThread
}

class CoreDataHelper {
    let storeName = "podverse"
    let storeFilename = "podverse.sqlite"
    
    static let shared = CoreDataHelper()
    var managedObjectModel: NSManagedObjectModel!
    var persistentStoreCoordinator: NSPersistentStoreCoordinator!
    
    var applicationDocumentsDirectory:URL {
        get {
            // The directory the application uses to store the Core Data store file. 
            let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            return urls[urls.count-1]
        }
    }
    
    init() {
        let modelURL = Bundle.main.url(forResource: self.storeName, withExtension: "momd")!
        self.managedObjectModel = NSManagedObjectModel(contentsOf: modelURL)!
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.appendingPathComponent(self.storeName)
        let failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: nil)
        } catch {
            // Report any error we got.
            var dict = [String: Any]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            
            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: ErrorDomain, code: CoreDataFailureCode, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. 
            //You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
        
        persistentStoreCoordinator = coordinator
    }
    
    fileprivate lazy var privateManagedObjectContext: NSManagedObjectContext = {
        // Initialize Managed Object Context
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        
        // Configure Managed Object Context
        managedObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator
        
        return managedObjectContext
    }()
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        // Initialize Managed Object Context
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        
        // Configure Managed Object Context
        managedObjectContext.parent = self.privateManagedObjectContext
        
        return managedObjectContext
    }()
    
    func save(_ completion:(()->())?) {
        managedObjectContext.performAndWait({
            do {
                try self.managedObjectContext.save()
                
            } catch {
                let saveError = error as NSError
                print("Unable to Save Changes of Managed Object Context")
                print("\(saveError), \(saveError.localizedDescription)")
            }
            
            self.privateManagedObjectContext.perform({
                do {
                    try self.privateManagedObjectContext.save()
                    completion?()
                } catch {
                    let saveError = error as NSError
                    print("Unable to Save Changes of Private Managed Object Context")
                    print("\(saveError), \(saveError.localizedDescription)")
                }
            })
        })
        
        
    }
    
    static func insertManagedObject(className: String, moc:NSManagedObjectContext? = nil) -> NSManagedObjectID {
        var localMoc = moc
        if localMoc == nil {
            localMoc = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
            localMoc?.parent = CoreDataHelper.shared.managedObjectContext
        }
        
        if let entityDescription = NSEntityDescription.entity(forEntityName: className, in: localMoc!) {
            // Create Managed Object
            return NSManagedObject(entity: entityDescription, insertInto: localMoc).objectID
        }
        
        return NSManagedObjectID()
    }
    
    static func fetchEntities(className: String, predicate: NSPredicate?, moc:NSManagedObjectContext?) -> [NSManagedObject] {
        if let moc = moc {
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: className)
            let entityDescription = NSEntityDescription.entity(forEntityName: className as String, in: moc)
            
            fetchRequest.entity = entityDescription
            fetchRequest.predicate = predicate
            fetchRequest.returnsObjectsAsFaults = false
            
            do {
                return try moc.fetch(fetchRequest)
            } catch {
                print(error.localizedDescription)
            }
        }
        
        return []
    }
    
    static func fetchEntityWithMostRecentPubDate(className: String, predicate: NSPredicate?, moc:NSManagedObjectContext?) -> NSManagedObject? {
        if let moc = moc {
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: className)
            let entityDescription = NSEntityDescription.entity(forEntityName: className as String, in: moc)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "pubDate", ascending: false)]
            fetchRequest.fetchLimit = 1
            
            fetchRequest.entity = entityDescription
            fetchRequest.predicate = predicate
            fetchRequest.returnsObjectsAsFaults = false
            
            do {
                return try moc.fetch(fetchRequest).first
            } catch {
                print(error.localizedDescription)
            }
        }
        
        return nil
    }
    
    static func fetchEntityWithID(objectId:NSManagedObjectID, moc:NSManagedObjectContext) -> NSManagedObject? {
        do {
            return try moc.existingObject(with: objectId)
        } catch {
            print(error.localizedDescription)
        }
        
        return nil
    }
    
    static func deleteItemFromCoreData(deleteObjectID:NSManagedObjectID, moc: NSManagedObjectContext) {
        let deleteObject = CoreDataHelper.fetchEntityWithID(objectId: deleteObjectID, moc: moc)
        
        if let deleteObject = deleteObject {
            moc.delete(deleteObject)
        }
    }

    static func retrieveExistingOrCreateNewPodcast(feedUrlString: String, moc:NSManagedObjectContext) -> Podcast {
        let predicate = NSPredicate(format: "feedUrl == %@", feedUrlString)
        let podcastSet = CoreDataHelper.fetchEntities(className: "Podcast", predicate: predicate, moc:moc) as! [Podcast]
        if podcastSet.count > 0 {
            return podcastSet[0]
        } else {
            let oid = CoreDataHelper.insertManagedObject(className: "Podcast", moc: moc)
            return CoreDataHelper.fetchEntityWithID(objectId: oid, moc: moc) as! Podcast
        }
    }
    
    static func retrieveExistingOrCreateNewEpisode(mediaUrlString: String, moc:NSManagedObjectContext) -> Episode {
        let predicate = NSPredicate(format: "mediaUrl == %@", mediaUrlString)
        let episodeSet = CoreDataHelper.fetchEntities(className: "Episode", predicate: predicate, moc:moc) as! [Episode]
        if episodeSet.count > 0 {
            return episodeSet[0]
        } else {
            let oid = CoreDataHelper.insertManagedObject(className: "Episode")
            return CoreDataHelper.fetchEntityWithID(objectId: oid, moc: moc) as! Episode
        }
    }
    
    static func createMOCForThread(threadType:ThreadType) -> NSManagedObjectContext {
        let concurrencyType:NSManagedObjectContextConcurrencyType = threadType == .privateThread ? .privateQueueConcurrencyType : .mainQueueConcurrencyType
        
        let moc = NSManagedObjectContext(concurrencyType: concurrencyType)
        let parent = CoreDataHelper.shared.managedObjectContext
        moc.parent = parent
        moc.refreshObjects()
        
        return moc
    }
    
    static func clearOrphanedEpisodes() {
        let moc = createMOCForThread(threadType: .privateThread)
        let predicate = NSPredicate(format: "podcast == nil")
        let episodeSet = CoreDataHelper.fetchEntities(className: "Episode", predicate: predicate, moc:moc) as! [Episode]
        for episode in episodeSet {
            PVDeleter.deleteEpisode(mediaUrl: episode.mediaUrl, moc: moc)
        }
    }
}

extension NSManagedObjectContext {
    func saveData(_ completion:(()->())?) {
        do {
            try self.save()
            CoreDataHelper.shared.save(completion)
        }
        catch {
           print("Could not save current context: ", error.localizedDescription) 
        }
    }
    
    func refreshObjects() {
        self.parent?.refreshAllObjects()
        self.refreshAllObjects()
    }
}
