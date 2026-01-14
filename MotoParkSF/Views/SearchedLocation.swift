//
//  SearchedLocation.swift
//  MotoParkSF
//
//  Created by David A. Shamma on 1/13/26.
//

import Foundation
import CoreLocation
import MapKit

struct SearchedLocation: Identifiable {
    let id = UUID()
    let name: String
    let address: String
    let coordinate: CLLocationCoordinate2D
    let phoneNumber: String?
    let mapItem: MKMapItem
}
