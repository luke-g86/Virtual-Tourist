//
//  MapViewController.swift
//  Udacity-virtual-tourist
//
//  Created by Lukasz on 16/07/2019.
//  Copyright © 2019 Lukasz. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import CoreData


class MapViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    
    var dataController: DataController!
    var fetchedResultsController: NSFetchedResultsController<Pin>!
    
    var userPins = [MKPointAnnotation]()
    var selectedPin: MKAnnotation?
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let longTap = UILongPressGestureRecognizer(target: self, action: #selector(longTapRecognizer(sender:)))
        mapView.delegate = self
        mapView.addGestureRecognizer(longTap)
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetails" {
            if let vc = segue.destination as? PhotoAlbumViewController {
                if let pin = selectedPin {
                    vc.mapView.addAnnotation(pin)
                    print(pin)
                }
            }
        }
    }
    
    @objc func longTapRecognizer(sender: UIGestureRecognizer) {
        
        if sender.state == .began {
            let locationInView = sender.location(in: mapView)
            let locationOnMap = mapView.convert(locationInView, toCoordinateFrom: mapView)
            
            let pin = MKPointAnnotation()
            pin.coordinate = locationOnMap
            
            userPins.append(pin)
            mapView.addAnnotations(userPins)
            
            APIConnection.getPhotosFromFlickr()
        }
        
    }
    
    func addLocationToTheMap(location: CLLocationCoordinate2D) {
        
        mapView.removeAnnotations(userPins)
        
    }
    
}

extension MapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.tintColor = .red
            pinView!.animatesDrop = true
            pinView!.canShowCallout = true
            pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if control == view.rightCalloutAccessoryView {
            let app = UIApplication.shared
            if let toOpen = view.annotation?.subtitle! {
                performSegue(withIdentifier: "showDetails", sender: nil)
            }
        }
    }
//
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        selectedPin = view.annotation!
        performSegue(withIdentifier: "showDetails", sender: nil)
    }
    }

