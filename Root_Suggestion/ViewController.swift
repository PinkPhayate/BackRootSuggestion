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
import SwiftyJSON


class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate, UISearchBarDelegate {
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var mySearchBar: UISearchBar!
    var currentLocationButton: UIButton! = nil
    var locationManager: CLLocationManager?
    var userLocation: CLLocationCoordinate2D!
    var destLocation: CLLocationCoordinate2D!
    var source:MKMapItem?
    var destination:MKMapItem?
//    var points: [JSON] = []
//    var points: [NSDictionary] = []
    var points:[JSON] = []
    var defaultHash: Int = 0
    var flag: Bool = true

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Unable Cancel button
        self.mySearchBar.showsCancelButton = true
        // Disable Bookmark button
        self.mySearchBar.showsBookmarkButton = false
        // set searchBar Style => Default
        self.mySearchBar.searchBarStyle = UISearchBarStyle.Default
        self.mySearchBar.delegate = self
        self.mySearchBar.placeholder = "目的地                                                                                                                         "
//        self.mySearchBar.text = "銀座駅"

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

    override func viewWillAppear(animated: Bool) {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: #selector(self.handleKeyboardWillShowNotification(_:)), name: UIKeyboardWillShowNotification, object: nil)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    //MARK: Model

    //MARK: Map
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.userLocation = CLLocationCoordinate2DMake(manager.location!.coordinate.latitude, manager.location!.coordinate.longitude)
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
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        let route: MKPolyline = overlay as! MKPolyline
        let routeRenderer = MKPolylineRenderer(polyline:route)
        routeRenderer.lineWidth = 5.0
        Logger.debug("\(route.hashValue)")
        if self.flag {
            //        if route.hashValue == self.defaultHash {
            routeRenderer.strokeColor = UIColor.blueColor()
            self.flag = false
        }else {
            routeRenderer.strokeColor = UIColor.redColor()
        }
        return routeRenderer
    }

    //MARK: Annotation
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        let annotation = view.annotation
        let title = annotation!.title
        Logger.debug("\(title)")
    }

    func drawAnnotations() {
        for point in self.points {
            Logger.debug("\(point)")
            let lng = point["lng"].string
            let lat = point["lat"].string
            let title = point["name"].string
            Logger.debug("\(Double(lng!))")
            Logger.debug("\(Double(lat!))")
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2DMake(Double(lat!)!, Double(lng!)!)
            annotation.title = String(title!)
            Logger.debug(String(title!))
            annotation.subtitle = ""

            self.mapView.addAnnotation(annotation)
            
        }
    }
    //MARK: Drawing Map
    // 経路を描画するときの色や線の太さを指定
    func drawShortestRoot(dest: CLLocationCoordinate2D) {
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
//            route.setValue("Default", forKey: "courseName")
            
            self.mapView.addOverlay(route.polyline)
            self.defaultHash = route.polyline.hashValue
            Logger.debug("\(route.polyline.hashValue)")
            self.showCurrentLocAndDestinationOnMap()
        }
    }
    
    func drawSuggestedRoot() {
        var fromPoint: CLLocationCoordinate2D = Stub.GET_CURRENT_LOCATION_FROM_STUB
        for point in points {
            Logger.debug("\(point)")
            let lng = point["lng"].string
            let lat = point["lat"].string
            Logger.debug("\(Double(lng!))")
            Logger.debug("\(Double(lat!))")
            let toPoint: CLLocationCoordinate2D = CLLocationCoordinate2DMake(Double(lat!)!, Double(lng!)!)
            self.getRoute(toPoint,fromPoint: fromPoint)
            fromPoint = toPoint
        }
        self.getRoute(Stub.GET_DESTINATION_LOCATION_FROM_STUB,fromPoint: fromPoint)

    }
    
    func getRoute(toPoint: CLLocationCoordinate2D, fromPoint: CLLocationCoordinate2D) {
        let request = MKDirectionsRequest()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: fromPoint, addressDictionary: nil))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: toPoint, addressDictionary: nil))
        request.requestsAlternateRoutes = true
        request.transportType = .Walking
        
        let directions = MKDirections(request: request)
        directions.calculateDirectionsWithCompletionHandler{
            response, error in
            
            guard let response = response else {
                //handle the error here
                self.showErrorAlert( "目的地が見つかりません" )
                Logger.error("COULD NOT FIND ANY ROOT")
                return
            }
            let route: MKRoute = response.routes[0] as MKRoute
            self.mapView.addOverlay(route.polyline)
        }
    }


    
