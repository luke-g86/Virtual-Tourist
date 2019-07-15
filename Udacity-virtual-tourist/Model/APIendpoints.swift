//
//  APIendpoints.swift
//  Udacity-virtual-tourist
//
//  Created by Lukasz on 15/07/2019.
//  Copyright © 2019 Lukasz. All rights reserved.
//

import Foundation

class APIendpoints {
    
    struct APIStruct {
        static let key = "4afb415cd8b1924e93014c604b3ed5fe"
        static let secret = "9fdfd0b07058d6db"
        
        private init() {}
    }
    
    
    
    
    enum Endpoints {
        
        static let base = "https://www.flickr.com/services/rest/?method="
        
        case photoSearch
        
        var urlBody: String {
            switch self {
            case .photoSearch: return APIendpoint.base + "flickr.photos.search&api_key=" + APIStruct.key
            }
        }
        
    }
    
    
    
    
    
}
