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
                    cell.imageView.image = image.resizeImage(image, newWidth: 125.0)
                    cell.titleLabel.text = photo.title
                    cell.hidden = false
                }
                
                else {
                    //if image not cached get image and cache it
                    Alamofire.request(.GET, photo.imageURL)
                        .responseImage { response in
                            if let image = response.result.value {
                                cell.imageView.image = image.resizeImage(image, newWidth: 125.0)
                                cell.titleLabel.text = photo.title
                                self.cacheImage(image, url: photo.imageURL)
                                cell.hidden = false
                            }
                            else {
                                cell.hidden = true  //if image does not exist hide collectionViewCell
                            }
                        }
                    }
                return cell
            }
            .addDisposableTo(disposeBag)
        
        flickrAPI
            .rx_Photos
            .driveNext { photos in
                if photos.count == 1 {
                    let alert = UIAlertController(title: "Oops", message: "No Photos for this search.", preferredStyle: .Alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
                    if self.navigationController?.visibleViewController?.isMemberOfClass(UIAlertController.self) != true {
                        self.presentViewController(alert, animated: true, completion: nil)
                    }
                    
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
    
    //Mark: Caching
    
    func cacheImage(image: Image, url: String) {
        photoCache.addImage(image, withIdentifier: url)
    }
    
    func cachedImage(url: String) -> Image? {
        return photoCache.imageWithIdentifier(url)
    }
    
    //Mark: MetaData
    
    func getImageMetaData() {
        let url = NSURL(string: "https://api.flickr.com/services/rest/?method=flickr.photos.getExif&api_key=10def1bdc4c43b3435513ee7df0ac4d1&photo_id=28010652176&format=json&nojsoncallback=1&api_sig=de57ef7e5305aa41497da5bb326afcb1")        
        
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
