//
//  Stub.swift
//  Root_Suggestion
//
//  Created by Tanaka Hayate on 10/8/16.
//  Copyright © 2016 Tanaka Hayate. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit

class Stub {
    class var GET_CURRENT_LOCATION_FROM_STUB: CLLocationCoordinate2D {
        let userLocation: CLLocationCoordinate2D = CLLocationCoordinate2DMake(35.662504,139.760234)
        return userLocation
    }
    class var GET_DESTINATION_LOCATION_FROM_STUB: CLLocationCoordinate2D {
        let userLocation: CLLocationCoordinate2D = CLLocationCoordinate2DMake(35.671049,139.764958)
        return userLocation
    }

}