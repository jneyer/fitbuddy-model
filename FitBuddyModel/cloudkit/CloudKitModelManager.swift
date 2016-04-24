//
//  CloudKitModelManager.swift
//  FitBuddyModel
//
//  Created by John Neyer on 4/24/16.
//  Copyright © 2016 John Neyer. All rights reserved.
//

import Foundation
import CloudKit
import FitBuddyCommon
import CoreData

@objc
public class CloudKitModelManager : NSObject, ModelManager {
    
    var cloudKit: CloudKitConnection?
    
    public required init (connection : CloudKitConnection) {
        cloudKit = connection
    }
    
    public func getAllWorkouts () -> [Workout] {
        
        return getRecords("Workout", condition: nil) as! [Workout]
    }
    
    public func getWorkoutSequence (workout: Workout) -> [WorkoutSequence] {
        
        return []
    }
    
    public func newLogbookEntryFromWorkoutSequence (workoutSequence: WorkoutSequence) -> LogbookEntry {
        
        return LogbookEntry()
    }
    
    public func getLastWorkoutDate (workout: Workout, withFormat : String?) -> String {
        
        return ""
    }
    
    
    public func getLogbookWorkoutsByDate () -> NSDictionary {
        
        return NSDictionary()
    }
    
    public func getAllLogbookEntries () ->  [LogbookEntry] {
        
        return []
    }
    
    
    public func getLogBookEntriesByWorkoutAndDate (workout: Workout, date: NSDate) -> [LogbookEntry] {
        
        return []
    }
    
    public func deleteDataObject (modelObject: AnyObject?) {
        
        
        
    }
    
    public func save () {
        
    }
    
    public func exportData(destination: String) -> NSURL? {
        
        return nil
    }
    
    public func importData(reference: AnyObject?) {
        NSLog("importData for CoreDataModelManager is not implemented")
    }
    
    public func saveModel(modelObject: AnyObject?) {
        
        if let obj = modelObject as? Workout {
            let myRecord = CKRecord (recordType: "Workout")
            myRecord.setObject(obj.workout_name, forKey: "workout_name")
            myRecord.setObject(obj.last_workout, forKey: "last_workout")
            myRecord.setObject((obj.deleted ? 1:0), forKey: "deleted")
            myRecord.setObject(obj.display, forKey: "display")
            cloudKit?.privateDB.saveRecord(myRecord, completionHandler: { savedRecord, saveError in
                
                if let e = saveError {
                    NSLog("An error occured saving data: \(e)")
                } else {
                    NSLog("Record saved successfully: \(savedRecord)")
                }
            })
            
        }
        
    }
    
    public func refreshModel(modelObject: AnyObject?) {
        
        
    }


    func getRecords (recordType: String, condition: NSPredicate?) -> [AnyObject] {
        
        var search = condition
        
        if search == nil {
            search = NSPredicate(value: true)
        }
        
        let query = CKQuery(recordType: recordType, predicate: search!)
        
        cloudKit?.privateDB.performQuery(query, inZoneWithID: nil, completionHandler: ({results, error in
            
            if (error != nil) {
                dispatch_async(dispatch_get_main_queue()) {
                    NSLog("Cloud access error: \(error)")
                }
            } else {
                
                if results!.count > 0 {
                    NSLog("Found \(results!.count) records")

                } else {
                    NSLog("No records found")
                }
            }
            
            
            
        }))
        
        return []
    }
    
    func getRecord () -> AnyObject? {
        
        
        return nil
    }
    
}