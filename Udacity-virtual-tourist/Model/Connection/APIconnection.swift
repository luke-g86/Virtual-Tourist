//
//  APIconnection.swift
//  Udacity-virtual-tourist
//
//  Created by Lukasz on 22/07/2019.
//  Copyright © 2019 Lukasz. All rights reserved.
//

import Foundation

class APIConnection {
    
    //MARK: Fetching JSON from the Flickr API
    
    class func getDataFromFlickr(longitude: Double, latitude: Double, page: Int32?, completionHandler: @escaping (PhotosSearchResponse?, Error?) -> Void) {
        
        let createdURL = APIendpoints.constructURL(latitude: latitude, longitute: longitude, page: page ?? 1).url
        let task = URLSession.shared.dataTask(with: createdURL!) { (data, response, error) in
            guard let data = data else {
                DispatchQueue.main.async {
                    completionHandler(nil, error)
                }
                return
            }
            let decoder = JSONDecoder()
            do {
                let requestObject = try decoder.decode(PhotosSearchResponse.self, from: data)
                DispatchQueue.main.async {
                    completionHandler(requestObject, nil)
                }
                
            } catch {
                DispatchQueue.main.async {
                    completionHandler(nil, error)
                }
            }
            
        }
        task.resume()
    }
    
    //MARK: Constructing URL to the image according to Flickr's specification
    
    class func urlFromFlickrData(server: String, id: String, secret: String, farm: Int) -> URLComponents {
     
        var urlComp = URLComponents()
        
        urlComp.scheme = APIendpoints.FlickrEndpointValues.scheme
        urlComp.host = "farm\(farm).staticflickr.com"
        urlComp.path = "/\(server)/\(id)_\(secret).png"
        
        return urlComp
        
    }
    
    //MARK: Downloading pictures from the given url
    
    class func downloadPhotos(url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        var request = URLRequest(url: url)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let task = URLSession.shared.dataTask(with: request) {data, response, error in
            DispatchQueue.main.async {
                completionHandler(data, response, error)
            }
        }
        task.resume()
    }
    
}
