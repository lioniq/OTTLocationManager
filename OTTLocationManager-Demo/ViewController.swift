//
//  ViewController.swift
//  LocationManager
//
//  Created by impressly on 12/3/15.
//  Copyright © 2015 OTT. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    var locationManager = OTTLocationManager()

    @IBOutlet weak var lat: UILabel!
    @IBOutlet weak var lon: UILabel!
    @IBOutlet weak var city: UILabel!
    @IBOutlet weak var district: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.locationManager.delegate = self
        refresh()
        
        
    }

    func refresh() {
        
        //开启定位
        self.locationManager.setup()
        self.locationManager.getLatLon()
    }
    
    func getNextPage() {
        
        if self.locationManager.mode == OTTLocationManagerMode.latLon {
            let lat = Float(self.locationManager.currentLocation!.coordinate.latitude)
            
            let lon = Float(self.locationManager.currentLocation!.coordinate.longitude)
           
        } else if self.locationManager.mode == OTTLocationManagerMode.cityDistrict {
            
            let city = self.locationManager.city
            let district = self.locationManager.district
            
//            self.city.text = city
//            self.district.text = district
        }

    }

}


extension ViewController : OTTLocationManagerDelegate {
    func didUpdateLatLon(locationManager: OTTLocationManager, lat: Float, lon: Float) {
        
        self.lat.text = lat.description
        self.lon.text = lon.description
    }
    
    func didSetCityDistrict(locationManager: OTTLocationManager, city: String, district: String) {
        self.city.text = city
        self.district.text = district
    }
}

