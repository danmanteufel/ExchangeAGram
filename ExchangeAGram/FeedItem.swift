//
//  FeedItem.swift
//  ExchangeAGram
//
//  Created by Dan Manteufel on 11/24/14.
//  Copyright (c) 2014 ManDevil Programming. All rights reserved.
//

import Foundation
import CoreData

@objc (FeedItem)
class FeedItem: NSManagedObject {

    @NSManaged var caption: String
    @NSManaged var image: NSData
    @NSManaged var thumbnail: NSData
    @NSManaged var latitude: NSNumber
    @NSManaged var longitude: NSNumber

}
