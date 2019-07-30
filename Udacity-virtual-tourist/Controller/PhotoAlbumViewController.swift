//
//  PhotoAlbumViewController.swift
//  Udacity-virtual-tourist
//
//  Created by Lukasz on 19/07/2019.
//  Copyright © 2019 Lukasz. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var photosCollectionView: UICollectionView!
    @IBOutlet weak var refreshButton: UIButton!
    
    //MARK: Variables
    
    var pin: Pin!
    var dataController: DataController!
    var fetchedResultsController: NSFetchedResultsController<Photo>!
    var blockOperation: [BlockOperation] = []
    
    
    
    //MARK: View Controller setup
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Fetched pictures from Flickr"
        
    
  
        
        setupFetchedResultsController()
        downloadPictures()
        setupCollectionView()
        
        setupMap()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        fetchedResultsController = nil
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setupFetchedResultsController()
    }


    //MARK: CollectionView setup method
    func setupCollectionView() {
        photosCollectionView.delegate = self
        photosCollectionView.collectionViewLayout = CollectionViewFlow()
        photosCollectionView.register(PhotosCollectionViewCell.self, forCellWithReuseIdentifier: "photoCell")
        photosCollectionView.backgroundColor = UIColor.white
        photosCollectionView.reloadData()
    }
    
    //MARK: CoreData setup method
    func setupFetchedResultsController() {
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "pin == %@", pin)
        fetchRequest.predicate = predicate
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "\(pin.creationDate)-photos")
        
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    //MARK: - Network connection
    
    
    //MARK: Downloading pictures from flickr
    func downloadPictures() {
        try? fetchedResultsController.performFetch()
        guard let arrayOfPhotos = fetchedResultsController.fetchedObjects else { return }
        
        for photo in arrayOfPhotos {
            if photo.image == nil {
                APIConnection.downloadPhotos(url: photo.imageURL!) { (data, response, error) in
                    DispatchQueue.main.async {
                        guard let data = data else {
                            print(error?.localizedDescription ?? "other error")
                            return
                        }
                        photo.image = data
                    }
                }
            }
        }
    }
    
    //MARK: Refresh button. Downloading images URLs and saving to the database
    @IBAction func getNewPhotos(sender: Any?) {
        
        // downloading new pictures
        try? fetchedResultsController.performFetch()
        guard let arrayOfPhotos = fetchedResultsController.fetchedObjects else {return}
        
        if arrayOfPhotos.count != 0 {
            for photo in arrayOfPhotos {
                dataController.viewContext.delete(photo)
            }
            try? dataController.viewContext.save()
            dataController.viewContext.refreshAllObjects()
            
            print(arrayOfPhotos.count)
        }
        
        let latitude = pin.coordinate.latitude
        let longitude = pin.coordinate.longitude
        
        // If pin does not have maxPages count yet or maxPages count is less than 2
        var page: Int32
        if pin.maxPages < 2 {
            page = 1
        } else {
            page = Int32.random(in: 1..<pin.maxPages)
            
        }
        
        APIConnection.getDataFromFlickr(longitude: longitude, latitude: latitude, page: page) { (photoResponse, error) in
            DispatchQueue.main.async {
                guard let photoResponse = photoResponse else {
                    print(error?.localizedDescription ?? "unknown error")
                    return
                }
                self.pin.maxPages = Int32(photoResponse.photos.pages)
                for url in photoResponse.photos.photo {
                    let photo = Photo(context: self.dataController.viewContext)
                    photo.creationDate = Date()
                    
                    //MARK: Constructing URL
                    photo.imageURL = APIConnection.urlFromFlickrData(server: url.server, id: url.id, secret: url.secret, farm: url.farm).url
                    photo.pin = self.pin
                    
                }
                try? self.dataController.viewContext.save()
                self.downloadPictures()
            }
            
        }
    }
    
    //MARK: - Map set up
    
    //MARK: Set annotation and map bahavior
    
    func setupMap() {
        mapView.delegate = self
        let annotation = MKPointAnnotation()
        annotation.coordinate = pin.coordinate
        
        
        locationToName(location: pin.coordinate) { (location, error) in
            DispatchQueue.main.async {
                guard let location = location else {
                    print(error?.localizedDescription ?? "unknown error")
                    return
                }
                let stringArr = String(describing: location)
                let separated = stringArr.components(separatedBy: ",")
                
                annotation.title = separated[0]
                annotation.subtitle = separated[2]
                
                self.mapView.addAnnotation(annotation)
                let region = MKCoordinateRegion(center: self.pin.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2))
                self.mapView.setRegion(region, animated: true)
                self.mapView.selectAnnotation(annotation, animated: true)
            }
        }
        mapView.isUserInteractionEnabled = false
    }
    
    //MARK: Convert selection to address
    
    func locationToName(location: CLLocationCoordinate2D, completionHandler: @escaping (CLPlacemark?, Error?) -> Void){
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

// MARK: - Extentions

extension PhotoAlbumViewController: MKMapViewDelegate, NSFetchedResultsControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate {
    
    //MARK: CollectionView settings
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.fetchedObjects?.count ?? 0
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let photo = fetchedResultsController.object(at: indexPath)
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as! PhotosCollectionViewCell
        
        cell.imageView.image = UIImage(named: "placeholder")
        
        if let data = photo.image {
            cell.imageView.image = UIImage(data: data)
            
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let photoToDelete = fetchedResultsController.object(at: indexPath)
        print(photoToDelete)
        dataController.viewContext.delete(photoToDelete)
        
        try? dataController.viewContext.save()
        
        return
    }
    
    //MARK: MapKit settings
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        guard annotation is MKPointAnnotation else { print("no mkpointannotaions"); return nil }
        
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.centerOffset = CGPoint(x: 0, y: 1000)
            pinView!.tintColor = .red
            pinView!.animatesDrop = true
            pinView!.canShowCallout = true
            pinView!.rightCalloutAccessoryView = UIButton(type: .system)
            
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }

    
    //MARK: CoreData settings
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        blockOperation.removeAll(keepingCapacity: false)
    }
    
    //MARK: Controller with set block operations put in a queue
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch type {
        case .insert: blockOperation.append(BlockOperation(block: {[weak self] in
            if let this = self {
                this.photosCollectionView.insertItems(at: [newIndexPath!])
            }
        })
            )
            
        case .update: blockOperation.append(BlockOperation(block: {
            [weak self] in
            if let this = self {
                this.photosCollectionView.reloadItems(at: [indexPath!])
            }
        }))
            
        case .move: blockOperation.append(BlockOperation(block: {
            [weak self] in
            if let this = self {
                this.photosCollectionView.moveItem(at: indexPath!, to: newIndexPath!)
            }
        }))
        case .delete: blockOperation.append(BlockOperation(block: {
            [weak self] in
            if let this = self {
                this.photosCollectionView.deleteItems(at: [indexPath!])
            }
        }))
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        photosCollectionView.performBatchUpdates({ () -> Void in
            for operation: BlockOperation in self.blockOperation {
                operation.start()
            }
        }) { (finished) -> Void in
            self.blockOperation.removeAll(keepingCapacity: false)
        }
    }
    
}
