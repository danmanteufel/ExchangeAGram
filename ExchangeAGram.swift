//
//  ExchangeAGram.swift
//  ExchangeAGram
//
//  Created by Dan Manteufel on 11/8/14.
//  Copyright (c) 2014 ManDevil Programming. All rights reserved.
//

import UIKit
import MobileCoreServices
import CoreData
import MapKit

//MARK: - FeedViewController
class FeedViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, CLLocationManagerDelegate {

    //MARK: Properties
    @IBOutlet weak var collectionView: UICollectionView!
    var feedArray: [AnyObject] = [] //Manually implementing the FetchResultsController functionality
    var locationManager: CLLocationManager!
    
    //MARK: Flow Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLocationManager()
        view.backgroundColor = UIColor(patternImage: UIImage(named: "AutumnBackground")!)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        let request = NSFetchRequest(entityName: "FeedItem")
        feedArray = moc!.executeFetchRequest(request, error: nil)!
        collectionView.reloadData()
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
        
        var displayImage = UIImage(data: thisItem.image)
                            
        if Bool(thisItem.filtered) {
            displayImage = UIImage(CGImage: displayImage?.CGImage, scale: 1.0, orientation: .Right)
        }
                            
        cell.imageView.image = displayImage
        cell.captionLabel.text = thisItem.caption
                            
        return cell
    }
    
    //MARK: UICollectionViewDelegate
    func collectionView(collectionView: UICollectionView,
                        didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let thisItem = feedArray[indexPath.item] as FeedItem
        //Doing this in code instead of segueing through the storyboard
        var filterVC = FilterViewController()
        filterVC.thisFeedItem = thisItem
        navigationController?.pushViewController(filterVC, animated: false)
    }
    
    //MARK: UIImagePickerControllerDelegate
    func imagePickerController(picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {
        let image = info[UIImagePickerControllerOriginalImage] as UIImage
        println(image)
        
        let imageData = UIImageJPEGRepresentation(image, 1.0)
        let thumbnailData = UIImageJPEGRepresentation(image, kThumbnailCompression)
        let entityDescription = NSEntityDescription.entityForName("FeedItem", inManagedObjectContext: moc!)
        let feedItem = FeedItem(entity: entityDescription!, insertIntoManagedObjectContext: moc!)
        feedItem.image = imageData
        feedItem.caption = "Test"
        feedItem.thumbnail = thumbnailData
        feedItem.latitude = locationManager.location.coordinate.latitude
        feedItem.longitude = locationManager.location.coordinate.longitude
        feedItem.uniqueID = NSUUID().UUIDString
        feedItem.filtered = false
        appDelegate.saveContext()
        
        feedArray.append(feedItem)
        dismissViewControllerAnimated(true, completion: nil)
        collectionView.reloadData()
    }
    
    //MARK: CLLocationManagerDelegate
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        println("locations = \(locations)")
    }
    
    //MARK: Helper Functions
    func setupLocationManager() {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        
        locationManager.distanceFilter = 100.0
        locationManager.startUpdatingLocation()
    }
    
}

