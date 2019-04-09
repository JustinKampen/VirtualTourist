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
    @IBOutlet weak var newCollectionButton: UIBarButtonItem!
    
    
    var dataController: DataController!
    var fetchedResultsController: NSFetchedResultsController<Photo>!
    var pin: Pin!
    var maxPages: Int?
    var imagePool: [FlickrURL] = []
    var photoArray: [Photo] = []
    
    // MARK: - Setup FetchedResultsController
    
    func setupFetchedResultsController() {
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "pin == %@", self.pin)
        fetchRequest.predicate = predicate
        let sortDescriptor = NSSortDescriptor(key: "imageURL", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "pin")
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            alert(message: "Could not load saved images")
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Life Cycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupFetchedResultsController()
        collectionView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        newCollectionButton.isEnabled = false
        mapView.delegate = self
        collectionView.delegate = self
        collectionView.dataSource = self
        setupFetchedResultsController()
        displaySelectedPin(withSelectedPin: pin)
        setupCollectionViewSpacing()
        photoArray = fetchedResultsController.fetchedObjects ?? []

        if photoArray.isEmpty {
            FlickrClient.getPhotosForLocation(latitude: String(pin.latitude), longitude: String(pin.longitude), page: 1, completion: handlePhotoDataResponse(photos:page:error:))
        }
        print("PIN LAT:  \(pin.latitude)")
        print("PIN LON:  \(pin.longitude)")
    }
    
    @IBAction func newCollectionButtonTapped(_ sender: Any) {
        emptyPhotoArray()
        PhotoPool.photo = []
        photoArray = []
        setupFetchedResultsController()
        collectionView.reloadInputViews()
        
        let photoPage = Int.random(in: 1...20)
        newCollectionButton.isEnabled = false
        FlickrClient.getPhotosForLocation(latitude: String(pin.latitude), longitude: String(pin.longitude), page: photoPage, completion: handlePhotoDataResponse(photos:page:error:))
    }
    
    func displaySelectedPin(withSelectedPin coordinates: Pin) {
        let annotation = MKPointAnnotation()
        annotation.coordinate.latitude = coordinates.latitude
        annotation.coordinate.longitude = coordinates.longitude
        let region = MKCoordinateRegion(center: annotation.coordinate, latitudinalMeters: 3000, longitudinalMeters: 3000)
        mapView.addAnnotation(annotation)
        mapView.setRegion(region, animated: true)
    }
    
    func getImageURL() {
        for photo in imagePool {
            let flickrPhoto = Photo(context: dataController.viewContext)
            flickrPhoto.imageURL = photo.url_n
            flickrPhoto.pin = pin
            photoArray.append(flickrPhoto)
        }
        try? dataController.viewContext.save()
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }
    
    func handlePhotoDataResponse(photos: FlickrImage?, page: Int?, error: Error?) {
        guard let photos = photos else {
            alert(message: "There was an error loading the images")
            return
        }
        imagePool = photos.photo
        maxPages = min(page!, 4000/30)
        getImageURL()
        newCollectionButton.isEnabled = true
    }
    
    func emptyPhotoArray() {
        for photo in photoArray {
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

// MARK: - UICollectionViewDelegate, UICollectionViewDataSource

extension PhotoAlbumViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photoArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "flickrCollectionCell", for: indexPath) as! PhotoAlbumCollectionViewCell
        let cellImage = photoArray[indexPath.row]
        
        if cellImage.imageData != nil {
            cell.imageView.image = UIImage(data: cellImage.imageData!)
            cell.activityIndicator.stopAnimating()
            newCollectionButton.isEnabled = true
        } else {
            if cellImage.imageURL != nil {
                let url = URL(string: cellImage.imageURL!)!
                cell.activityIndicator.startAnimating()
                
                FlickrClient.downloadPhoto(url: url) { (data, error) in
                    guard let data = data else {
                        self.alert(message: "There was an error loading the images")
                        return
                    }
                    cellImage.imageData = data
                    cellImage.pin = self.pin
                    try? self.dataController.viewContext.save()
                    DispatchQueue.main.async {
                        cell.imageView.image = UIImage(data: data)
                        cell.setNeedsLayout()
                        cell.activityIndicator.stopAnimating()
                    }
                }
            } else {
                cell.activityIndicator.stopAnimating()
            }
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let photoToDelete = photoArray[indexPath.row]
        dataController.viewContext.delete(photoToDelete)
        try? dataController.viewContext.save()
        photoArray.remove(at: indexPath.row)
        collectionView.deleteItems(at: [indexPath])
    }
}
