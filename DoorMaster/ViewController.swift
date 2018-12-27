//
//  ViewController.swift
//  DoorMaster
//
//  Created by roger deutsch on 12/25/18.
//  Copyright © 2018 Roger Deutsch. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource,CBCentralManagerDelegate, CBPeripheralDelegate,
CBPeripheralManagerDelegate
{
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        
    }
    
    
    let userDefs = UserDefaults.standard
    var BTDevices : [String] = [String]()
    var currentBTDevice : String!
    var centralManager : CBCentralManager?
    var peripherals = Array<CBPeripheral>()
    var data : NSMutableData = NSMutableData()
    var currentPeripheral : CBPeripheral!
    
    @IBOutlet weak var BTPicker: UIPickerView!

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        peripherals.removeAll()
        BTDevices.removeAll()
        if (central.state == .poweredOn){
            self.centralManager?.scanForPeripherals(withServices: nil, options: nil)
        }
        else {
            let alertVC = UIAlertController(title: "Bluetooth is not enabled", message: "Make sure that your bluetooth is turned on", preferredStyle: UIAlertController.Style.alert)
            let action = UIAlertAction(title: "ok", style: UIAlertAction.Style.default, handler: { (action: UIAlertAction) -> Void in
                self.dismiss(animated: true, completion: nil)
            })
            alertVC.addAction(action)
            self.present(alertVC, animated: true, completion: nil)
            BTDevices.append("-- Devices display here --")
            BTPicker.reloadAllComponents()
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if (peripheral.name != nil){
            BTDevices.append(peripheral.name!)
            
        }
        else{
            BTDevices.append("no device name")
        }
        peripherals.append(peripheral)
        BTPicker.reloadAllComponents()
        setUserBtDevice()
        
    }
    
    @IBAction func ScanForBluetooth(sender: UIButton){
        BTDevices.removeAll()
        peripherals.removeAll()
        if (centralManager?.state == .poweredOn){
            self.centralManager?.scanForPeripherals(withServices: nil, options: nil)
        }
        else {
            let alertVC = UIAlertController(title: "Bluetooth is not enabled", message: "Make sure that your bluetooth is turned on", preferredStyle: UIAlertController.Style.alert)
            let action = UIAlertAction(title: "ok", style: UIAlertAction.Style.default, handler: { (action: UIAlertAction) -> Void in
                self.dismiss(animated: true, completion: nil)
            })
            alertVC.addAction(action)
            self.present(alertVC, animated: true, completion: nil)
            BTDevices.append("-- Devices display here --")
            BTPicker.reloadAllComponents()
        }
        
    }
    
    @IBAction func OpenCloseDoor(sender: UIButton){
        // This function sends data over bluetooth to the connected .
        currentPeripheral = peripherals[BTPicker.selectedRow(inComponent: 0)]
        centralManager?.connect(currentPeripheral, options: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("*****************************")
        print("Connection complete")
        print("Peripheral info: \(currentPeripheral)")
        
        //Stop Scan- We don't need to scan once we've connected to a peripheral. We got what we came for.
        centralManager?.stopScan()
        print("Scan Stopped")
        
        //Erase data that we might have
        data.length = 0
        
        //Discovery callback
        peripheral.delegate = self
        //Only look for services that matches transmit uuid
        peripheral.discoverServices(nil)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("*******************************************************")
        
        if ((error) != nil) {
            print("Error discovering services: \(error!.localizedDescription)")
            return
        }
        
        guard let services = peripheral.services else {
            return
        }
        //We need to discover the all characteristic
        for service in services {
            
            peripheral.discoverCharacteristics(nil, for: service)
        }
        print("Discovered Services: \(services)")
        //writeValue(data:"test")
        //disconnectFromDevice(peripheral)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        if let error = error {
            print("Error discovering service characteristics: \(error.localizedDescription)")
        }
        
        service.characteristics?.forEach({ characteristic in
            if let descriptors = characteristic.descriptors {
                print("DESCRIPTORS \(descriptors)")
            }
            let outString = "yes\n"
            let data = outString.data(using: String.Encoding.utf8)
            for characteristic in service.characteristics as [CBCharacteristic]!{
                if(characteristic.uuid.uuidString == "FFE1")
                {
                    print("sending data")
                    peripheral.writeValue(data ?? Data() ,
                                          for: characteristic,
                                          type: CBCharacteristicWriteType.withResponse)
                }
            }
            print("CHARACTERISTIC : \(characteristic.uuid.uuidString)")
            print(characteristic.properties)
        })
    }
    
    func peripheral(_ peripheral: CBPeripheral,
                    didWriteValueFor characteristic: CBCharacteristic,
                    error: Error?){
        let outString = "other data\n"
        let data = outString.data(using: String.Encoding.utf8)
        if (error != nil){
            print(error.debugDescription)
            peripheral.writeValue(data ?? Data() ,
                                  for: characteristic,
                                  type: CBCharacteristicWriteType.withoutResponse)
        }
        else{
            // navigationController?.popToRootViewController(animated: true)
        }
    }

    func disconnectFromDevice (_ peripheral: CBPeripheral ) {
        if peripheral != nil {
            centralManager?.cancelPeripheralConnection(peripheral)
        }
    }
    
    func writeValue(data: String){
        /*let characteristic :String = "FFE!"
        let valueString = (data as NSString).data(using: String.Encoding.utf8.rawValue)
    
        let outString = "yes\n"
        let data = outString.data(using: String.Encoding.utf8)
        currentPeripheral.writeValue(data, for: characteristic, type: CBCharacteristicWriteType.withoutResponse)
     */
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
        
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return BTDevices.count
    }
    
        override func viewDidLoad() {
        super.viewDidLoad()
        // viewDidLoad() runs BEFORE CentralManager initialization
        //Initialise CoreBluetooth Central Manager
        centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.main)
        
        // Connect data:
        self.BTPicker.delegate = self
        self.BTPicker.dataSource = self
        BTPicker.reloadAllComponents()
        //BTDevices = ["Item 1", "Item 2", "Item 3", "Item 4", "Item 5", "Item 6"]
        //userDefs.removeObject(forKey: "btdevice")  // use to remove value you added
        currentBTDevice = userDefs.string(forKey:"btdevice")
        if (currentBTDevice != nil){
            print (currentBTDevice)
        }
            
        setUserBtDevice()
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
            return BTDevices[row]
    }
    
    func setUserBtDevice(){
        let itemIndex = getUserSavedBTDevice();
        
        BTPicker.selectRow(itemIndex, inComponent: 0, animated: true)
        
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

