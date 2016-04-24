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

class CoreDataTableControllerS: UIViewController, UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var tableView: UITableView?
    var fetchedResultsController: NSFetchedResultsController?
    var debug = false
    var suspendAutomaticTrackingOfChangesInManagedObjectContext = false
    var beganUpdates = false
    
    
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
    
    private func setFetchedResultsController (newfrc: NSFetchedResultsController) {
        
        let oldfrc = self.fetchedResultsController
        
        if newfrc != oldfrc {
            self.fetchedResultsController = newfrc
            newfrc.delegate = self
            self.performFetch()
        } else {
            self.tableView?.reloadData()
        }
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
            self.tableView?.beginUpdates()
            self.beganUpdates = true
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
                self.tableView?.insertRowsAtIndexPaths([indexPath!], withRowAnimation: UITableViewRowAnimation.Fade)
            case NSFetchedResultsChangeType.Delete:
                self.tableView?.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: UITableViewRowAnimation.Fade)
            case NSFetchedResultsChangeType.Update:
                self.tableView?.reloadRowsAtIndexPaths([indexPath!], withRowAnimation: UITableViewRowAnimation.Fade)
            case NSFetchedResultsChangeType.Move:
                self.tableView?.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: UITableViewRowAnimation.Fade)
                self.tableView?.insertRowsAtIndexPaths([indexPath!], withRowAnimation: UITableViewRowAnimation.Fade)
                
            }
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        if (self.beganUpdates) {
            self.tableView?.endUpdates()
        }
    }
}
