//
//  OTTLocationSearchTable.swift
//  OTTLocationManager
//
//  Created by JERRY LIU on 8/9/2016.
//  Copyright © 2016 OTT. All rights reserved.
//

import Foundation
import MapKit

protocol OTTLocationSearchTableDelegate: class {
    func didSelect(annotation: MKAnnotation)
}

class OTTLocationSearchTable: UITableViewController {
    
    weak var delegate: OTTLocationSearchTableDelegate?
    
    var results: [MKAnnotation] = []

}

extension OTTLocationSearchTable : UISearchResultsUpdating {
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        guard let searchQuery = searchController.searchBar.text else { return }
        
        OTTLocationManager().geocodeDitu(searchQuery, apiKey: nil, successBlock: {(results) in
            
            self.results = results
            self.tableView.reloadData()
            
            }, errorBlock: {(error) in
                print("[OTTLocationSearchTable updateSearchResults] error: \(error)")
        })
    }
}
extension OTTLocationSearchTable {
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell")!
        let selectedItem = results[indexPath.row]
        cell.textLabel?.text = selectedItem.title ?? "no name"
        cell.detailTextLabel?.text = selectedItem.subtitle ?? "no address"
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let selectedItem = results[indexPath.row]
        delegate?.didSelect(selectedItem)
        dismissViewControllerAnimated(true, completion: nil)
    }
}