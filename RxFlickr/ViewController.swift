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

class ViewController: UIViewController, UICollectionViewDelegate, UISearchBarDelegate, UISearchControllerDelegate {
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var collectionView: UICollectionView!
    var flickrAPI: FlickrAPI!
    
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
    }
    
    func setupRx() {
        flickrAPI = FlickrAPI(withNameObservable: rx_searchBarText)
        
        flickrAPI
            .rx_Photos
            .drive(collectionView.rx_itemsWithCellFactory) { (cv, i, photo) in
                let cell = cv.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: NSIndexPath(forRow: i, inSection: 0)) as! imageCollectionViewCell
                
                Alamofire.request(.GET, photo.imageURL)
                    .responseImage { response in
                        
                        if let image = response.result.value {
                            
                            cell.imageView.image = image.resizeImage(image, newWidth: 125.0)
                            cell.titleLabel.text = photo.title
                        }
                }

                
                return cell
            }
            .addDisposableTo(disposeBag)
        
        flickrAPI
            .rx_Photos
            .driveNext { photos in
                if photos.count == 0 {
                    let alert = UIAlertController(title: "Oops", message: "No Photos for this search.", preferredStyle: .Alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
                    if self.navigationController?.visibleViewController?.isMemberOfClass(UIAlertController.self) != true {
                        self.presentViewController(alert, animated: true, completion: nil)
                    }
                    
                }
            }
            .addDisposableTo(disposeBag)
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
