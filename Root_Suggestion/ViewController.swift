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

        //位置情報の精度
        self.locationManager!.desiredAccuracy = kCLLocationAccuracyBest
        //位置情報取得間隔(m)
        self.locationManager!.distanceFilter = 300
        
        self.locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager?.startUpdatingLocation()

        // 現在地を中心に持ってくるスクリプト
//        mapView.setCenterCoordinate(mapView.userLocation.coordinate, animated: true)

        
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //MARK: Local notification
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        userLocation = CLLocationCoordinate2DMake(manager.location!.coordinate.latitude, manager.location!.coordinate.longitude)
        
        Logger.info("\(userLocation.latitude), \(userLocation.longitude)")
        
        let userLocAnnotation: MKPointAnnotation = MKPointAnnotation()
        userLocAnnotation.coordinate = userLocation
        userLocAnnotation.title = "Current Point"
        mapView.addAnnotation(userLocAnnotation)
        Logger.debug("Success to get current location data")
        

    }
    func locationManager(manager: CLLocationManager,didFailWithError error: NSError){
        Logger.error("locationManager error")
    }
    
    
    // 経路を描画するときの色や線の太さを指定
    func getRoute() {
        // 現在地と目的地のMKPlacemarkを生成
//        var fromPlacemark = MKPlacemark(coordinate:userLocation, addressDictionary:nil)
//        var toPlacemark   = MKPlacemark(coordinate:destLocation, addressDictionary:nil)
        // MKPlacemark から MKMapItem を生成
//        var fromItem = MKMapItem(placemark:fromPlacemark)
//        var toItem   = MKMapItem(placemark:toPlacemark)

        let request = MKDirectionsRequest()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: self.userLocation, addressDictionary: nil))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: self.destLocation, addressDictionary: nil))
        request.requestsAlternateRoutes = true
        request.transportType = .Walking
//        let directions = MKDirections(request: request)
//        directions.calculateDirectionsWithCompletionHandler { [unowned self] response, error in
//            guard let unwrappedResponse = response else { return }
//
//            /**CANNOT MAPVIEW.ADD*/
//            for route in unwrappedResponse.routes {
//                self.mapView.add(route.polyline)
//                self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
//            }
//        }
        
//        let directions = MKDirections(request:request)
//        directions.calculateDirectionsWithCompletionHandler({
//            (response:MKDirectionsResponse!, error:NSError!) -> Void in
//            
//            response.routes.count
//            if (error != nil || response.routes.isEmpty) {
//                return
//            }
//            var route: MKRoute = response.routes[0] as MKRoute
//            // 経路を描画
//            self.mapView.addOverlay(route.polyline!)
//            // 現在地と目的地を含む表示範囲を設定する
//            self.showUserAndDestinationOnMap()
//        })

    }

    // 地図の表示範囲を計算
    func showUserAndDestinationOnMap() {
        Logger.debug("")
        // 現在地と目的地を含む矩形を計算
        let maxLat:Double = fmax(self.userLocation.latitude,  self.destLocation.latitude)
        let maxLon:Double = fmax(self.userLocation.longitude, self.destLocation.longitude)
        let minLat:Double = fmin(self.userLocation.latitude,  self.destLocation.latitude)
        let minLon:Double = fmin(self.userLocation.longitude, self.destLocation.longitude)
        
        // 地図表示するときの緯度、経度の幅を計算
        let mapMargin:Double = 1.5;  // 経路が入る幅(1.0)＋余白(0.5)
        let leastCoordSpan:Double = 0.005;    // 拡大表示したときの最大値
        let span_x:Double = fmax(leastCoordSpan, fabs(maxLat - minLat) * mapMargin);
        let span_y:Double = fmax(leastCoordSpan, fabs(maxLon - minLon) * mapMargin);
        
        let span:MKCoordinateSpan = MKCoordinateSpanMake(span_x, span_y);
        
        // 現在地を目的地の中心を計算
        let center:CLLocationCoordinate2D = CLLocationCoordinate2DMake((maxLat + minLat) / 2, (maxLon + minLon) / 2);
        let region:MKCoordinateRegion = MKCoordinateRegionMake(center, span);
        
        mapView.setRegion(mapView.regionThatFits(region), animated:true);
    }
    
    func mapView( mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(polyline: overlay as! MKPolyline)
        renderer.strokeColor = UIColor.blueColor()
        return renderer
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
                Logger.error("Reverse geocoder failed with error")
                return
            }
            
            let placemark = placemarks![0]
            Logger.info("\(placemark.location!.coordinate.latitude), \(placemark.location!.coordinate.longitude)")
            self.destLocation = CLLocationCoordinate2DMake( placemark.location!.coordinate.latitude, placemark.location!.coordinate.longitude)
            self.showUserAndDestinationOnMap()
        })
    }
}

