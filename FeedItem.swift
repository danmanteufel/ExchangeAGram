//
//  FeedItem.swift
//  ExchangeAGram
//
//  Created by Dan Manteufel on 11/8/14.
//  Copyright (c) 2014 ManDevil Programming. All rights reserved.
//

import Foundation
import CoreData

@objc (FeedItem)
class FeedItem: NSManagedObject {

    @NSManaged var image: NSData
    @NSManaged var caption: String

}
