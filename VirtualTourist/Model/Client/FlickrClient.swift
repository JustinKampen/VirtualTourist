//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by Justin Kampen on 3/27/19.
//  Copyright © 2019 Justin Kampen. All rights reserved.
//

import Foundation

class FlickrClient {
    
    // MARK: - Flickr URL Endpoints
    
    static let apiKey = "faa212f560bf5ab44a657d0074da7ed4"

    enum Endpoints {
        static let base = "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=\(apiKey)"
        
        case getPhotoForLocation(String, String, Int)
        
        var stringValue: String {
            switch self {
            case .getPhotoForLocation(let latitude, let longitude, let page):
                return Endpoints.base + "&sort=interestingness-desc&accuracy=11&lat=\(latitude)&lon=\(longitude)&extras=url_n&per_page=30&page=\(page)&format=json&nojsoncallback=1"
            }
        }
        
        var url: URL {
            return URL(string: stringValue)!
        }
    }
    
    // MARK: - Flickr API Call
    
    class func getPhotosForLocation(latitude: String, longitude: String, page: Int, completion: @escaping (FlickrImage?, Int?, Error?) -> Void) {
        let request = URLRequest(url: Endpoints.getPhotoForLocation(latitude, longitude, page).url)
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let data = data else {
                completion(nil, nil, error)
                return
            }
            let decoder = JSONDecoder()
            do {
                let responseObject = try decoder.decode(FlickrResponse.self, from: data)
                completion(responseObject.photos, responseObject.photos.pages, nil)
                PhotoPool.photo = responseObject.photos.photo
                MaxPages.pages = responseObject.photos.pages
            } catch {
                completion(nil, nil, error)
            }
        }
        task.resume()
    }

    class func downloadPhoto(url: URL, completion: @escaping (Data?, Error?) -> Void) {
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data else {
                completion(nil, error)
                return
            }
            completion(data, nil)
        }
        task.resume()
    }
}
