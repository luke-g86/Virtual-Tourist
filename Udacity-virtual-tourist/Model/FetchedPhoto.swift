//
//  FetchedPhoto.swift
//  Udacity-virtual-tourist
//
//  Created by Lukasz on 15/07/2019.
//  Copyright © 2019 Lukasz. All rights reserved.
//

import Foundation

struct FetchedPhoto: Codable {
    
    let id: String
    let owner: String
    let secret: String
    let server: String
    let farm: String
    let title: String
    let isPublic: Int
    let isFriend: Int
    let isFamily: Int
    
    enum CodingKeys: String, CodingKey {
        case id, owner, secret, server, farm, title
        case isPublic = "ispublic"
        case isFriend = "isfriend"
        case isFamily = "isfamily"
    }
    
}
