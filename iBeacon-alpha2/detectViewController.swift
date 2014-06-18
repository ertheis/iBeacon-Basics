//
//  detectViewController.swift
//  iBeacon-alpha2
//
//  Created by Eric Theis on 6/11/14.
//  Copyright (c) 2014 PubNub. All rights reserved.
//

import UIKit
import CoreLocation
import CoreBluetooth

class detectViewController: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet var found : UILabel
    @IBOutlet var uuid : UILabel
    @IBOutlet var major : UILabel
    @IBOutlet var minor : UILabel
    @IBOutlet var accuracy : UILabel
    @IBOutlet var distance : UILabel
    @IBOutlet var rssi : UILabel
    
    let uuidObj = NSUUID(UUIDString: "0CF052C2-97CA-407C-84F8-B62AAC4E9020")
    
    var region = CLBeaconRegion()
    var manager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        manager.delegate = self
        initRegion()
        println(manager)
        println(region)
    }
    
    func initRegion() {
        self.region = CLBeaconRegion(proximityUUID: uuidObj, identifier: "com.pubnub.test")
        
        println(self.isMemberOfClass(CLLocationManagerDelegate))
    }

    @IBAction func startDetection(sender : UIButton) {
        self.manager.startMonitoringForRegion(self.region)
        self.found.text = "Starting Monitor"
    }
    
    func locationManager(manager: CLLocationManager!, didStartMonitoringForRegion region: CLRegion!) {
        self.found.text = "Scanning..."
        manager.startRangingBeaconsInRegion(region as CLBeaconRegion)
    }
    
    func locationManager(manager: CLLocationManager!, monitoringDidFailForRegion region: CLRegion!, withError error: NSError!) {
        self.found.text = "Error :("
        println(error)
    }
    
    func locationManager(manager: CLLocationManager!, didEnterRegion region: CLRegion!) {
        manager.startRangingBeaconsInRegion(region as CLBeaconRegion)
        self.found.text = "Possible Match"
    }
    
    func locationManager(manager: CLLocationManager!, didExitRegion region: CLRegion!) {
        manager.stopRangingBeaconsInRegion(region as CLBeaconRegion)
        self.found.text = "No :("
    }
    
    func locationManager(manager: CLLocationManager!, didRangeBeacons beacons: NSArray!, inRegion region: CLBeaconRegion!) {
        if(beacons.count == 0) { return }
        
        var beacon = beacons.lastObject as CLBeacon
        
        if (beacon.proximity == CLProximity.Unknown) {
            self.distance.text = "Unknown Proximity"
            
            self.found.text = "No"
            self.uuid.text = "N/A"
            self.major.text = "N/A"
            self.minor.text = "N/A"
            self.accuracy.text = "N/A"
            self.rssi.text = "N/A"
            
            return
        } else if (beacon.proximity == CLProximity.Immediate) {
            self.distance.text = "Immediate"
        } else if (beacon.proximity == CLProximity.Near) {
            self.distance.text = "Near"
        } else if (beacon.proximity == CLProximity.Far) {
            self.distance.text = "Far"
        }
        self.found.text = "Yes!"
        self.uuid.text = beacon.proximityUUID.UUIDString
        self.major.text = "\(beacon.major)"
        self.minor.text = "\(beacon.minor)"
        self.accuracy.text = "\(beacon.accuracy)"
        self.rssi.text = "\(beacon.rssi)"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
