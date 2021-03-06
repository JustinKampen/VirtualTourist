//
//  MapViewController.swift
//  VirtualTourist
//
//  Created by Justin Kampen on 3/27/19.
//  Copyright © 2019 Justin Kampen. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, NSFetchedResultsControllerDelegate {
    
    // MARK: - Outlets and Properties
    
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var deletePinsView: UIView!
    
    var dataController: DataController!
    var fetchedResultsController: NSFetchedResultsController<Pin>!
    var pins: [Pin] = []
    var pinSelected: Pin?
    var editState = false
    
    // MARK: - Setup FetchedResultsController
    
    func setupFetchedResultsController() {
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
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
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = editButtonItem
        deletePinsView.isHidden = true
        mapView.delegate = self
        setupFetchedResultsController()
        loadSavedPins()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        fetchedResultsController = nil
    }
    
    // MARK: - Setup MapView and Pins
    
    func loadSavedPins() {
        for pin in fetchedResultsController.fetchedObjects ?? [] {
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
            mapView.addAnnotation(annotation)
            pins.append(pin)
        }
    }
    
    @IBAction func mapViewPressed(_ sender: UILongPressGestureRecognizer) {
        let pressPoint = mapView.convert(sender.location(in: mapView), toCoordinateFrom: mapView)
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: pressPoint.latitude, longitude: pressPoint.longitude)
        if sender.state == .began {
            // add a PIN to the map
            annotation.coordinate = CLLocationCoordinate2D(latitude: pressPoint.latitude, longitude: pressPoint.longitude)
        } else if sender.state == .changed {
            // update the PIN to the new location
            annotation.coordinate = CLLocationCoordinate2D(latitude: pressPoint.latitude, longitude: pressPoint.longitude)
        } else if sender.state == .ended {
            // save this PIN to CoreData
            mapView.addAnnotation(annotation)
            print(pressPoint.latitude)
            print(pressPoint.longitude)
            let pin = Pin(context: dataController.viewContext)
            pin.creationDate = Date()
            pin.latitude = pressPoint.latitude
            pin.longitude = pressPoint.longitude
            try? dataController.viewContext.save()
        }
    }
    
    func addPinToLocation(withCoordinates coordinates: CLLocationCoordinate2D) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: coordinates.latitude, longitude: coordinates.longitude)
        mapView.addAnnotation(annotation)
    }
    
    
    
//    func addPinLocation(withCoordinates coordinates: CLLocationCoordinate2D) {
//        let annotation = MKPointAnnotation()
//        annotation.coordinate = CLLocationCoordinate2D(latitude: coordinates.latitude, longitude: coordinates.longitude)
//        mapView.addAnnotation(annotation)
//        let pin = Pin(context: dataController.viewContext)
//        pin.creationDate = Date()
//        pin.latitude = coordinates.latitude
//        pin.longitude = coordinates.longitude
//        try? dataController.viewContext.save()
//    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: true)
        if editing {
            deletePinsView.isHidden = false
            editState = true
        } else {
            deletePinsView.isHidden = true
            editState = false
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let controller = segue.destination as! PhotoAlbumViewController
        controller.dataController = dataController
        controller.pin = pinSelected
    }
}

// MARK: - MKMapViewDelegate

extension MapViewController {
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        let pinTapped = view.annotation as? MKPointAnnotation
        let pinTappedCoordinates = pinTapped!.coordinate
        setupFetchedResultsController()
        pins = fetchedResultsController.fetchedObjects ?? []
        for pin in pins {
            if pin.latitude == pinTappedCoordinates.latitude && pin.longitude == pinTappedCoordinates.longitude {
                if editState {
                    mapView.removeAnnotation(pinTapped!)
                    dataController.viewContext.delete(pin)
                    try? dataController.viewContext.save()
                    break
                } else {
                    pinSelected = pin
                    performSegue(withIdentifier: "showPhotosForPin", sender: nil)
                    break
                }
            }
        }
    }
}
