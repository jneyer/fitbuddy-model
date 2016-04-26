//
//  CoreDataConnection.swift
//  FitBuddy
//
//  Created by john.neyer on 5/5/15.
//  Copyright (c) 2015 jneyer.com. All rights reserved.
//

import Foundation
import CoreData
import FitBuddyCommon

@objc
public class CoreDataConnection : NSObject {
    
    //The default context
    static public let defaultConnection : CoreDataConnection = CoreDataConnection()
    
    override
    public init() {
        
    }
    
    public init(groupContext: Bool) {
        super.init()
        
        if groupContext {
            self.setGroupContext()
        }
    }
    
    lazy public var theLocalStore: NSURL = {
        return CoreDataHelper.coreDataLocalURL()
        }()
    
    
    lazy public var applicationDocumentsDirectory: NSURL = {
        return CoreDataHelper.localDocsURL()
        }()
    
    
    lazy public var managedObjectModel: NSManagedObjectModel = {
        return NSManagedObjectModel(contentsOfURL: NSBundle(identifier: "com.giantrobotlabs.FitBuddyModel")!.URLForResource("GymBuddyModel", withExtension: "momd")!)!
        }()
    
    lazy public var managedObjectContext: NSManagedObjectContext = {
        
        let managedObjectContext = NSManagedObjectContext.init(concurrencyType: NSManagedObjectContextConcurrencyType.MainQueueConcurrencyType)
        
        managedObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator
        managedObjectContext.mergePolicy = NSMergePolicy(mergeType: NSMergePolicyType.MergeByPropertyObjectTrumpMergePolicyType);
        
        return managedObjectContext
        }()

    
    lazy public var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
       
        let path = self.applicationDocumentsDirectory
        let dbDirURL = path.URLByAppendingPathComponent("Database")
        let storeURL = self.theLocalStore
        
        if (!NSFileManager.defaultManager().fileExistsAtPath(dbDirURL.path!))
        {
            var error: NSError? = nil
            do {
                try NSFileManager.defaultManager().createDirectoryAtURL(dbDirURL, withIntermediateDirectories: false, attributes: nil)
            } catch var error1 as NSError {
                error = error1
            } catch {
                fatalError()
            }
            
            if (error != nil)
            {
                NSLog("Unable to create directory for database: %@", error!)
            }
        }
        
        var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        
        var error: NSError? = nil
        var failureReason = "There was an error creating or loading the application's saved data."
        
        let options = self.defaultStoreOptions()
        
