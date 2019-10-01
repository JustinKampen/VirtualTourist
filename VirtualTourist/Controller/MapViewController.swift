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
        let location = sender.location(in: mapView)
        let locCoord = mapView.convert(location, toCoordinateFrom: mapView)
        let pinAnnotation = MKPointAnnotation()
        
        if sender.state == .began {
            pinAnnotation.coordinate = locCoord
            print("\(#function) Coordinate: \(locCoord.latitude),\(locCoord.longitude)")
            mapView.addAnnotation(pinAnnotation)
        } else if sender.state == .changed {
            print("changed")
            pinAnnotation.coordinate = locCoord
        } else if sender.state == .ended {
            print("ended")
            let pin = Pin(context: dataController.viewContext)
            pin.creationDate = Date()
            pin.latitude = locCoord.latitude
            pin.longitude = locCoord.longitude
            print(pin.latitude)
            print(pin.longitude)
            try? dataController.viewContext.save()
        }
    }
    
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
