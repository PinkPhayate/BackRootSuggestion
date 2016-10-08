//
//  ViewController.swift
//  Root_Suggestion
//
//  Created by Tanaka Hayate on 10/7/16.
//  Copyright © 2016 Tanaka Hayate. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate, UISearchBarDelegate {
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var mySearchBar: UISearchBar!
    var currentLocationButton: UIButton! = nil
    var locationManager: CLLocationManager?
    var userLocation: CLLocationCoordinate2D!
    var destLocation: CLLocationCoordinate2D!
    var source:MKMapItem?
    var destination:MKMapItem?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Unable Cancel button
        self.mySearchBar.showsCancelButton = true
        // Disable Bookmark button
        self.mySearchBar.showsBookmarkButton = false
        // set searchBar Style => Default
        self.mySearchBar.searchBarStyle = UISearchBarStyle.Default
        self.mySearchBar.delegate = self
        self.mySearchBar.placeholder = "Please enter your destination"
        self.mySearchBar.text = "新橋駅"

//        self.mySearchBar.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.tapScreen(_:))))
        self.mapView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.tapScreen(_:))))
        self.view.addSubview(mySearchBar)

        
        self.locationManager = CLLocationManager()
        self.locationManager!.delegate = self
        mapView.delegate = self

        // 位置情報取得の許可状況を確認
        let status = CLLocationManager.authorizationStatus()
        if(status == CLAuthorizationStatus.NotDetermined) {
            Logger.debug("didChangeAuthorizationStatus:\(status)");
            self.locationManager!.requestAlwaysAuthorization()
        }

        // Accuracy about locationManager
        self.locationManager!.desiredAccuracy = kCLLocationAccuracyBest
        //位置情報取得間隔(m)
        self.locationManager!.distanceFilter = 300
        self.locationManager?.startUpdatingLocation()
        self.mapView.removeAnnotations(self.mapView.annotations)

        /**Current Location Button*/
        self.currentLocationButton = UIButton( frame:CGRectMake(self.view.frame.size.width-90,self.view.frame.size.height-100,80,80) )
        self.currentLocationButton.setImage( UIImage(named: "here"), forState: UIControlState.Normal)
        self.currentLocationButton.addTarget(self, action: #selector(self.pushCurrentLocationButton(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        self.view.addSubview(self.currentLocationButton)

    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    //MARK: Map
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        userLocation = CLLocationCoordinate2DMake(manager.location!.coordinate.latitude, manager.location!.coordinate.longitude)

        Logger.info("\(userLocation.latitude), \(userLocation.longitude)")
        
//        let userLocAnnotation: MKPointAnnotation = MKPointAnnotation()
//        userLocAnnotation.coordinate = userLocation
//        userLocAnnotation.title = "Current Point"
//        mapView.addAnnotation(userLocAnnotation)

        Logger.debug("Success to get current location data")
    }
    
    func locationManager(manager: CLLocationManager,didFailWithError error: NSError){
        Logger.error("locationManager error")
    }
    
    //MARK: Drawing Map
    // 経路を描画するときの色や線の太さを指定
    func getRoute(dest: CLLocationCoordinate2D) {
        let request = MKDirectionsRequest()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: self.userLocation, addressDictionary: nil))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: dest, addressDictionary: nil))
        request.requestsAlternateRoutes = true
        request.transportType = .Walking
        
        let directions = MKDirections(request: request)
        directions.calculateDirectionsWithCompletionHandler{
            response, error in
            
            guard let response = response else {
                //handle the error here
                Logger.error("COULD NOT FIND ANY ROOT")
                return
            }
            let route: MKRoute = response.routes[0] as MKRoute
            self.mapView.addOverlay(route.polyline)
            self.showCurrentLocAndDestinationOnMap()
        }
    }
    
    func mapView( mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(polyline: overlay as! MKPolyline)
        
        renderer.strokeColor = UIColor.blueColor()
        return renderer
    }


    // 地図の表示範囲を計算
    func showCurrentLocAndDestinationOnMap() {
        // 現在地と目的地を含む矩形を計算
        let maxLat:Double = fmax(self.userLocation.latitude,  self.destLocation.latitude)
        let maxLon:Double = fmax(self.userLocation.longitude, self.destLocation.longitude)
        let minLat:Double = fmin(self.userLocation.latitude,  self.destLocation.latitude)
        let minLon:Double = fmin(self.userLocation.longitude, self.destLocation.longitude)
        
        // 地図表示するときの緯度、経度の幅を計算
        let mapMargin:Double = 3.0
        let leastCoordSpan:Double = 0.005;    // 拡大表示したときの最大値
        let span_x:Double = fmax(leastCoordSpan, fabs(maxLat - minLat) * mapMargin);
        let span_y:Double = fmax(leastCoordSpan, fabs(maxLon - minLon) * mapMargin);
        
        let span:MKCoordinateSpan = MKCoordinateSpanMake(span_x, span_y);
        
        // Map Center is average of curr and dest
        let center:CLLocationCoordinate2D = CLLocationCoordinate2DMake((maxLat + minLat) / 2, (maxLon + minLon) / 2);
        let region:MKCoordinateRegion = MKCoordinateRegionMake(center, span)
        // Map Center is current location
//        let region:MKCoordinateRegion = MKCoordinateRegionMake(self.userLocation, span)
        
        mapView.setRegion(mapView.regionThatFits(region), animated:true);
    }
    
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        let route: MKPolyline = overlay as! MKPolyline
        let routeRenderer = MKPolylineRenderer(polyline:route)
        routeRenderer.lineWidth = 5.0
        routeRenderer.strokeColor = UIColor.blueColor()
        return routeRenderer
    }
    func buttonTapped(overray: MKPolylineRenderer) {
        //Button Tapped
    }
    
    //MARK: SearchBar
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        self.mySearchBar.resignFirstResponder()
        // セット済みのピンを削除
        self.mapView.removeAnnotations(self.mapView.annotations)
        // 描画済みの経路を削除
        self.mapView.removeOverlays(self.mapView.overlays)
        
        // Search lat and lng of your destination
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(self.mySearchBar.text!, completionHandler: {(placemarks: [CLPlacemark]?, error: NSError?) -> Void in

            // Could not find your distination
            if error != nil {
                Logger.error("REVERSE GEOCODER FAILED WITH ERROR")
                return
            }
            // Success
            let placemark = placemarks![0]
            Logger.info("\(placemark.location!.coordinate.latitude), \(placemark.location!.coordinate.longitude)")
            self.destLocation = CLLocationCoordinate2DMake( placemark.location!.coordinate.latitude, placemark.location!.coordinate.longitude)
            self.showCurrentLocAndDestinationOnMap()
//            self.mySearchBar.hidden = true
            self.getRoute( self.destLocation )
        })
    }
    func tapScreen(searchBar: UISearchBar) {
//        if self.mySearchBar.hidden {
//            self.mySearchBar.hidden = false
//            return
//        }
//            self.mySearchBar.hidden = true
    }
    func handleKeyboardWillShowNotification(notification: NSNotification) {
        self.mySearchBar.showsCancelButton = true
    }
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchBar.showsCancelButton = false
        searchBar.resignFirstResponder()
    }

    @IBAction func pushCurrentLocationButton(sender: AnyObject) {
        // 現在地と目的地を含む矩形を計算
        if self.userLocation == nil || self.destLocation == nil {
            // Map Center is current location
//            let region:MKCoordinateRegion = MKCoordinateRegionMake(self.userLocation)
//            mapView.setRegion(mapView.regionThatFits(region), animated:true);

            return
        }
        let maxLat:Double = fmax(self.userLocation.latitude,  self.destLocation.latitude)
        let maxLon:Double = fmax(self.userLocation.longitude, self.destLocation.longitude)
        let minLat:Double = fmin(self.userLocation.latitude,  self.destLocation.latitude)
        let minLon:Double = fmin(self.userLocation.longitude, self.destLocation.longitude)
        
        // 地図表示するときの緯度、経度の幅を計算
        let mapMargin:Double = 3.0
        let leastCoordSpan:Double = 0.005;    // 拡大表示したときの最大値
        let span_x:Double = fmax(leastCoordSpan, fabs(maxLat - minLat) * mapMargin);
        let span_y:Double = fmax(leastCoordSpan, fabs(maxLon - minLon) * mapMargin);
        let span:MKCoordinateSpan = MKCoordinateSpanMake(span_x, span_y);
        
        // Map Center is current location
        let region:MKCoordinateRegion = MKCoordinateRegionMake(self.userLocation, span)
        mapView.setRegion(mapView.regionThatFits(region), animated:true);
    }
}

