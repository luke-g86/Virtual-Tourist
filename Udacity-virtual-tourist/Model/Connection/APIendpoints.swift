//
//  APIendpoints.swift
//  Udacity-virtual-tourist
//
//  Created by Lukasz on 15/07/2019.
//  Copyright © 2019 Lukasz. All rights reserved.
//

import Foundation

class APIendpoints {
    
    
    struct FlickrEndpointKeys {
        static let method = "method"
        static let APIkey = "api_key"
        static let format = "format"
        static let radius = "radius"
        static let noJsonCallBack = "nojsoncallback"
        static let perPage = "per_page"
        static let latitude = "lat"
        static let longitude = "lon"
        static let page = "page"
    }
    
    struct FlickrEndpointValues {
        static let APIkey = "4afb415cd8b1924e93014c604b3ed5fe"
        static let scheme = "https"
        static let host = "www.flickr.com"
        static let path = "/services/rest/"
        static let method = "flickr.photos.search"
        static let format = "json"
        // Radius city level
        static let radius = 5
        // No callback
        static let noJsonCallBack = 1
        // No. of pictures
        static let perPage = 20
        
    }
    
    
    class func constructURL(latitude: Double, longitute: Double, page: Int32) -> URLComponents {
        var url = URLComponents()
        url.scheme = FlickrEndpointValues.scheme
        url.host = FlickrEndpointValues.host
        url.path = FlickrEndpointValues.path
        
        
        let urlQueryItems = [
            FlickrEndpointKeys.format : FlickrEndpointValues.format,
            FlickrEndpointKeys.radius : FlickrEndpointValues.radius,
            FlickrEndpointKeys.noJsonCallBack : FlickrEndpointValues.noJsonCallBack,
            FlickrEndpointKeys.perPage : FlickrEndpointValues.perPage
            ] as [String : Any]
        
  
        
        url.queryItems = [
            URLQueryItem(name: FlickrEndpointKeys.method, value: FlickrEndpointValues.method),
            URLQueryItem(name: FlickrEndpointKeys.APIkey, value: FlickrEndpointValues.APIkey),
            URLQueryItem(name: FlickrEndpointKeys.latitude, value: String(format: "%.5f", latitude)),
            URLQueryItem(name: FlickrEndpointKeys.longitude, value: String(format: "%.5f", longitute)),
            URLQueryItem(name: FlickrEndpointKeys.page, value: String(page))
        ]
        
        for (key, value) in urlQueryItems {
            let item = URLQueryItem(name: key, value: "\(value)")
            url.queryItems?.append(item)
        }
        
        return url
        
    }
    
    
    
}
