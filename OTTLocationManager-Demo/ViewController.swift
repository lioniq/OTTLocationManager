//
//  ViewController.swift
//  LocationManager
//
//  Created by impressly on 12/3/15.
//  Copyright © 2015 OTT. All rights reserved.
//

import UIKit
import AddressBook

class ViewController: UIViewController {
    var locationManager = OTTLocationManager()

    @IBAction func didTapRefresh(sender: AnyObject) {
        refresh()
    }
    
    @IBOutlet weak var mapView: MKMapView!
    
    // search
    var selectedPin: MKPlacemark?
    var resultSearchController: UISearchController!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSearch()
        
        self.mapView.showsUserLocation = true
        
        self.locationManager.delegate = self
        refresh()
    }

    func setupSearch() {
        let locationSearchTable = storyboard!.instantiateViewControllerWithIdentifier("LocationSearchTable") as! OTTLocationSearchTable
        
        // init resultSearchController
        resultSearchController = UISearchController(searchResultsController: locationSearchTable)
        resultSearchController.searchResultsUpdater = locationSearchTable
        
        // config searchbar
        let searchBar = resultSearchController!.searchBar
        searchBar.sizeToFit()
        searchBar.placeholder = "Enter location"
        
        // searchbar/navigation bar setup
        navigationItem.titleView = searchBar
        resultSearchController.hidesNavigationBarDuringPresentation = false
        resultSearchController.dimsBackgroundDuringPresentation = true
        definesPresentationContext = true
        
        locationSearchTable.delegate = self
    }
    
    func refresh() {
        locationManager.start()
    }
    
    func zoomToCoord(coord: CLLocationCoordinate2D) {
        // Zoom Level Math:
        //        http://troybrant.net/blog/2010/01/set-the-zoom-level-of-an-mkmapview/
        //        http://blogs.bing.com/maps/2006/02/25/map-control-zoom-levels-gt-resolution
        let ZOOM_LEVEL_12 = 0.344 // degrees/meters math....
        
        let region = MKCoordinateRegion(center: coord, span: MKCoordinateSpanMake(ZOOM_LEVEL_12, ZOOM_LEVEL_12))
        self.mapView.setRegion(region, animated: true)
    }

}

extension ViewController : OTTLocationSearchTableDelegate {
    func didSelect(annotation: MKAnnotation) {
        mapView.removeAnnotations(mapView.annotations) // reset
        mapView.addAnnotation(annotation)
        zoomToCoord(annotation.coordinate)
    }
}

extension ViewController : OTTLocationManagerDelegate {
    
    func didUpdateLatLon(locationManager: OTTLocationManager, lat: Double, lon: Double) {
        print("lat: \(lat), lon: \(lon)")
        let curCoord = CLLocationCoordinate2DMake(lat, lon)
        zoomToCoord(curCoord)
    }
    
    func didUpdateCityDistrict(locationManager: OTTLocationManager, fullAddress: String?, zhFullAddress: String?, district: String?, city: String?, country: String?) {
        print("current location: \(fullAddress)")
    }
    
//    func alertNoResults() {
//        // alert no results
//        let alertVC = UIAlertController(title: "Geocode", message: "No results found", preferredStyle: UIAlertControllerStyle.Alert)
//        let action = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil)
//        alertVC.addAction(action)
//        
//        presentViewController(alertVC, animated: true, completion: nil)
//    }
}

