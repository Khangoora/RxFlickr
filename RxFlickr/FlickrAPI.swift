//
//  FlickrAPI.swift
//  RxFlickr
//
//  Created by Jaskirat Khangoora on 6/30/16.
//  Copyright © 2016 Jaskirat Khangoora. All rights reserved.
//



import Alamofire
import RxSwift
import RxAlamofire
import RxCocoa
import SwiftyJSON
import AlamofireImage


struct FlickrAPI {
    let FLICKR_API_KEY:String = "c7ef74ae22618e8394377baa86d6df07"
    let FLICKR_URL:String = "https://api.flickr.com/services/rest/"
    let SEARCH_METHOD:String = "flickr.photos.search"
    let FORMAT_TYPE:String = "json"
    let JSON_CALLBACK:Int = 1
    let PRIVACY_FILTER:Int = 1
    
    lazy var rx_Photos: Driver<[Photo]> = self.fetchPhotos()
    private var imageSearch: Observable<String>
    var photo = Photo()
    var photos = [Photo]()

    
    init(withNameObservable nameObservable: Observable<String>) {
        self.imageSearch = nameObservable
    }
    
    private mutating func fetchPhotos() -> Driver<[Photo]> {
        return imageSearch
            .subscribeOn(MainScheduler.instance)
            .doOn(onNext: { response in
                UIApplication.sharedApplication().networkActivityIndicatorVisible = true
            })
            .observeOn(ConcurrentDispatchQueueScheduler(globalConcurrentQueueQOS: .Background))
            .flatMapLatest { text in 
                return RxAlamofire
                    .requestJSON(.GET, self.FLICKR_URL, parameters: ["method": self.SEARCH_METHOD, "api_key": self.FLICKR_API_KEY, "tags":text,"privacy_filter":self.PRIVACY_FILTER, "format":self.FORMAT_TYPE, "nojsoncallback": self.JSON_CALLBACK])
                    .debug()
                    .catchError { error in
                        return Observable.never()
                }
            }
            .observeOn(ConcurrentDispatchQueueScheduler(globalConcurrentQueueQOS: .Background))
            .map { (response, json) -> [Photo] in
                
                self.photos.removeAll()
                print(self.photos)
                var innerJson:JSON = JSON(json)
                let numberOfPhotos = innerJson["photos"]["perpage"].int
                
                for i in 0...numberOfPhotos!{
                    var innerJson:JSON = JSON(json)
                    self.photo.farm = innerJson["photos"]["photo"][i]["farm"].stringValue
                    self.photo.server = innerJson["photos"]["photo"][i]["server"].stringValue
                    self.photo.identifier = innerJson["photos"]["photo"][i]["id"].stringValue
                
                    self.photo.secret = innerJson["photos"]["photo"][i]["secret"].stringValue
                    self.photo.title = innerJson["photos"]["photo"][i]["title"].stringValue

                
                    self.photo.imageURL = "http://farm\(self.photo.farm).staticflickr.com/\(self.photo.server)/\(self.photo.identifier)_\(self.photo.secret)_s.jpg/"
                    
                    self.photos.append(self.photo)

                
                }
            
                return self.photos

                
            }
            .observeOn(MainScheduler.instance)
            .doOn(onNext: { response in
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            })
            .asDriver(onErrorJustReturn: [])
    }
}
