//
//  CoreDataTableController.swift
//  FitBuddy
//
//  Created by John Neyer on 4/24/16.
//  Copyright © 2016 jneyer.com. All rights reserved.
//

import Foundation
import FitBuddyCommon
import CoreData

class CoreDataTableController: UIViewController, UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var tableView: UITableView?
    
    var debug = false
    var suspendAutomaticTrackingOfChangesInManagedObjectContext = false
    var beganUpdates = false
    
    var controllerChanged = false
    
    var fetchedResultsController : NSFetchedResultsController? {
        
        willSet (newfrc) {
            if newfrc != nil && newfrc != self.fetchedResultsController {
                controllerChanged = true
                newfrc!.delegate = self
            }
        }
        
        didSet {
            if controllerChanged {
                self.performFetch()
                controllerChanged = false
            } else {
                self.tableView?.reloadData()
            }
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        return UITableViewCell()
    }
    
    func performFetch () {
        
        if ((self.fetchedResultsController) != nil) {
            if ((self.fetchedResultsController?.fetchRequest.predicate) != nil) {
                if (self.debug) {
                    NSLog("Fetching \(self.fetchedResultsController!.fetchRequest.entityName) with predicate \(self.fetchedResultsController!.fetchRequest.predicate)")
                }
            } else {
                if (self.debug) {
                    NSLog("Fetching all \(self.fetchedResultsController?.fetchRequest.entityName) (no predicate)")
                }
            }
            do {
                try self.fetchedResultsController!.performFetch()
            } catch {
                
                
            }
        } else {
            NSLog ("NSFetchedResultsController not initialized")
        }
        
        self.tableView?.reloadData()
        
    }
    
    
    // UITableViewDataSource Support
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        if self.fetchedResultsController != nil && self.fetchedResultsController?.sections != nil {
            return (self.fetchedResultsController?.sections?.count)!
        }
        return 0
    }
   
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (self.fetchedResultsController?.sections![section].numberOfObjects)!
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.fetchedResultsController?.sections![section].name
    }
    
    func tableView(tableView: UITableView, sectionForSectionIndexTitle title: String, atIndex index: Int) -> Int {
        return (self.fetchedResultsController?.sectionForSectionIndexTitle(title, atIndex: index))!
    }
    
    func sectionIndexTitlesForTableView(tableView: UITableView) -> [String]? {
        return self.fetchedResultsController?.sectionIndexTitles
    }
 
    //NSFetchedControllerDelegate
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        if (!self.suspendAutomaticTrackingOfChangesInManagedObjectContext) {
            if let view = self.tableView {
                view.beginUpdates()
                self.beganUpdates = true
            }
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        if (!self.suspendAutomaticTrackingOfChangesInManagedObjectContext)
        {
            switch (type) {
            case NSFetchedResultsChangeType.Insert:
                self.tableView?.insertSections(NSIndexSet.init(index: sectionIndex), withRowAnimation: UITableViewRowAnimation.Fade)
            case NSFetchedResultsChangeType.Delete:
                self.tableView?.deleteSections(NSIndexSet.init(index: sectionIndex), withRowAnimation: UITableViewRowAnimation.Fade)
            default: break
                // Do Nothing
            }
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        if (!self.suspendAutomaticTrackingOfChangesInManagedObjectContext) {
            
            switch (type) {
                
            case NSFetchedResultsChangeType.Insert:
                self.tableView?.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: UITableViewRowAnimation.Fade)
            case NSFetchedResultsChangeType.Delete:
                self.tableView?.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: UITableViewRowAnimation.Fade)
            case NSFetchedResultsChangeType.Update:
                self.tableView?.reloadRowsAtIndexPaths([indexPath!], withRowAnimation: UITableViewRowAnimation.Fade)
            case NSFetchedResultsChangeType.Move:
                self.tableView?.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: UITableViewRowAnimation.Fade)
                self.tableView?.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: UITableViewRowAnimation.Fade)
                
            }
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        if (self.beganUpdates) {
            self.tableView?.endUpdates()
        }
    }
}
