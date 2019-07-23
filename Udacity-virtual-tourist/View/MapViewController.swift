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
    

    var selectedPin: MKAnnotation?
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let longTap = UILongPressGestureRecognizer(target: self, action: #selector(longTapRecognizer(sender:)))
        mapView.delegate = self
        mapView.addGestureRecognizer(longTap)
        
        setupFetchedResultsController()
        fetchPinToMap()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setupFetchedResultsController()
        fetchPinToMap()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        fetchedResultsController = nil
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
    
    //MARK: - Interaction with a map
    
    @objc func longTapRecognizer(sender: UIGestureRecognizer) {
        
        if sender.state == .began {
            let locationInView = sender.location(in: mapView)
            
            let pin = Pin(context: dataController.viewContext)
            pin.coordinates = mapView.convert(locationInView, toCoordinateFrom: mapView)
            pin.creationDate = Date()
            try? dataController.viewContext.save()
        
            downloadDataFromFlickr(coordinates: pin.coordinates)
        }
    }
    
    
    func fetchPinToMap() {
        guard let arrayOfPins = fetchedResultsController.fetchedObjects else { return }
        
        //        var annotation = MKPointAnnotation()
        //        guard let first = arrayOfPins.first?.coordinates else {return}
        //        annotation.coordinate = first
        //        mapView.addAnnotation(annotation)
        //
        for pin in arrayOfPins {
            let annotation = MKPointAnnotation()
            annotation.coordinate = pin.coordinates
            mapView.addAnnotation(annotation)
        }
    }
    
    // MARK: - Network connection
    
    func downloadDataFromFlickr(coordinates: CLLocationCoordinate2D) {
        
        let latitude = coordinates.latitude
        let longitude = coordinates.longitude
        
        APIConnection.getDataFromFlickr(longitude: longitude, latitude: latitude) { (photos, error) in
            
            guard let photos = photos else{
                print(error?.localizedDescription ?? "error")
                return
            }
//            for photo in photos {
//                print(photo.absoluteString)
//            }
            print(photos.count)
        }
        
        
    }
    
    // MARK: - Setting Fetched Results Controller
    
    func setupFetchedResultsController() {
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "pins")
        
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
        
    }
    
}

extension MapViewController: MKMapViewDelegate, NSFetchedResultsControllerDelegate {
    
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
        
        // TODO - selection from fetched data
        
        
        //        selectedPin = view.annotation!
        //        performSegue(withIdentifier: "showDetails", sender: nil)
    }
    
    
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        // update maps
        
        fetchPinToMap()
        
    }
    
}

