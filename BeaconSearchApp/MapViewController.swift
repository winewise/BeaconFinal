//
//  MapViewController.swift
//  BeaconSearchApp
//
//  Created by Developer 1 on 2015-10-26.
//  Copyright © 2015 Ap1. All rights reserved.
//

import UIKit
import MapKit
import BeaconSearch

class MapViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    let initialLocation = CLLocationCoordinate2D(latitude: 43.647772, longitude: -79.380426)
    let regionRadius: CLLocationDistance = 1000
    let numberOfLocations = 1000
    let clusteringManager = FBClusteringManager()
    weak var mainTabBarController: MainTabBarController?
    var persistedFoundBeacons: [Beacon] = []
    var operationQueue: NSOperationQueue?
    
    var allBeacons: [Beacon] {
        get {
            return self.segmentedControl.selectedSegmentIndex == 0 ? self.persistedFoundBeacons : self.mainTabBarController!.allBeacons
        }
    }
    
    var storedBeacons: [CLBeacon : Beacon] {
        get {
            return self.mainTabBarController!.storedBeacons
        }
    }
    
    var findBeacon: FindBeacon? {
        get {
            return self.mainTabBarController?.findBeacon
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.operationQueue = NSOperationQueue()
        
        self.mapView.showsUserLocation = true

        let array: [MKAnnotation] = self.beaconLocations()
        
        clusteringManager.setAnnotations(array)
        clusteringManager.delegate = self
        
        self.goToCurrentLocation()
        
        let barButton = MKUserTrackingBarButtonItem(mapView: self.mapView)
        self.navigationItem.rightBarButtonItem = barButton
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func goToCurrentLocation() {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        if let currentLocation = appDelegate.currentLocation {
            let span = MKCoordinateSpanMake(0.075, 0.075)
            let region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: currentLocation.coordinate.latitude, longitude: currentLocation.coordinate.longitude), span: span)
            mapView.setRegion(region, animated: true)
        }
    }

    // MARK: - Utility
    func beaconLocations() -> [FBAnnotation] {
        var array:[FBAnnotation] = []
        for beacon in self.allBeacons {
            if let lat = beacon.latitude, lng = beacon.longitude, dLat = Double(lat), dLng = Double(lng) {
                let annotation: FBAnnotation = FBAnnotation()
                annotation.title = beacon.nickName != nil && !beacon.nickName!.isEmpty ? beacon.nickName! : "Unnamed"
                annotation.index = self.allBeacons.indexOf(beacon) ?? -1
                annotation.coordinate = CLLocationCoordinate2D(latitude: dLat, longitude: dLng)
                array.append(annotation)
            }
        }
        
        return array
    }
    
    func zoomToRegion(annotations: [MKAnnotation]) {
        var zoomRect: MKMapRect = MKMapRectNull
        for annotation in annotations {
            let annotationPoint = MKMapPointForCoordinate(annotation.coordinate)
            let pointRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, 0.1, 0.1)
            zoomRect = MKMapRectUnion(zoomRect, pointRect)
        }
        
        mapView.setVisibleMapRect(zoomRect, animated: true)
    }
    
    func update() {
        dispatch_async(dispatch_get_main_queue(), {
            self.operationQueue?.cancelAllOperations()
            if self.mapView != nil {
                let annotationsToRemove = self.mapView.annotations.filter { $0 !== self.mapView.userLocation }
                self.mapView.removeAnnotations(annotationsToRemove)
                
                let array: [MKAnnotation] = self.beaconLocations()
                self.clusteringManager.setAnnotations(array)
                self.updateRegion()
            }
        })
    }
    
    func updateNearbyBeacons() {
        var beacons: [Beacon] = []
        for beacon in self.mainTabBarController!.persistedFoundBeacons {
            if let beaconValue = self.storedBeacons[beacon] {
                beacons.append(beaconValue)
            }
        }
        
        self.persistedFoundBeacons = beacons
        
        self.update()
    }
    
    @IBAction func segmentedControlValueChanged(sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            self.updateNearbyBeacons()
        }
        else {
            self.update()
        }
    }
}

extension MapViewController : FBClusteringManagerDelegate {
    
    func cellSizeFactorForCoordinator(coordinator:FBClusteringManager) -> CGFloat{
        return 6.0
    }
}