//MARK: - FilterViewController
class FilterViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    //MARK: Defines
    let kTopEdgeInset: CGFloat = 10
    let kLeftEdgeInset: CGFloat = 10
    let kBottomEdgeInset: CGFloat = 10
    let kRightEdgeInset: CGFloat = 10
    let kItemSize = CGSize(width: 150, height: 150)
    let kSaturation = 0.5
    let kIntensity = 0.7
    let kInputMaxX: CGFloat = 0.9
    let kInputMaxY: CGFloat = 0.9
    let kInputMaxZ: CGFloat = 0.9
    let kInputMaxW: CGFloat = 0.9
    let kInputMinX: CGFloat = 0.2
    let kInputMinY: CGFloat = 0.2
    let kInputMinZ: CGFloat = 0.2
    let kInputMinW: CGFloat = 0.2
    let kPlaceholderImage = UIImage(named: "Placeholder")
    let tmp = NSTemporaryDirectory()
    
    //MARK: Properties
    var thisFeedItem: FeedItem!
    var collectionView: UICollectionView!
    var context = CIContext(options: nil)
    var filters: [CIFilter] = []
    
    //MARK: Flow Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: kTopEdgeInset,
                                           left: kLeftEdgeInset,
                                           bottom: kBottomEdgeInset,
                                           right: kRightEdgeInset)
        layout.itemSize = kItemSize
        collectionView = UICollectionView(frame: view.frame, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .whiteColor()
        collectionView.registerClass(FilterCell.self, forCellWithReuseIdentifier: "My Cell")
        view.addSubview(collectionView)
        
        filters = photoFilter()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        let temp = NSFileManager.defaultManager().contentsOfDirectoryAtPath(tmp, error: nil) as [String]
        for file in temp {
            NSFileManager.defaultManager().removeItemAtPath(tmp + file, error: nil)
        }
    }
    
    //MARK: Helper Functions
    func photoFilter() -> [CIFilter] {
        let blur = CIFilter(name: "CIGaussianBlur")
        let instant = CIFilter(name: "CIPhotoEffectInstant")
        let noir = CIFilter(name: "CIPhotoEffectNoir")
        let transfer = CIFilter(name: "CIPhotoEffectTransfer")
        let unsharpen = CIFilter(name: "CIUnsharpMask")
        let monochrome = CIFilter(name: "CIColorMonochrome")
        let colorControls = CIFilter(name: "CIColorControls")
        colorControls.setValue(kSaturation, forKey: kCIInputSaturationKey)
        let sepia = CIFilter(name: "CISepiaTone")
        sepia.setValue(kIntensity, forKey: kCIInputIntensityKey)
        let colorClamp = CIFilter(name: "CIColorClamp")
        colorClamp.setValue(CIVector(x: kInputMaxX,
                                     y: kInputMaxY,
                                     z: kInputMaxZ,
                                     w: kInputMaxW), forKey: "inputMaxComponents")
        colorClamp.setValue(CIVector(x: kInputMinX,
                                     y: kInputMinY,
                                     z: kInputMinZ,
                                     w: kInputMinW), forKey: "inputMinComponents")
        let composite = CIFilter(name: "CIHardLightBlendMode")
        composite.setValue(sepia.outputImage, forKey: kCIInputImageKey)
        let vignette = CIFilter(name: "CIVignette")
        vignette.setValue(composite.outputImage, forKey: kCIInputImageKey)
        vignette.setValue(kIntensity * 2, forKey: kCIInputIntensityKey)
        vignette.setValue(kIntensity * 30, forKey: kCIInputRadiusKey)
        
        return [blur, instant, noir, transfer, unsharpen, monochrome, colorControls, sepia, colorClamp, composite, vignette]
    }
    
    func filteredImageFromImage(imageData: NSData, withFilter filter: CIFilter) -> UIImage {
        filter.setValue(CIImage(data: imageData), forKey: kCIInputImageKey)
        let filteredImage = filter.outputImage
        //Has to do with optimizing the image for processing
        let cgImage = context.createCGImage(filteredImage, fromRect: filteredImage.extent())
        return UIImage(CGImage: cgImage)!//UIImage(CIImage: filteredImage)! would make it crappy
    }
    
    func createUIAlertController(indexPath: NSIndexPath) {
        let alert = UIAlertController(title: "Photo Options",
                                      message: "Please choose an option",
                                      preferredStyle: .Alert)
        alert.addTextFieldWithConfigurationHandler { (textField) -> Void in
            textField.placeholder = "Add Caption"
            textField.secureTextEntry = false
        }
        let textField = alert.textFields![0] as UITextField
        let photoAction = UIAlertAction(title: "Post Photo to Facebook with Caption",
                                        style: .Destructive) { (UIAlertAction) -> Void in
                                            self.shareToFacebook(indexPath)
                                            let text = textField.text
                                            self.saveFilterToCoreData(indexPath, caption: text)}
        alert.addAction(photoAction)
        let saveFilterAction = UIAlertAction(title: "Save Filter",
                                             style: .Default) { (UIAlertAction) -> Void in
                                                let text = textField.text
                                                self.saveFilterToCoreData(indexPath, caption: text)}
        alert.addAction(saveFilterAction)
        let cancelAction = UIAlertAction(title: "Select Another Filter",
                                         style: .Cancel) { (UIAlertAction) -> Void in }
        alert.addAction(cancelAction)
        presentViewController(alert, animated: true, completion: nil)
    }
    
    func saveFilterToCoreData(indexPath: NSIndexPath, caption: String) {
        let filterImage = filteredImageFromImage(thisFeedItem.image, withFilter: filters[indexPath.item])
        thisFeedItem.image = UIImageJPEGRepresentation(filterImage, 1.0)
        thisFeedItem.thumbnail = UIImageJPEGRepresentation(filterImage, kThumbnailCompression)
        thisFeedItem.caption = caption
        thisFeedItem.filtered = true
        appDelegate.saveContext()
        navigationController?.popViewControllerAnimated(true)
    }
    
    func shareToFacebook(indexPath: NSIndexPath) {
        let filterImage = filteredImageFromImage(thisFeedItem.image, withFilter: filters[indexPath.item])
        let photos: NSArray = [filterImage]
        var params = FBPhotoParams()
        params.photos = photos
        FBDialogs.presentShareDialogWithPhotoParams(params, clientState: nil) { (call, result, error) -> Void in
                                                        if (result != nil) {
                                                            println(result)
                                                        } else {
                                                            println(error)
                                                        }
        }
    }
    
    //MARK: UICollectionViewDataSource
    func collectionView(collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return filters.count
    }
    
    func collectionView(collectionView: UICollectionView,
                        cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("My Cell", forIndexPath: indexPath) as FilterCell
        cell.imageView.image = kPlaceholderImage
        let filterQueue = dispatch_queue_create("filter queue", nil)
        dispatch_async(filterQueue, { () -> Void in
            let filterImage = self.getCachedImage(indexPath.item)
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                cell.imageView.image = filterImage
            })
        })
        return cell
    }
    
    //MARK: UICollectionViewDelegate
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        createUIAlertController(indexPath)
    }
    
    //MARK: Caching Functions
    func cacheImage(imageNumber: Int) {
        let fileName = "\(thisFeedItem.uniqueID)\(imageNumber)"
        let uniquePath = tmp.stringByAppendingPathComponent(fileName)
        if !NSFileManager.defaultManager().fileExistsAtPath(uniquePath) {
            let data = self.thisFeedItem.thumbnail
            let filter = self.filters[imageNumber]
            let image = filteredImageFromImage(data, withFilter: filter)
            UIImageJPEGRepresentation(image, 1.0).writeToFile(uniquePath, atomically: true)
        }
    }
    
    func getCachedImage(imageNumber: Int) -> UIImage {
        let fileName = "\(thisFeedItem.uniqueID)\(imageNumber)"
        let uniquePath = tmp.stringByAppendingPathComponent(fileName)
        if !NSFileManager.defaultManager().fileExistsAtPath(uniquePath) {
            cacheImage(imageNumber)
        }
        return UIImage(CGImage: UIImage(contentsOfFile: uniquePath)?.CGImage, scale: 1.0, orientation: .Right)!
    }
}

