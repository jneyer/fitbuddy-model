//
//  CoreDataModelManager.swift
//  FitBuddy
//
//  Created by john.neyer on 5/10/15.
//  Copyright (c) 2015 jneyer.com. All rights reserved.
//

import Foundation
import FitBuddyCommon
import CoreData

@objc
public class CoreDataModelManager: NSObject, ModelManager {
    
    var coreData : CoreDataConnection?
    
    public required init (connection : CoreDataConnection) {
        coreData = connection
    }
    
    public func getAllWorkouts() -> [Workout] {
        
        let mm = CloudKitModelManager(connection: CloudKitConnection.defaultConnection)
        mm.getAllWorkouts()
        
        // Create a new fetch request using the LogItem entity
        let fetchRequest = NSFetchRequest(entityName: FBConstants.WORKOUT_TABLE)
        let sortDescriptor = NSSortDescriptor(key: "last_workout", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        // Execute the fetch request, and cast the results to an array of LogItem objects
        if let fetchResults = (try? coreData!.managedObjectContext.executeFetchRequest(fetchRequest)) as? [Workout] {
            return fetchResults
        }
        
        return []
    }
    
    public func getWorkoutSequence (workout: Workout) -> [WorkoutSequence] {
        
        let fetchRequest = NSFetchRequest(entityName: FBConstants.WORKOUT_SEQUENCE)
        fetchRequest.predicate = NSPredicate(format: "workout == %@", argumentArray: [workout])
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "sequence", ascending: true)]
        
        if let fetchResults = (try? coreData!.managedObjectContext.executeFetchRequest(fetchRequest)) as? [WorkoutSequence] {
            return fetchResults
        }
        
        return []
    }
    
    public func newLogbookEntryFromWorkoutSequence (workoutSequence: WorkoutSequence) -> LogbookEntry {
        
        let newEntry = NSEntityDescription.insertNewObjectForEntityForName(FBConstants.LOGBOOK_TABLE, inManagedObjectContext: coreData!.managedObjectContext) as! LogbookEntry
        
        newEntry.workout = workoutSequence.workout
        newEntry.workout_name = workoutSequence.workout.workout_name
        newEntry.date = NSDate()
        newEntry.exercise_name = workoutSequence.exercise.name
        newEntry.notes = workoutSequence.exercise.notes
        newEntry.completed = true
        
        if workoutSequence.exercise is ResistanceExercise {
            
            let exercise = workoutSequence.exercise as! ResistanceExercise
            newEntry.weight = exercise.weight
            newEntry.sets = exercise.sets
            newEntry.reps = exercise.reps
        }
        
        if workoutSequence.exercise is CardioExercise {
            
            let exercise = workoutSequence.exercise as! CardioExercise
            newEntry.pace = exercise.pace
            newEntry.distance = exercise.distance
            newEntry.duration = exercise.duration
        }
        
        return newEntry;
        
    }
    
    public func getLastWorkoutDate (workout: Workout, withFormat: String? = nil) -> String {
        
        if workout.last_workout != nil
        {
            if withFormat != nil {
                return FitBuddyUtils.dateFromNSDate(workout.last_workout, format:withFormat!)
            }
            
            return FitBuddyUtils.shortDateFromNSDate(workout.last_workout)
        }
        else
        {
            if workout.logbookEntries.count == 0
            {
                return "never"
            }
        }
        
        let sortDescriptor = NSSortDescriptor(key: "date", ascending: false)
        let sorted = workout.logbookEntries.sortedArrayUsingDescriptors([sortDescriptor])
        
        let completed = NSPredicate(format: "completed = 1");
        let filtered = sorted.filter { completed.evaluateWithObject($0) }
        
        let lastDate = (filtered[0] as! LogbookEntry).date
        
        workout.last_workout = lastDate
        do {
            try workout.managedObjectContext?.save()
        } catch _ {
        }
        
        if withFormat != nil {
            return FitBuddyUtils.dateFromNSDate(workout.last_workout, format:withFormat!)
        }
        
        return FitBuddyUtils.shortDateFromNSDate(workout.last_workout)
    }
    
    public func getLogbookWorkoutsByDate () -> NSDictionary {
        
        let results = NSMutableDictionary()
        let queryResults = getAllLogbookEntries()
        
        if queryResults.count > 0 {
            
            for entry in queryResults {
                
                let entryDate = FitBuddyUtils.shortDateFromNSDate(entry.date_t)
                
                if let array = results.objectForKey(entryDate) as? NSMutableArray {
                    
                    if entry.workout != nil && !array.containsObject(entry.workout!) {
                        array.addObject(entry.workout!)
                    }
                }
                else {
                    
                    if entry.workout != nil {
                        results.setObject(NSMutableArray(array:[entry.workout!]), forKey: entryDate)
                    }
                }
                
            }
        }
        
        return results
        
    }
    
    public func getAllLogbookEntries () ->  [LogbookEntry] {
        
        let fetchRequest = NSFetchRequest(entityName: FBConstants.LOGBOOK_TABLE)
        let sortDescriptor = NSSortDescriptor(key: "date", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        let predicate = NSPredicate(format: "completed = %@", argumentArray: [1])
        fetchRequest.predicate = predicate
        
        // Execute the fetch request, and cast the results to an array of LogItem objects
        if let fetchResults = (try? CoreDataConnection.defaultConnection.managedObjectContext.executeFetchRequest(fetchRequest)) as? [LogbookEntry] {
            return fetchResults
        }
        
        return []
    }
    
    public func getLogBookEntriesByWorkoutAndDate (workout: Workout, date: NSDate) -> [LogbookEntry] {
        
        
        
        return []
    }
    
    public func deleteDataObject (nsManagedObject: AnyObject?) {
        
        if let dataObj = nsManagedObject as? NSManagedObject {
            coreData!.managedObjectContext.deleteObject(dataObj)
            save()
            
            NSLog("Deleted managed object")
        }else {
            NSLog("Did not net an NSManagedObjectModel, \(nsManagedObject)")
        }
    }
    
    public func save () {
        
        var error: NSError? = nil
        if coreData!.managedObjectContext.hasChanges {
            do {
                try coreData!.managedObjectContext.save()
            } catch let error1 as NSError {
                error = error1
            }
        }
        
        if error != nil {
            NSLog("Unresolved error \(error), \(error!.userInfo)")
            abort()
        }
        
    }

    public func exportData(destination: String) -> NSURL? {
        
        if destination == FBConstants.kITUNES {
            let archive = CoreDataArchive()
            return archive.exportToDisk(true)
        }
        
        NSLog("Unknown export type: %@", destination);
        return nil;
        
    }
    
    public func importData(reference: AnyObject?) {
        NSLog("importData for CoreDataModelManager is not implemented")
    }
    
    public func saveModel(modelObject: AnyObject?) {
        if let object = modelObject as? NSManagedObject {
            
            var error: NSError? = nil
            do {
                try object.managedObjectContext?.save()
            } catch let error1 as NSError {
                error = error1
            }
            
            if error != nil {
                NSLog("Error saving model context \(error), \(error!.userInfo)")
                abort()
            }
        }
    }
    
    public func refreshModel(modelObject: AnyObject?) {
        if modelObject is NSManagedObject {
            CoreDataConnection.defaultConnection.managedObjectContext.refreshObject(modelObject as! NSManagedObject, mergeChanges: true)
        }
    }
    
}
