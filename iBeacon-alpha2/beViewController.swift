//
//  beViewController.swift
//  iBeacon-alpha2
//
//  Created by Eric Theis on 6/11/14.
//  Copyright (c) 2014 PubNub. All rights reserved.
//

import UIKit
import CoreLocation
import CoreBluetooth

class beViewController: UIViewController, CBPeripheralManagerDelegate {

    @IBOutlet var uuid : UILabel
    @IBOutlet var major : UILabel
    @IBOutlet var minor : UILabel
    @IBOutlet var identity : UILabel
    @IBOutlet var status : UILabel
    
    let uuidObj = NSUUID(UUIDString: "0CF052C2-97CA-407C-84F8-B62AAC4E9020")
    
    var region = CLBeaconRegion()
    var data = NSDictionary()
    var manager = CBPeripheralManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initBeacon()
        updateInterface()
        // Do any additional setup after loading the view.
    }
    
    func initBeacon(){
        self.region = CLBeaconRegion(proximityUUID: uuidObj, major: 6, minor: 9, identifier: "com.pubnub.test")
    }
    
    func updateInterface(){
        self.uuid.text = self.region.proximityUUID.UUIDString
        self.major.text = "\(self.region.major)"
        self.minor.text = "\(self.region.minor)"
        self.identity.text = self.region.identifier
    }
    
    @IBAction func transmitBeacon(sender : UIButton) {
        self.data = self.region.peripheralDataWithMeasuredPower(nil)
        self.manager = CBPeripheralManager(delegate: self, queue: nil, options: nil)
    }
    
    func peripheralManagerDidUpdateState(peripheral: CBPeripheralManager!) {
        if(peripheral.state == CBPeripheralManagerState.PoweredOn) {
            println("powered on")
            println(data)
            self.manager.startAdvertising(data)
            self.status.text = "Transmitting!"
        } else if(peripheral.state == CBPeripheralManagerState.PoweredOff) {
            println("powered off")
            self.manager.stopAdvertising()
            self.status.text = "Power Off"
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
