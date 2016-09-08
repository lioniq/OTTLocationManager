//
//  OTTLocationManager.swift
//  OTTLocationManager
//
//  Created by impressly on 12/3/15.
//  Copyright © 2015 OTT. All rights reserved.
//

import Foundation
import CoreLocation

protocol OTTLocationManagerDelegate: NSObjectProtocol {
    func didUpdateLatLon(locationManager: OTTLocationManager, lat: Double, lon: Double)
    func didUpdateCityDistrict(locationManager: OTTLocationManager, fullAddress: String?, zhFullAddress: String?, district: String?, city: String?, country: String?)
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
            
            // request for always on
            self.manager.requestAlwaysAuthorization()
            
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
//    func geocode(address: String) {
//        CLGeocoder().geocodeAddressString(address, completionHandler: {(placemarks, error) in
//            if (error != nil) {
//                print("[OTTLocationManager didUpdateLocations] reverse geocoder failed")
//                return
//            }
//            
//            if placemarks!.count > 0 {
////                self.delegate?.didGeocodeAddress(self, placemarks: placemarks!)
//            }
//        })
//    }
    
    func geocodeDitu(address: String, apiKey: String?, successBlock: (results: [MKAnnotation]) -> Void, errorBlock: (error: NSError) -> Void) {
        
        guard address.characters.count > 0 else {
            return
        }
        let escAddress = address.stringByReplacingOccurrencesOfString(" ", withString: "+").stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
        let url = NSURL(string: "http://ditu.google.cn/maps/api/geocode/json?address=\(escAddress!)&sensor=false")
        
        var jsonDict: NSDictionary = NSDictionary()
        
        do {
            let resp = NSData(contentsOfURL: url!)
            jsonDict = try NSJSONSerialization.JSONObjectWithData(resp!, options: NSJSONReadingOptions.MutableContainers) as! NSDictionary
            
            var results: [MKAnnotation] = []
            
            for json in (jsonDict["results"] as! NSArray) {
                let r = json as! Dictionary<String, AnyObject>
                
                // TODO: safer JSON handling
                
                // title/shortname
                let addressComponents = r["address_components"] as! [Dictionary<String, AnyObject>]
                let name = addressComponents.first!["short_name"] as! String
                
                // formatted full address
                let formattedAddress = r["formatted_address"] as! String
                print("[geocodeDitu] name: \(name), formatted: \(formattedAddress)")
                
                let geometry = r["geometry"] as! Dictionary<String, AnyObject>
                let loc = geometry["location"] as! Dictionary<String, AnyObject>
                let lat = loc["lat"] as! Double
                let lon = loc["lng"] as! Double
                print("          lat/lng: \(lat), \(lon)")
                
//                // instantiate MKPlacemark
//                let coord = CLLocationCoordinate2DMake(lat, lon)
//                let addressDict: Dictionary<String, AnyObject> = [
//                    kABPersonAddressStreetKey as String: address
//                ]
//                
//                let pm = MKPlacemark(coordinate: coord, addressDictionary: addressDict)
//                
//                // make mapItem
//                let mapItem = MKMapItem(placemark: pm)
//                mapItem.name = name

                // instantiate annotations
                let anno = MKPointAnnotation()
                anno.coordinate = CLLocationCoordinate2DMake(lat, lon)
                anno.title = name
                anno.subtitle = formattedAddress
                
                results.append(anno)
            }
            
            successBlock(results: results)
            
            
        } catch let error as NSError {
            print("[geocodeDitu] error: \(error)")
            errorBlock(error: error)
        }
        
        
    }
}

extension OTTLocationManager: CLLocationManagerDelegate {
    
    //    Request user current location lat/lon and reverse geocode for basic information
    //    Manager object retains CLLocationManager instance and waits for delegate method.
    //    For iOS9+ this is unneccessary as can use `manager.requestLocation()` method for one-time request for location
    //    Calls delegates TWICE in this instance, and closes GPS location by itself
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
            
            
            // 获取反地理编码
            CLGeocoder().reverseGeocodeLocation(manager.location!, completionHandler: {(placemarks, error) -> Void in
                
                if (error != nil) {
                    print("[OTTLocationManager didUpdateLocations] reverse geocoder failed")
                    return
                }
                
                if placemarks!.count > 0 {
                    let pm = placemarks![0] as CLPlacemark
                    
                    // concatenate strings
                    let addressStrings: [String?] = [pm.subLocality, pm.locality, pm.country]
                    let fullAddress = addressStrings.flatMap{$0}.joinWithSeparator(", ")
                    print("[OTTLocationManager didUpdateLocations] address: \(fullAddress)")
                    
                    let zhFullAddress = addressStrings.reverse().flatMap{$0}.joinWithSeparator("")
                    
                    self.delegate?.didUpdateCityDistrict(self, fullAddress: fullAddress, zhFullAddress: zhFullAddress, district: pm.subLocality, city: pm.locality, country: pm.country)
                }
            })
            
            self.manager.stopUpdatingLocation()
        }
    }
    
    // 定位错误信息
    func locationManager(manager: CLLocationManager, didFinishDeferredUpdatesWithError error: NSError?) {
        print("[OTTLocationManager didFinishDeferredUpdatesWithError] \(error)")
    }
    
}