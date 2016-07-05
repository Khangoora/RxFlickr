//
//  ViewController.swift
//  RxFlickr
//
//  Created by Jaskirat Khangoora on 6/30/16.
//  Copyright © 2016 Jaskirat Khangoora. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import AlamofireImage
import Alamofire
import ImageIO

class ViewController: UIViewController, UICollectionViewDelegate, UISearchBarDelegate, UISearchControllerDelegate {
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var collectionView: UICollectionView!
    var flickrAPI: FlickrAPI!
    let photoCache = AutoPurgingImageCache(
        memoryCapacity: 100 * 1024 * 1024,
        preferredMemoryUsageAfterPurge: 60 * 1024 * 1024
    )
    
    let disposeBag = DisposeBag()
    var rx_searchBarText: Observable<String> {
        return searchBar
            .rx_text
            .filter { $0.characters.count > 0 }
            .throttle(0.5, scheduler: MainScheduler.instance)
            .map{$0.lowercaseString}
            .distinctUntilChanged()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupRx()
        configureKeyboardDismissesOnScroll()
    }
    
    func setupRx() {
        flickrAPI = FlickrAPI(withNameObservable: rx_searchBarText)
        
        flickrAPI
            .rx_Photos
            .drive(collectionView.rx_itemsWithCellFactory) { (cv, i, photo) in
                let cell = cv.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: NSIndexPath(forRow: i, inSection: 0)) as! imageCollectionViewCell
                
                //If image cached no need to make network call
                if let image = self.cachedImage(photo.imageURL) {
                    self.setupCell(cell, image: image, photo: photo)
                }
                
                else { //Send Alamofire request to get images
                    self.getImages(photo, cell: cell)
                }
                
                return cell
            }
            .addDisposableTo(disposeBag)
        
        flickrAPI
            .rx_Photos
            .driveNext { photos in
                if photos.count == 1 {
                    self.setAlert("Oops", message: "No photos for this search.")
                }
            }
            .addDisposableTo(disposeBag)
    }
    
    func configureKeyboardDismissesOnScroll() {
        let searchBar = self.searchBar
        
        collectionView.rx_contentOffset
            .asDriver()
            .driveNext { _ in
                if searchBar.isFirstResponder() {
                    _ = searchBar.resignFirstResponder()
                }
            }
            .addDisposableTo(disposeBag)
    }
    
    // MARK: Get Images using Alamofire
    func getImages(photo: Photo, cell: imageCollectionViewCell) {
        Alamofire.request(.GET, photo.imageURL)
            .responseImage { response in
                if let image = response.result.value {
                    self.setupCell(cell, image: image, photo: photo)
                    self.cacheImage(image, url: photo.imageURL)
                    
                }
                else {
                    cell.hidden = true  //if image does not exist hide collectionViewCell
                }
        }
        
    }
    
    // MARK: Setup Cell
    func setupCell(cell : imageCollectionViewCell, image : UIImage, photo : Photo){
        cell.imageView.image = image.resizeImage(image, newWidth: 125.0)
        cell.titleLabel.text = photo.title
        cell.hidden = false
        
        
    }
    
    // MARK: Setup Alert
    
    func setAlert(title : String, message : String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
        if self.navigationController?.visibleViewController?.isMemberOfClass(UIAlertController.self) != true {
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    // MARK: Caching
    
    func cacheImage(image: Image, url: String) {
        photoCache.addImage(image, withIdentifier: url)
    }
    
    func cachedImage(url: String) -> Image? {
        return photoCache.imageWithIdentifier(url)
    }
    
    // MARK: MetaData
    
    func getImageMetaData() {
        let url = NSURL(string: "http://ptforum.photoolsweb.com/ubbthreads.php?ubb=download&Number=1024&filename=1024-2006_1011_093752.jpg")        
        
        if let imageSource = CGImageSourceCreateWithURL(url!, nil) {
            print(imageSource)
            if let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as Dictionary! {
                print(imageProperties)
                if let GPSProperties = imageProperties[kCGImagePropertyGPSDictionary] as? [String : AnyObject]{
                    print(GPSProperties[kCGImagePropertyGPSLatitude as String], GPSProperties[kCGImagePropertyGPSLongitude as String])
                }
                
            }
        }
    }
}
extension UIImage {
    func resizeImage(image: UIImage, newWidth: CGFloat) -> UIImage {
        
        let scale = newWidth / image.size.width
        let newHeight = image.size.height * scale
        UIGraphicsBeginImageContext(CGSizeMake(newWidth, newHeight))
        image.drawInRect(CGRectMake(0, 0, newWidth, newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
}
