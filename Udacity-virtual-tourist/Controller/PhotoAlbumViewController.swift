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
    
    var pin: Pin!
    var dataController: DataController!
    var fetchedResultsController: NSFetchedResultsController<Photo>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        photosCollectionView.delegate = self
        mapView.delegate = self
        
        setupFetchedResultsController()
        setupCollectionView()
        
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = pin.coordinate
        
        let fetched = fetchedResultsController.fetchedObjects
        let photo = Photo(context: dataController.viewContext)
    }
    
    func setupCollectionView() {
        
        let width = (view.frame.width - 25) / 3
        let layout = photosCollectionView.collectionViewLayout as! UICollectionViewFlowLayout
        layout.itemSize = CGSize(width: width, height: width)
        photosCollectionView.backgroundColor = UIColor.lightGray
        photosCollectionView.reloadData()
    }
    
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
    
}

// MARK: - Extentions

extension PhotoAlbumViewController: MKMapViewDelegate, NSFetchedResultsControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate {
    
    //MARK: - CollectionView settings
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.fetchedObjects?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let photo = fetchedResultsController.object(at: indexPath)
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as! PhotosCollectionViewCell
        
        cell.imageView.image = UIImage(named: "placeholder")
        
        if let url = photo.imageURL {
            APIConnection.downloadPhotos(url: url) { (data, response, error) in
                guard let data = data else {
                    print(error?.localizedDescription ?? "error")
                    return
                }
                cell.imageView.image = UIImage(data: data)
            }
        }
        
        let photos = fetchedResultsController.fetchedObjects
        
        
        return cell
    }
    
    
    //Mark: - MapKit settings
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.tintColor = .red
            pinView!.animatesDrop = true
            pinView!.canShowCallout = true
            pinView!.rightCalloutAccessoryView = UIButton(type: .infoDark)
            print(pinView!.annotation?.coordinate)
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    //Mark: - CoreData settings
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
        
    }
    
    
}
