//
//  PhotosSearchResponse.swift
//  Udacity-virtual-tourist
//
//  Created by Lukasz on 15/07/2019.
//  Copyright © 2019 Lukasz. All rights reserved.
//

import Foundation

struct PhotosSearchResponse: Codable {
    let photos: Photos
    let stat: String
}

struct Photos: Codable {
    let page: Int
    let pages: Int
    let perpage: Int
    let total: String
    let photo: [FetchedPhoto]
    
}
