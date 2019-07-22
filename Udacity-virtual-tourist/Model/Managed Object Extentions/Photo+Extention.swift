//
//  Photo+Extention.swift
//  Udacity-virtual-tourist
//
//  Created by Lukasz on 20/07/2019.
//  Copyright © 2019 Lukasz. All rights reserved.
//

import Foundation
import CoreData

extension Photo {
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        creationdate = Date()
    }
}