extension MapViewController : MKMapViewDelegate {
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        self.updateRegion()
    }
    
    func updateRegion() {
        self.operationQueue?.addOperationWithBlock({
            
            let mapBoundsWidth = Double(self.mapView.bounds.size.width)
            
            let mapRectWidth:Double = self.mapView.visibleMapRect.size.width
            
            let scale:Double = mapBoundsWidth / mapRectWidth
            
            let annotationArray = self.clusteringManager.clusteredAnnotationsWithinMapRect(self.mapView.visibleMapRect, withZoomScale:scale)
            
            self.clusteringManager.displayAnnotations(annotationArray, onMapView:self.mapView)
            
        })
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        if (annotation is MKUserLocation) {
            return nil
        }
        
        var reuseId = ""
        
        if annotation.isKindOfClass(FBAnnotationCluster) {
            
            reuseId = "Cluster"
            var clusterView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId)
            clusterView = FBAnnotationClusterView(annotation: annotation, reuseIdentifier: reuseId)
            
            return clusterView
            
        } else {
            
            reuseId = "Pin"
            var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            
            if mainTabBarController!.writeAccess {
                pinView!.draggable = true
            }
            
            let rightControl = UIButton(type: UIButtonType.DetailDisclosure)
            rightControl.setImage(UIImage(named: "disclosure-indicator"), forState: UIControlState.Normal)
            rightControl.frame = CGRectMake(0, 0, 12, 19)
            rightControl.tag = 1
            pinView!.rightCalloutAccessoryView = rightControl
            let leftControl = UIButton(frame: CGRectMake(0, 0, 26, 26))
            leftControl.setImage(UIImage(named: "directions-icon"), forState: UIControlState.Normal)
            leftControl.tag = 2
            pinView!.leftCalloutAccessoryView = leftControl
            
            var pinTintColor = UIColor.greenColor()
            if let fbAnnotation = pinView?.annotation as? FBAnnotation {
                let beacon = self.allBeacons[fbAnnotation.index]
                if beacon.companyId != nil && !beacon.companyId!.isEmpty {
                    if let colorHex = beacon.color, color = UIColor(hexString: colorHex) {
                        pinTintColor = color
                    }
                }
                else {
                    // unkown
                    pinTintColor = UIColor.redColor()
                }
            }
            
            if #available(iOS 9.0, *) {
                pinView!.pinTintColor = pinTintColor
            } else {
                pinView!.pinColor = .Green
            }
            
            return pinView
        }
    }
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if control.tag == 1 {
            if let fbAnnotation = view.annotation as? FBAnnotation {
                if fbAnnotation.index >= 0 {
                    let beacon = self.allBeacons[fbAnnotation.index]
                    
                    if let webViewController = self.storyboard?.instantiateViewControllerWithIdentifier("WebViewController") as? WebViewController {
                        webViewController.beacon = beacon
                        self.navigationController?.pushViewController(webViewController, animated: true)
                    }
                }
            }
        }
        else if control.tag == 2 {
            if let selectedLoc = view.annotation {
                let currentLocMapItem = MKMapItem.mapItemForCurrentLocation()
                let selectedPlacemark = MKPlacemark(coordinate: selectedLoc.coordinate, addressDictionary: nil)
                let selectedMapItem = MKMapItem(placemark: selectedPlacemark)
                
                if let fbAnnotation = view.annotation as? FBAnnotation {
                    let beacon = self.allBeacons[fbAnnotation.index]
                    selectedMapItem.name = beacon.notifyTitleFar ?? ""
                }
                
                let mapItems = [currentLocMapItem, selectedMapItem]
                let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
                MKMapItem.openMapsWithItems(mapItems, launchOptions:launchOptions)
            }
        }
    }
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, didChangeDragState newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
        switch (newState) {
        case .Ending:
            if let fbAnnotation = view.annotation as? FBAnnotation, lat = view.annotation?.coordinate.latitude.description, long = view.annotation?.coordinate.longitude.description {
                let beacon = self.allBeacons[fbAnnotation.index]
                if let findBeacon = self.findBeacon {

                    self.showLoading()
                    findBeacon.updateBeacon(updateBeaconUrl, username: PFUser.currentUser()?.username ?? "", beacon: beacon, lat: lat, long: long, completionHandler: { result, message in
                        if result {
                        }
                        else {
                             view.dragState = oldState
                        }
                        
                        dispatch_async(dispatch_get_main_queue())  {
                            self.hideLoading()
                        }
                    })
                }
            }
        default:
            break
        }
    }
}