//MARK: - ProfileViewController
class ProfileViewController: UIViewController, FBLoginViewDelegate {
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var fbLoginView: FBLoginView!
    
    //MARK: Flow Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        fbLoginView.readPermissions = ["public_profile", "publish_actions"]
    }
    
    @IBAction func mapViewButtonPressed(sender: UIButton) {
    }
    
    //MARK: FBLoginViewDelegate
    func loginViewShowingLoggedInUser(loginView: FBLoginView!) {
        //profileImageView.hidden = false
        nameLabel.hidden = false
    }
    
    func loginViewFetchedUserInfo(loginView: FBLoginView!, user: FBGraphUser!) {
        println(user)
        nameLabel.text = user.name
        let userImageURL = "https://graph.facebook.com/\(user.objectID)" +
                           "/picture?type=small"
        let url = NSURL(string: userImageURL)
        profileImageView.image = UIImage(data: NSData(contentsOfURL: url!)!)
    }
    
    func loginViewShowingLoggedOutUser(loginView: FBLoginView!) {
        //profileImageView.hidden = true
        nameLabel.hidden = true
    }
    
    func loginView(loginView: FBLoginView!, handleError error: NSError!) {
        println("Error: \(error.localizedDescription)")
    }
    
}

//MARK: - MapViewController
class MapViewController: UIViewController {
    
    let kLatitudeDelta = 0.05
    let kLongitudeDelta = 0.05
    
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let request = NSFetchRequest(entityName: "FeedItem")
        var error: NSError?
        let itemArray = moc?.executeFetchRequest(request, error: &error)
        if itemArray!.count > 0 {
            for item in itemArray! {
                let location = CLLocationCoordinate2D(latitude: Double(item.latitude), longitude: Double(item.longitude))
                let span = MKCoordinateSpanMake(kLatitudeDelta, kLongitudeDelta)
                let region = MKCoordinateRegionMake(location, span)
                mapView.setRegion(region, animated: true)
                
                let annotation = MKPointAnnotation()
                annotation.setCoordinate(location)
                annotation.title = item.caption
                mapView.addAnnotation(annotation)
            }
        }
        
//        let location = CLLocationCoordinate2D(latitude: 48.868639224587, longitude: 2.37119161036255)
//        let span = MKCoordinateSpanMake(0.05, 0.05)
//        let region = MKCoordinateRegionMake(location, span)
//        mapView.setRegion(region, animated: true)
//        
//        let annotation = MKPointAnnotation()
//        annotation.setCoordinate(location)
//        annotation.title = "Canal Saint-Martin"
//        annotation.subtitle = "Paris"
//        mapView.addAnnotation(annotation)
    }
    
}

//MARK: - FeedCell
class FeedCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var captionLabel: UILabel!
}

//MARK: - FilterCell
class FilterCell: UICollectionViewCell {
    
    //MARK: Properties
    var imageView: UIImageView!
    
    //MARK: Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
        imageView = UIImageView(frame: CGRect(x: 0,
                                              y: 0,
                                              width: frame.size.width,
                                              height: frame.size.height))
        contentView.addSubview(imageView)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

//MARK: - Model
//MARK: Defines
let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
let moc = appDelegate.managedObjectContext
let kThumbnailCompression: CGFloat = 0.1

//MARK: Globals

//MARK: Structs

//MARK: Classes