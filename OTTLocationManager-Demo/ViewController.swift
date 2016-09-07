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

    // location geocoding
    @IBOutlet weak var lat: UILabel!
    @IBOutlet weak var lon: UILabel!
    @IBOutlet weak var city: UILabel!
    @IBOutlet weak var district: UILabel!
    @IBOutlet weak var country: UILabel!
    
    @IBAction func didTapRefresh(sender: AnyObject) {
        refresh()
    }
    
    // reverse geocoding address
    
    @IBOutlet weak var addressTextField: UITextField!
    @IBAction func didTapAddressGeocode(sender: AnyObject) {
        lookupAddress()
    }
    
    @IBOutlet weak var mapView: MKMapView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.locationManager.delegate = self
        refresh()
    }

    func refresh() {
        locationManager.start()
    }
    
    func lookupAddress() {
        guard let address = addressTextField.text else { return }
//        locationManager.geocode(address)
        locationManager.geocodeDitu(address)
    }

}


extension ViewController : OTTLocationManagerDelegate {
    
    func didUpdateLatLon(locationManager: OTTLocationManager, lat: Double, lon: Double) {
        self.lat.text = lat.description
        self.lon.text = lon.description
    }
    
    func didUpdateCityDistrict(locationManager: OTTLocationManager, district: String?, city: String?, country: String?) {
        self.city.text = city
        self.district.text = district
        self.country.text = country
    }
    
    func didGeocodeAddress(locationManager: OTTLocationManager, placemarks: [CLPlacemark]) {
        if placemarks.count == 0 {
            alertNoResults()
        } else {
            for pm in placemarks {
                print("placemark: \(pm.country), \(pm.locality), \(pm.subLocality)")
                let anno = MKPlacemark(placemark: pm)
                self.mapView.addAnnotation(anno)
            }
        }
    }
    
    func didGeocodeDitu(locationManager: OTTLocationManager, results: [Dictionary<String, AnyObject>]) {
        if results.count == 0 {
            alertNoResults()
        } else {
            for r in results {
                let address = r["address"] as! String
                let lat = r["lat"] as! Double
                let lon = r["lon"] as! Double
                let coord = CLLocationCoordinate2DMake(lat, lon)
                let addressDict: Dictionary<String, AnyObject> = [kABPersonAddressStreetKey as String: address]
                
                let anno = MKPlacemark(coordinate: coord, addressDictionary: addressDict)
                self.mapView.addAnnotation(anno)
            }
        }
    }
    
    func alertNoResults() {
        // alert no results
        let alertVC = UIAlertController(title: "Geocode", message: "No results found", preferredStyle: UIAlertControllerStyle.Alert)
        let action = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil)
        alertVC.addAction(action)
        
        presentViewController(alertVC, animated: true, completion: nil)
    }
}

