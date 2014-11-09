//
//  FeedViewController.swift
//  ExchangeAGram
//
//  Created by Dan Manteufel on 11/8/14.
//  Copyright (c) 2014 ManDevil Programming. All rights reserved.
//

import UIKit
import MobileCoreServices
import CoreData

//MARK: - FeedViewController
class FeedViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate {

    @IBOutlet weak var collectionView: UICollectionView!
    
    var feedArray: [AnyObject] = [] //Manually implementing the FetchResultsController functionality
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let request = NSFetchRequest(entityName: "FeedItem")
        feedArray = moc!.executeFetchRequest(request, error: nil)!

    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
         //Get the new view controller using segue.destinationViewController.
         //Pass the selected object to the new view controller.
    }
    
    @IBAction func snapBarButtonItemPressed(sender: UIBarButtonItem) {
        if UIImagePickerController.isSourceTypeAvailable(.Camera) {
            var cameraController = UIImagePickerController()
            cameraController.delegate = self
            cameraController.sourceType = .Camera
            cameraController.mediaTypes = [kUTTypeImage]
            cameraController.allowsEditing = false //not necessary - default
            self.presentViewController(cameraController, animated: true, completion: nil)
        } else if UIImagePickerController.isSourceTypeAvailable(.PhotoLibrary) {
            var cameraController = UIImagePickerController()
            cameraController.delegate = self
            cameraController.sourceType = .PhotoLibrary //not necessary - default
            cameraController.mediaTypes = [kUTTypeImage]
            cameraController.allowsEditing = false //not necessary - default
            self.presentViewController(cameraController, animated: true, completion: nil)
        } else {
            var alert = UIAlertController(title: "Alert",
                                          message: "You can't use this app unless you allow access your Photo Library and/or Camera.  Go to Settings -> Privacy -> Photos and/or Camera.",
                                          preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    //MARK: UICollectionViewDataSource
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return feedArray.count
    }
    
    func collectionView(collectionView: UICollectionView,
                        cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        var cell: FeedCell = collectionView.dequeueReusableCellWithReuseIdentifier("Feed Cell", forIndexPath: indexPath) as FeedCell
        let thisItem = feedArray[indexPath.item] as FeedItem
        
        cell.imageView.image = UIImage(data: thisItem.image)
        cell.captionLabel.text = thisItem.caption
                            
        return cell
    }
    
    //MARK: UICollectionViewDelegate
    
    //MARK: UIImagePickerControllerDelegate
    func imagePickerController(picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {
        let image = info[UIImagePickerControllerOriginalImage] as UIImage
        println(image)
        
        let imageData = UIImageJPEGRepresentation(image, 1.0)
        let entityDescription = NSEntityDescription.entityForName("FeedItem", inManagedObjectContext: moc!)
        let feedItem = FeedItem(entity: entityDescription!, insertIntoManagedObjectContext: moc!)
        feedItem.image = imageData
        feedItem.caption = "Test"
        appDelegate.saveContext()
        
        feedArray.append(feedItem)
        dismissViewControllerAnimated(true, completion: nil)
        collectionView.reloadData()
    }
    
}

//MARK: - FeedCell
class FeedCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var captionLabel: UILabel!
}

//MARK: - Model
//MARK: Defines
let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
let moc = appDelegate.managedObjectContext

//MARK: Globals

//MARK: Structs

//MARK: Classes