//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Justin Kampen on 3/27/19.
//  Copyright © 2019 Justin Kampen. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController, NSFetchedResultsControllerDelegate {
    
    // MARK: - Outlets and Properties
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var newCollectionButton: UIToolbar!
    
    var dataController: DataController!
    var fetchedResultsController: NSFetchedResultsController<Photo>!
    var pin: Pin!
    var photos: [Photo] = []
    var maxPages: Int?
    
    // MARK: - Setup FetchedResultsController
    
    func setupFetchedResultsController() {
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "pin == %@", self.pin)
        fetchRequest.predicate = predicate
        let sortDescriptor = NSSortDescriptor(key: "imageURL", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Life Cycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        collectionView.delegate = self
        collectionView.dataSource = self
        setupFetchedResultsController()
        displaySelectedPin(withSelectedPin: pin)
        setupCollectionViewSpacing()
    }
    
    @IBAction func newCollectionButtonTapped(_ sender: Any) {
        
    }
    
    func displaySelectedPin(withSelectedPin coordinates: Pin) {
        let annotation = MKPointAnnotation()
        annotation.coordinate.latitude = coordinates.latitude
        annotation.coordinate.longitude = coordinates.longitude
        let region = MKCoordinateRegion(center: annotation.coordinate, latitudinalMeters: 3000, longitudinalMeters: 3000)
        mapView.addAnnotation(annotation)
        mapView.setRegion(region, animated: true)
    }
    
    func getPhotos() {
        
    }
    
    func handlePhotoDataResponse(photos: Photo?, page: Int?, error: Error?) {
        if photos != nil {
            
        }
    }
    
    func emptyPhotoArray() {
        for photo in photos {
            dataController.viewContext.delete(photo)
            try? dataController.viewContext.save()
        }
    }
    
    func setupCollectionViewSpacing() {
        let space: CGFloat = 3.0
        let dimension: CGFloat = (view.frame.size.width - (2 * space)) / 3
        flowLayout.minimumInteritemSpacing = space
        flowLayout.itemSize = CGSize(width: dimension, height: dimension)
    }
    
}

// MARK: - MKMapViewDelegate

extension PhotoAlbumViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let identifier = "Annotation"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        if annotationView == nil {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView!.canShowCallout = true
        } else {
            annotationView?.annotation = annotation
        }
        return annotationView
    }
}

// MARK: - UICollectionViewDelegate, UICollectionViewDataSource

extension PhotoAlbumViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "flickrCollectionCell", for: indexPath) as! PhotoAlbumCollectionViewCell
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let photoToDelete = photos[indexPath.row]
        dataController.viewContext.delete(photoToDelete)
        try? dataController.viewContext.save()
        photos.remove(at: indexPath.row)
        collectionView.deleteItems(at: [indexPath])
    }
    

    
}
