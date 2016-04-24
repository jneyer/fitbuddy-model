//
//  CloudKitConnection.swift
//  FitBuddyModel
//
//  Created by John Neyer on 4/24/16.
//  Copyright © 2016 John Neyer. All rights reserved.
//

import Foundation
import CloudKit
import FitBuddyCommon

@objc
public class CloudKitConnection : NSObject {
    
    //The default context
    public static let defaultConnection : CloudKitConnection = CloudKitConnection()
    
    public let publicDB = CKContainer.defaultContainer().publicCloudDatabase
    public let privateDB = CKContainer.defaultContainer().privateCloudDatabase
    
    override
    public init() {
        
    }
    
    

    
    
}