        do {
            try coordinator!.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: self.theLocalStore, options: options)
        } catch var error1 as NSError {
            error = error1
            
            coordinator = nil
            
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            dict[NSUnderlyingErrorKey] = error
            error = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(error), \(error!.userInfo)")
            abort()
        } catch {
            fatalError()
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CoreDataConnection.storeWillChangeHandler), name:  NSPersistentStoreCoordinatorStoresWillChangeNotification, object: nil);
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CoreDataConnection.storeDidChangeHandler) , name:  NSPersistentStoreCoordinatorStoresDidChangeNotification, object: nil);
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CoreDataConnection.storeDidImportHandler) , name:  NSPersistentStoreDidImportUbiquitousContentChangesNotification, object: nil);
        
        return coordinator!
        }()
    
    public func defaultStoreOptions () -> [NSObject: AnyObject]? {
        
        var icloudDefault = false
        if let sharedDefaults = NSUserDefaults(suiteName: FBConstants.kGROUPPATH) {
            icloudDefault = sharedDefaults.boolForKey(FBConstants.kUSEICLOUDKEY)
        }
    
        return defaultStoreOptions(icloudDefault)
    }
    
    public func defaultStoreOptions (foriCloud: Bool) -> [NSObject: AnyObject]? {
        
        if foriCloud {
            return [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true, NSPersistentStoreUbiquitousContentNameKey: "iCloudStore"]
        }
        
        return [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true]
    }
        
    //Set app directory and local store to the group container. 
    //This will move files if the group container hasn't been initialized.
    public func setGroupContext () -> Bool {
        
        if !(NSFileManager.defaultManager().fileExistsAtPath(CoreDataHelper.coreDataGroupURL().path!)) {
            
            let groupDBDir = CoreDataHelper.groupDocsURL().URLByAppendingPathComponent("Database")
            let appDBDir = CoreDataHelper.localDocsURL().URLByAppendingPathComponent("Database")
            
            moveFiles(appDBDir, toDir: groupDBDir)
        }
        else if NSFileManager.defaultManager().fileExistsAtPath(CoreDataHelper.coreDataLocalURL().path!) {
            
            let groupDBPath = CoreDataHelper.coreDataGroupURL()
            let appDBPath = CoreDataHelper.coreDataLocalURL()
            
            CoreDataHelper.migrateDataStore(appDBPath, sourceStoreType: CoreDataType.LOCAL, destSqliteStore: groupDBPath, destStoreType: CoreDataType.GROUP)
        }
        
        self.applicationDocumentsDirectory = CoreDataHelper.groupDocsURL()
        self.theLocalStore = CoreDataHelper.coreDataGroupURL()
    
        NSLog("Set up group context")
        
        return true
    }

    public func setUbiquityContext () -> Bool {
        
        if FitBuddyUtils.isCloudOn() == (CoreDataHelper.coreDataUbiquityURL() != nil) {
            //This is good. Cloud settings are in sync
            
            if FitBuddyUtils.isCloudOn() {
                //Need to set doc locations to device for sync
                self.applicationDocumentsDirectory = CoreDataHelper.groupDocsURL()
                self.theLocalStore = CoreDataHelper.coreDataUbiquityURL()!
                
                FitBuddyUtils.setDefault(FBConstants.kUBIQUITYURLKEY, value: CoreDataHelper.coreDataUbiquityURL()!.path!)
                FitBuddyUtils.saveDefaults()
            }
        }
        else if FitBuddyUtils.isCloudOn() && (CoreDataHelper.coreDataUbiquityURL() == nil) {
            
            //This means iCloud was turned off. Need to rebuild the database and remove ubiquity keys
            NSLog("iCloud turned off. Trying to migrate database to group container.")
            
            let uurl = FitBuddyUtils.getDefault(FBConstants.kUBIQUITYURLKEY)
            
            CoreDataHelper.migrateDataStore(NSURL(string: uurl!)!, sourceStoreType: CoreDataType.ICLOUD, destSqliteStore: CoreDataHelper.coreDataGroupURL(), destStoreType: CoreDataType.GROUP, delete:false)
            
            FitBuddyUtils.setCloudOn(false)
        }
        else if CoreDataHelper.coreDataUbiquityURL() != nil && !FitBuddyUtils.isCloudOn() {
            
            //This means iCloud was turned on.
            NSLog("iCloud was turned on but we're leaving data in the group.")
            
        }

        return true
    }
    
    func moveFiles(fromDir: NSURL, toDir: NSURL) {
        
        var error: NSError? = nil
        
        //Make sure the local exists for copy
        if !NSFileManager.defaultManager().fileExistsAtPath(toDir.path!) {
            do {
                try NSFileManager.defaultManager().createDirectoryAtPath(toDir.path!, withIntermediateDirectories: true, attributes: nil)
            } catch let error1 as NSError {
                error = error1
            }
        }
        
        let directoryEnumerator = NSFileManager.defaultManager().enumeratorAtPath(fromDir.path!)
        
        while let file = directoryEnumerator?.nextObject() as? String {
                
                let fileUrl = NSURL(fileURLWithPath: file)
                
                do {
                    try NSFileManager.defaultManager().copyItemAtPath(fromDir.URLByAppendingPathComponent(file).path!, toPath: toDir.URLByAppendingPathComponent(fileUrl.lastPathComponent!).path!)
                } catch let error1 as NSError {
                    error = error1
                }
                
                do {
                    try NSFileManager.defaultManager().removeItemAtPath(fromDir.URLByAppendingPathComponent(file).path!)
                } catch let error1 as NSError {
                    error = error1
                }
        }
        
        if error != nil {
            NSLog("Unable to move database to app container: %@", error!)
        }
    }
    
/////
//
// Change handlers for the UbiquityStoreManager
//
    public func storeWillChangeHandler() {
        
        
        if (FBConstants.DEBUG) {
            NSLog("Saving context prior to change.")
        }
        
        var error: NSError? = nil
        do {
            try self.managedObjectContext.save()
        } catch let error1 as NSError {
            error = error1
        }
        self.managedObjectContext.reset();
        
        if (error != nil) {
            NSLog("Error occured while saving context during prepare: %@", error!)
        }
        
    }
    
    public func storeDidChangeHandler () {
        
        var error: NSError? = nil
        do {
            try self.managedObjectContext.save()
        } catch let error1 as NSError {
            error = error1
        }
        
        if (error != nil) {
            NSLog("Error occured while saving context on change: %@", error!)
        }
        
        if (FBConstants.DEBUG) {
            NSLog("Store did change. Notify listeners");
        }
        
        NSNotificationCenter.defaultCenter().postNotificationName(FBConstants.kUBIQUITYCHANGED, object: self)
        
    }
    
    public func storeDidImportHandler() {
        
        if (FBConstants.DEBUG) {
            NSLog("Store did change on import. Notify listeners")
        }
        
        NSNotificationCenter.defaultCenter().postNotificationName(FBConstants.kUBIQUITYCHANGED, object: self)
    }
    
}