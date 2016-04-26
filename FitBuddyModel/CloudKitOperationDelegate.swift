//
//  ModelDelegate.swift
//  FitBuddyModel
//
//  Created by John Neyer on 4/25/16.
//  Copyright © 2016 John Neyer. All rights reserved.
//

import Foundation

public protocol CloudKitOperationDelegate {
    //func operationCompleted()
    //func operationCompleted(results: AnyObject?)
    func operationCompleted(results: [AnyObject?])
}
