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
    
    var pin: Pin!
    var dataController: DataController!
    var fetchedResultsController: NSFetchedResultsController<Photo>!
    
    private var hiddenCells: [PhotosCollectionViewCell] = []
    private var expandedCell: PhotosCollectionViewCell?
    private var isStatusBarHidden = false
    var blockOperation: [BlockOperation] = []
    
    override var prefersStatusBarHidden: Bool {
        return isStatusBarHidden
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
        photosCollectionView.delegate = self
        photosCollectionView.collectionViewLayout = CollectionViewFlow()
        mapView.delegate = self
        
        setupFetchedResultsController()
        downloadPictures()
        setupCollectionView()
        
        
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = pin.coordinate
        
        let fetched = fetchedResultsController.fetchedObjects
        let photo = Photo(context: dataController.viewContext)
    }
    
    func setupCollectionView() {
        photosCollectionView.register(PhotosCollectionViewCell.self, forCellWithReuseIdentifier: "photoCell")
        photosCollectionView.backgroundColor = UIColor.white
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
                    print(photo.imageURL)
                  
                }
                try? self.dataController.viewContext.save()
                self.downloadPictures()
            }
        
        }
        
    }
    
}

    // MARK: - Extentions

    extension PhotoAlbumViewController: MKMapViewDelegate, NSFetchedResultsControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate {
        
        //MARK: - CollectionView settings
        
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
        
        func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
            blockOperation.removeAll(keepingCapacity: false)
        }
        
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
        
//            }
//
//            if let indexPath = indexPath, type == .delete {
//                photosCollectionView.deleteItems(at: [indexPath])
//                return
//            }
//
//            if let indexPath = indexPath, type == .insert {
//                photosCollectionView.insertItems(at: [indexPath])
//                return
//            }
//
//            if let newIndexPath = newIndexPath, let oldIndexPath = indexPath, type == .move {
//                photosCollectionView.moveItem(at: oldIndexPath, to: newIndexPath)
//                return
//            }
//
//            if type != .update {
//                photosCollectionView.reloadData()
//            }
        

//        func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
//
//            let indexSet = IndexSet(integer: sectionIndex)
//
//            switch type {
//            case .insert: photosCollectionView.insertSections(indexSet)
//            case .delete: photosCollectionView.deleteSections(indexSet)
//            case .update: photosCollectionView.reloadData()
//            default:
//                fatalError("error")
//            }
//        }
        
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
