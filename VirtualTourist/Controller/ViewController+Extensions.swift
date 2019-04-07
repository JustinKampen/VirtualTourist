//
//  ViewController+Extensions.swift
//  VirtualTourist
//
//  Created by Justin Kampen on 4/5/19.
//  Copyright © 2019 Justin Kampen. All rights reserved.
//

import UIKit
import MapKit

extension UIViewController {
    
    // MARK: - Present Alert Message
    
    func alert(message: String, title: String = "") {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(OKAction)
        DispatchQueue.main.async {
            self.present(alertController, animated: true, completion: nil)
        }
    }
}

extension UIViewController: MKMapViewDelegate {
    
    // MARK: - MKMapViewDelegate
    
    public func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
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
