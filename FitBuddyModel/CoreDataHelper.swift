//
//  CoreDataHelper2.swift
//  FitBuddy
//
//  Created by john.neyer on 5/9/15.
//  Copyright (c) 2015 jneyer.com. All rights reserved.
//

import Foundation
import FitBuddyCommon
import CoreData

public class CoreDataHelper: NSObject {
    
    override
    public init() {
        
    }
    
    //Return the current data state based on the icloud flag and present data
    public static func coreDataState (coredataconnection : CoreDataConnection) -> CoreDataType {
        
        if FitBuddyUtils.isCloudOn() {
            return CoreDataType.ICLOUD
        }
        else {
            
            if NSFileManager.defaultManager().fileExistsAtPath(coreDataGroupURL().path!) {
                return CoreDataType.GROUP
            }
            else if NSFileManager.defaultManager().fileExistsAtPath(coreDataLocalURL().path!) {
                return CoreDataType.LOCAL
            }
            
        }
        
        return CoreDataType.NEW
    }
    
    //Return the docs URL for the group container
    public static func groupDocsURL () -> NSURL {
        return NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier(FBConstants.kGROUPPATH)!
    }
    
    //Return the URL for the group contaner sqlite database
    public static func coreDataGroupURL () -> NSURL {
        return groupDocsURL().URLByAppendingPathComponent("Database").URLByAppendingPathComponent(FBConstants.kDATABASE2_0)
    }
    
    //Return the docs URL for the local container
    public static func localDocsURL () -> NSURL {
        return NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0] 
    }
    
    //Return the URL for the local documents directory sqlite database
    public static func coreDataLocalURL () -> NSURL {
        return localDocsURL().URLByAppendingPathComponent("Database").URLByAppendingPathComponent(FBConstants.kDATABASE2_0)
    }
    
    public static func ubiquityDocsURL () -> NSURL? {
        if let url = NSFileManager.defaultManager().URLForUbiquityContainerIdentifier(FBConstants.kUBIQUITYCONTAINER) {
            return url
        }
        return nil
    }
    
    public static func coreDataUbiquityURL () -> NSURL? {
        let token = NSFileManager.defaultManager().ubiquityIdentityToken
        let url = NSFileManager.defaultManager().URLForUbiquityContainerIdentifier(nil)
        
        if token != nil || url != nil {
            return groupDocsURL().URLByAppendingPathComponent("Database").URLByAppendingPathComponent(FBConstants.kDATABASE2_0REMOTE)
        }
        return nil
    }
    
    public static func migrateDataStore (sourceSqliteStore: NSURL, sourceStoreType: CoreDataType, destSqliteStore: NSURL, destStoreType: CoreDataType) {
        
        migrateDataStore(sourceSqliteStore, sourceStoreType: sourceStoreType, destSqliteStore: destSqliteStore, destStoreType: destStoreType, delete: true)
    }
    
    //Migrate a local data store to new location
    public static func migrateDataStore (sourceSqliteStore: NSURL, sourceStoreType: CoreDataType, destSqliteStore: NSURL, destStoreType: CoreDataType, delete: Bool) {
        
        let storeURL = destSqliteStore
        let seedStoreURL = sourceSqliteStore
        
        // create a new coordinator
        let coord = NSPersistentStoreCoordinator(managedObjectModel: CoreDataConnection.defaultConnection.managedObjectModel)
        
        var error: NSError? = nil
        
        var seedStoreOptions = CoreDataConnection.defaultConnection.defaultStoreOptions(sourceStoreType == CoreDataType.ICLOUD)!
        seedStoreOptions[NSReadOnlyPersistentStoreOption] = true

        let seedStore: NSPersistentStore?
        do {
            seedStore = try coord.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: seedStoreURL, options: seedStoreOptions)
        } catch let error1 as NSError {
            error = error1
            seedStore = nil
        }
        
        let newStoreOptions = CoreDataConnection.defaultConnection.defaultStoreOptions((destStoreType == CoreDataType.ICLOUD))
        
        let queue = NSOperationQueue()
        
        queue.addOperationWithBlock({
            
            var blockError: NSError? = nil
            
            do {
                try coord.migratePersistentStore(seedStore!, toURL: storeURL, options: newStoreOptions, withType: NSSQLiteStoreType)
            } catch let error as NSError {
                blockError = error
            } catch {
                fatalError()
            }
            
            if blockError != nil {
                NSLog("An error occured while migrating the persistent store %@", error!)
            }
            
            
            let mainQueue = NSOperationQueue()
            mainQueue.addOperationWithBlock({
                //This will be called when the migration is done
                if destStoreType == CoreDataType.GROUP {
                    if delete {
                        do {
                            try NSFileManager.defaultManager().removeItemAtPath(seedStoreURL.path!)
                        } catch let error1 as NSError {
                            error = error1
                        } catch {
                            fatalError()
                        }
                    }
                }
                
                FitBuddyUtils.setCloudOn(destStoreType == CoreDataType.ICLOUD)
                FitBuddyUtils.saveDefaults()
            })
        })
        
        if error != nil {
            NSLog("An error occured during migration %@", error!)
        }
        
    }
    
    public static func migrateiCloudStoreToGroupStore () {
        
        //The iCloud store
        let cloudStore: NSPersistentStore = CoreDataConnection.defaultConnection.persistentStoreCoordinator.persistentStores.first! as NSPersistentStore
        var groupStoreOptions = CoreDataConnection.defaultConnection.defaultStoreOptions(false)!
        groupStoreOptions[NSPersistentStoreRemoveUbiquitousMetadataOption] = true
        let groupStore = CoreDataHelper.coreDataGroupURL()
        
        var error : NSError? = nil

        do {
            try CoreDataConnection.defaultConnection.persistentStoreCoordinator.migratePersistentStore(cloudStore, toURL: groupStore, options: groupStoreOptions, withType: NSSQLiteStoreType)
        } catch let error1 as NSError {
            error = error1
        }
        
        if error != nil {
            NSLog("An error occured while migrating iCloud data %@", error!)
        }
        else {
            FitBuddyUtils.setCloudOn(false)
            FitBuddyUtils.saveDefaults()
        }
    }
}