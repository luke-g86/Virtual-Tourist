//
//  Pin+Extentions.swift
//  Udacity-virtual-tourist
//
//  Created by Lukasz on 20/07/2019.
//  Copyright © 2019 Lukasz. All rights reserved.
//

import Foundation
import CoreData
import MapKit


extension Pin: MKAnnotation {
    public var coordinate: CLLocationCoordinate2D {
        set {
            latitude = newValue.latitude
            longitude = newValue.longitude
        }
        get {
            return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
    }
    

    public override func awakeFromInsert() {
        super.awakeFromInsert()
        creationDate = Date()
    }
    
    private func locationToName(location: CLLocationCoordinate2D, completionHandler: @escaping (CLPlacemark?, Error?) -> Void){
        let loc = CLLocation.init(latitude: location.latitude, longitude: location.longitude)
        CLGeocoder().reverseGeocodeLocation(loc, completionHandler: {(placemarks: [CLPlacemark]?, error: Error?) in
            guard let placemarks = placemarks else {
                print(error?.localizedDescription ?? "")
                completionHandler(nil, error)
                return
            }
            let placemark = placemarks[0]
            completionHandler(placemark, nil)
        })
    }
    
}
