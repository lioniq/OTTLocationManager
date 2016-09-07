//
//  OTTLocationManager.swift
//  OTTLocationManager
//
//  Created by impressly on 12/3/15.
//  Copyright © 2015 OTT. All rights reserved.
//

import Foundation
import Foundation
import CoreLocation

protocol OTTLocationManagerDelegate: NSObjectProtocol {
    func didUpdateLatLon(locationManager: OTTLocationManager, lat: Double, lon: Double)
    func didUpdateCityDistrict(locationManager: OTTLocationManager, district: String?, city: String?, country: String?)
    
    func didGeocodeAddress(locationManager: OTTLocationManager, placemarks: [CLPlacemark])
    func didGeocodeDitu(locationManager: OTTLocationManager, results: [Dictionary<String, AnyObject>])
}

class OTTLocationManager: NSObject {
    
    // Core Location
    let manager = CLLocationManager()
    var currentLocation: CLLocation?
    
    //LocationManagerDelegate
    weak var delegate: OTTLocationManagerDelegate?
    
    // geocoded city/country/district
    var district: String?
    var city: String?
    var country: String?
    
    // MARK: Lifecycle
    override init() {
        self.currentLocation = CLLocation()
        super.init()
    }
    
    deinit {
        manager.stopUpdatingLocation()
    }

    // IOS8 以后才能使用定位功能
    private func ios8() -> Bool {
        return UIDevice.currentDevice().systemVersion >= "8.0"
    }
    
    // get user permission
    func allowRequest() {
        if (ios8()) {
            
            // 使用应用程序期间允许访问位置数据
            self.manager.requestWhenInUseAuthorization()
            
        } else {
            print("[OTTLocationMangager allowRequest] iOS7 or below not yet implemented! Failed to get user authorization for location")
        }
    }
    
    func start() {
        self.allowRequest()
        if (CLLocationManager.locationServicesEnabled()) {
            self.manager.desiredAccuracy = kCLLocationAccuracyBest
            
            self.manager.distanceFilter = kCLLocationAccuracyHundredMeters
            
            self.manager.delegate = self
            self.manager.startUpdatingLocation()
        }
    }
    
    func stop() {
        manager.stopUpdatingLocation()
    }
    
    // MARK: - Geocoding
    func geocode(address: String) {
        CLGeocoder().geocodeAddressString(address, completionHandler: {(placemarks, error) in
            if (error != nil) {
                print("[OTTLocationManager didUpdateLocations] reverse geocoder failed")
                return
            }
            
            if placemarks!.count > 0 {
                self.delegate?.didGeocodeAddress(self, placemarks: placemarks!)
            }
        })
    }
    
    func geocodeDitu(address: String) {
        let escAddress = address.stringByReplacingOccurrencesOfString(" ", withString: "+").stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
        let url = NSURL(string: "http://ditu.google.cn/maps/api/geocode/json?address=\(escAddress)&sensor=false")
        
        var jsonDict: NSDictionary = NSDictionary()
        
        do {
            let resp = NSData(contentsOfURL: url!)
            jsonDict = try NSJSONSerialization.JSONObjectWithData(resp!, options: NSJSONReadingOptions.MutableContainers) as! NSDictionary
            jsonDict["result"]
        } catch {
            print("[geocodeDitu] error: \(error)")
        }
        
        var results: [Dictionary<String, AnyObject>] = []
        
        for json in (jsonDict["results"] as! NSArray) {
            let r = json as! Dictionary<String, AnyObject>
            
            let formattedAddress = r["formatted_address"] as! String
            print("[geocodeDitu] formatted: \(formattedAddress)")
            
            let geometry = r["geometry"] as! Dictionary<String, AnyObject>
            let loc = geometry["location"] as! Dictionary<String, AnyObject>
            let lat = loc["lat"] as! Double
            let lon = loc["lng"] as! Double
            print("          lat/lng: \(lat), \(lon)")
            
            // append result
            
            let result: Dictionary<String, AnyObject> = ["address": formattedAddress, "lat": lat, "lon": lon]
            results.append(result)
        }
        
        delegate?.didGeocodeDitu(self, results: results)
    }
}

extension OTTLocationManager: CLLocationManagerDelegate {
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        // 取得locations数组的最后一个
        let location: CLLocation = locations[locations.count - 1]
        if location.horizontalAccuracy > 0 {
            let lat = Double(location.coordinate.latitude)
            let lon = Double(location.coordinate.longitude)
            
            self.currentLocation = location
            print("[OTTLocationManager didUpdateLocations] lat = \(lat),  lon = \(lon)")
            
            // 传值给代理
            self.delegate?.didUpdateLatLon(self, lat: lat, lon: lon)
            self.manager.stopUpdatingLocation()
            
            // 获取反地理编码
            CLGeocoder().reverseGeocodeLocation(manager.location!, completionHandler: {(placemarks, error) -> Void in
                
                if (error != nil) {
                    print("[OTTLocationManager didUpdateLocations] reverse geocoder failed")
                    return
                }
                
                if placemarks!.count > 0 {
                    let pm = placemarks![0] as CLPlacemark
                    self.delegate?.didUpdateCityDistrict(self, district: pm.subLocality, city: pm.locality, country: pm.country)
                }
            })
        }
    }
    
    // 定位错误信息
    func locationManager(manager: CLLocationManager, didFinishDeferredUpdatesWithError error: NSError?) {
        print("[OTTLocationManager didFinishDeferredUpdatesWithError] \(error)")
    }
    
}