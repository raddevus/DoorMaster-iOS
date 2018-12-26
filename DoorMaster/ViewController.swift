//
//  ViewController.swift
//  DoorMaster
//
//  Created by roger deutsch on 12/25/18.
//  Copyright © 2018 Roger Deutsch. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource,CBCentralManagerDelegate {
    
    let userDefs = UserDefaults.standard
    var BTDevices : [String] = [String]()
    var currentBTDevice : String!
    var centralManager : CBCentralManager?
    var peripherals = Array<CBPeripheral>()
    
    @IBOutlet weak var BTPicker: UIPickerView!

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if (central.state == .poweredOn){
            self.centralManager?.scanForPeripherals(withServices: nil, options: nil)
        }
        else {
            // do something like alert the user that ble is not on
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if (peripheral.name != nil){
            BTDevices.append(peripheral.name!)
        }
        else{
            BTDevices.append("no device name")
        }
        BTPicker.reloadAllComponents()
        // tableView.reloadData()
    }

    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
        
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return BTDevices.count
    }
    
        override func viewDidLoad() {
        super.viewDidLoad()
        
        //Initialise CoreBluetooth Central Manager
        centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.main)
        
        // Connect data:
        self.BTPicker.delegate = self
        self.BTPicker.dataSource = self
        
        //BTDevices = ["Item 1", "Item 2", "Item 3", "Item 4", "Item 5", "Item 6"]
        //userDefs.removeObject(forKey: "btdevice")  // use to remove value you added
        currentBTDevice = userDefs.string(forKey:"btdevice")
        if (currentBTDevice != nil){
            print (currentBTDevice)
        }
        var itemIndex = getUserSavedBTDevice();
        
        BTPicker.selectRow(itemIndex, inComponent: 0, animated: true)
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
            return BTDevices[row]
    }
    
    func getUserSavedBTDevice() -> Int{
        for (index, item) in BTDevices.enumerated(){
            if (item == currentBTDevice){
                return index
            }
        }
        // if the item isn't found we just return 0
        // so the first item in uipickerview is selected.
        return 0;
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        userDefs.set(BTDevices[row], forKey:"btdevice")
        userDefs.synchronize()
        print(BTDevices[row])
        
    }


}