//    func mapView( mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
//        let renderer = MKPolylineRenderer(polyline: overlay as! MKPolyline)
//        Logger.info("\(renderer.hash)")
//        renderer.strokeColor = UIColor.redColor()
//        return renderer
//    }


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
    
    func buttonTapped(overray: MKPolylineRenderer) {
        //Button Tapped
    }
    
    
    //MARK: Controller
    func handleKeyboardWillShowNotification(notification: NSNotification) {
        self.mySearchBar.showsCancelButton = true
    }
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        self.mySearchBar.showsCancelButton = false
        self.mySearchBar.resignFirstResponder()
    }
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        self.flag = true
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
                self.showErrorAlert( "目的地が見つかりません" )
                return
            }
            // Success
            let placemark = placemarks![0]
            Logger.info("\(placemark.location!.coordinate.latitude), \(placemark.location!.coordinate.longitude)")
            self.destLocation = CLLocationCoordinate2DMake( placemark.location!.coordinate.latitude, placemark.location!.coordinate.longitude)
            self.showCurrentLocAndDestinationOnMap()
            

            if self.mySearchBar.text! == "銀座" || self.mySearchBar.text! == "銀座駅" {
                self.drawShortestRoot(Stub.GET_DESTINATION_LOCATION_FROM_STUB)
                self.getSuggestedRoots()
            }else {
                self.drawShortestRoot( self.destLocation )
            }

            //            self.getRoute( self.destLocation, fromPoint: self.userLocation )
            self.showCurrentLocAndDestinationOnMap()
        })
    }
    func tapScreen(searchBar: UISearchBar) {
//        if self.mySearchBar.hidden {
//            self.mySearchBar.hidden = false
//            return
//        }
//            self.mySearchBar.hidden = true
    }


    @IBAction func pushCurrentLocationButton(sender: AnyObject) {
        // 現在地と目的地を含む矩形を計算
        if self.userLocation == nil || self.destLocation == nil {
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
    
    //MARK: API
    func getSuggestedRoots(){
//        self.userLocation = Stub.GET_CURRENT_LOCATION_FROM_STUB
//        self.destLocation = Stub.GET_DESTINATION_LOCATION_FROM_STUB
//        
//        let url: String = "http://210.129.50.253:8000/api/routesearch/?format=json&current_location_lng=\(self.userLocation.longitude)&current_location_lat=\(self.userLocation.latitude)&destination_lng=\(self.destLocation.longitude)&destination_lat=\(self.destLocation.latitude)"
//        do {
//            let opt = try HTTP.GET(url)
//            
//            opt.start { (response) in
//                if (response.text != nil) {
//                    Logger.debug("\(response.text)")
//                    let d: NSData = (response.text)!.dataUsingEncoding(NSUTF8StringEncoding)!
//                    let json = JSON(data: d)
//                    for point in json {
//                        self.points.append(point.1)
//                    }
//                self.drawSuggestedRoot()
//                self.drawAnnotations()
//                    
//                }
//            }
//        }
//        catch _ {
//            self.showErrorAlert( "サーバーに接続できません" )
//        }
    }
    func showErrorAlert(message: String){
        let alertController: UIAlertController = UIAlertController(title: "ERROR", message: message, preferredStyle: .Alert)
        let actionOK = UIAlertAction(title: "OK", style: .Default){
            action -> Void in
        }
        alertController.addAction(actionOK)
        self.presentViewController(alertController, animated: true, completion: nil)
    }

}

