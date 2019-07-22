//
//  APIconnection.swift
//  Udacity-virtual-tourist
//
//  Created by Lukasz on 22/07/2019.
//  Copyright © 2019 Lukasz. All rights reserved.
//

import Foundation

class APIConnection {
    
    static let lat: Double = 37.76007833
    static let lon: Double = -122.50956667
    
    class func getDataFromFlickr() {
        
        let createdURL = APIendpoints.constructURL(latitude: lat, longitute: lon).url
        
        print("created url: \(createdURL)")
        
        let task = URLSession.shared.dataTask(with: createdURL!) { (data, response, error) in
            
            guard let data = data else {
                print(error?.localizedDescription ?? "error")
                return
            }
            let decoder = JSONDecoder()
            do {
                let requestObject = try decoder.decode(PhotosSearchResponse.self, from: data)
                    print("response =====")
                print(requestObject.photos.photo.count)
                for photoURL in requestObject.photos.photo {
                    let url = urlFromFlickrData(server: photoURL.server, id: photoURL.id, secret: photoURL.secret, farm: photoURL.farm).url.
                }
                
            } catch {
                print(error.localizedDescription)
            }
            
        }
        task.resume()
        
    }
    
    class func urlFromFlickrData(server: String, id: String, secret: String, farm: Int) -> URLComponents {
     
        var urlComp = URLComponents()
        
        urlComp.scheme = APIendpoints.FlickrEndpointValues.scheme
        urlComp.host = "farm\(farm).staticflickr.com"
        urlComp.path = "/\(server)/\(id)_\(secret).png"
        
        return urlComp
        
    }
    
}
