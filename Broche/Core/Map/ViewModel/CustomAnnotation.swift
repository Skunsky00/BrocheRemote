//
//  CustomAnnotation.swift
//  Broche
//
//  Created by Jacob Johnson on 7/25/23.
//

import MapKit

class VisitedLocationAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?

    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
        self.title = "Visited"
        // You can set other properties like subtitle, image, etc. as needed.
    }
}

class FutureVisitAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    var image: UIImage?

    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
        self.title = "Future Visit"
        self.image = UIImage(systemName: "airplane.departure")
        // You can set other properties like subtitle, image, etc. as needed.
    }
}

