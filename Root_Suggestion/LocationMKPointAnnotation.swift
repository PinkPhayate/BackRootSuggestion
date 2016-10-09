//
//  LocationMKPointAnnotation.swift
//  Root_Suggestion
//
//  Created by Tanaka Hayate on 10/9/16.
//  Copyright © 2016 Tanaka Hayate. All rights reserved.
//

import UIKit
import MapKit

class LocationMKPointAnnotation: MKPointAnnotation {
    var locationId = ""
    var name = ""
    var details = ""
    var formatted_phone_number = ""
    var lat: String = ""
    var lng: String = ""
    var can_check_in = ""
    var url = ""
    var address = ""
    var city = ""
    var state = ""
    var zip = ""
    var country = ""
    var aria_id = ""
    var users_count = ""
    var distance = ""
    var sensor_radius = ""
    override init() {
    }
}

