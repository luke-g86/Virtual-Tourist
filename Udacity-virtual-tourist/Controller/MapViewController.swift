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
    
    
    //MARK: - View's behavior
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Drop a Pin to fetch pictures"
        
        mapSetup()
        setupFetchedResultsController()

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
                vc.dataController = dataController
                vc.pin = sender as? Pin
            }
        }
    }
    
    //MARK: - Interaction with a map
    
    //MARK: Map set up
    
    func mapSetup() {
        let longTap = UILongPressGestureRecognizer(target: self, action: #selector(longTapRecognizer(sender:)))
        mapView.delegate = self
        mapView.addGestureRecognizer(longTap)
    }
    
    @objc func longTapRecognizer(sender: UIGestureRecognizer) {
        
        if sender.state == .began {
            let locationInView = sender.location(in: mapView)
            
            let pin = Pin(context: dataController.viewContext)
            pin.coordinate = mapView.convert(locationInView, toCoordinateFrom: mapView)
            pin.creationDate = Date()
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = pin.coordinate
            mapView.addAnnotation(annotation)
            
            downloadDataFromFlickr(pin: pin)
            
            do {
                try dataController.viewContext.save()
                print("saving")
            } catch {
                print("error in saving")
            }
            
        }
    }
    
    //MARK: Updating map by placing pins

    func fetchPinToMap() {
        
        guard let arrayOfPins = fetchedResultsController.fetchedObjects else {
            print("error")
            return
        }
        if mapView.annotations.count < arrayOfPins.count {
            for pin in arrayOfPins {
                let geoAnnotation = MKPointAnnotation()
                geoAnnotation.coordinate = pin.coordinate
                self.mapView.addAnnotation(geoAnnotation)
            }
        }
    }

    
    // MARK: - Network connection
    
    func downloadDataFromFlickr(pin: Pin) {
        
        var page: Int32
     
        let latitude = pin.coordinate.latitude
        let longitude = pin.coordinate.longitude
        
        // If pin does not have maxPages count yet or maxPages count is less than 2
        
        if pin.maxPages < 2 {
            page = 1
        } else {
            page = Int32.random(in: 1..<pin.maxPages)
        }
        
        //MARK: Connection with the Flickr API
        
        APIConnection.getDataFromFlickr(longitude: longitude, latitude: latitude, page: page) { (fetchedData, error) in
            
            guard let fetchedData = fetchedData else{
                print(error?.localizedDescription ?? "error")
                return
            }
            
            // For randomly selected page, URLs are being downloaded, parsed and saved for each photo.
            // As user can drop multiple pins, actual photos are not downloaded yet.
            
            pin.maxPages = Int32(fetchedData.photos.pages)
            for url in fetchedData.photos.photo {
                let photo = Photo(context: self.dataController.viewContext)
                photo.creationDate = Date()
          
                //MARK: Constructing URL
                photo.imageURL = APIConnection.urlFromFlickrData(server: url.server, id: url.id, secret: url.secret, farm: url.farm).url
                
                photo.pin = pin
            }
            do {
                try self.dataController.viewContext.save()
            } catch {
                print(error.localizedDescription)
            }
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

//MARK: - Extentions

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

    // Filter selected pin and perform segue to the new view controller.
    // selected pin is being deselected to assure its responsiveness next time.
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        guard let pins = fetchedResultsController.fetchedObjects else { return}
        let pin = pins.filter{$0.coordinate.latitude == view.annotation!.coordinate.latitude && $0.coordinate.longitude == view.annotation!.coordinate.longitude}.first

        performSegue(withIdentifier: "showDetails", sender: pin)
        
            let selectedAnnotations = mapView.selectedAnnotations
            for annotation in selectedAnnotations {
                mapView.deselectAnnotation(annotation, animated: false)
            }
        }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        // update maps
        fetchPinToMap()
    }
}

