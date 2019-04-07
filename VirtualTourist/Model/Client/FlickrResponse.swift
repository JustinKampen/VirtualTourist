//
//  FlickrResponse.swift
//  VirtualTourist
//
//  Created by Justin Kampen on 3/28/19.
//  Copyright © 2019 Justin Kampen. All rights reserved.
//

import Foundation

struct FlickrResponse: Codable {
    let photos: FlickrImage
    let stat: String
}

struct FlickrImage: Codable {
    let page: Int
    let pages: Int
    let perpage: Int
    let total: String
    let photo: [FlickrURL]
}

struct FlickrURL: Codable {
    let id: String
    let server: String
    let secret: String
    let farm: Int
    let ispublic: Int
    let url_n: String
}
