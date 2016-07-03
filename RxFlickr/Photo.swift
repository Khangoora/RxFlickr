//
//  Photo.swift
//  RxFlickr
//
//  Created by Jaskirat Khangoora on 6/30/16.
//  Copyright © 2016 Jaskirat Khangoora. All rights reserved.
//



struct Photo {
    var identifier: String!
    var owner: String!
    var secret: String!
    var server: String!
    var farm: String!
    var imageURL : String!
    var title : String!
    
    init() {
        self.identifier = ""
        self.owner = ""
        self.secret = ""
        self.server = ""
        self.farm = ""
        self.imageURL = ""
        self.title = ""


    }
}


