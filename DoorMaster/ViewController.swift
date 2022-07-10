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
    
    @IBOutlet var textDiagnostics : UITextView!
    
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
        textDiagnostics.text += "Loaded...\n"
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        textDiagnostics.text += "centralManager()...\n"
        if (peripheral.name != nil){
            BTDevices.append(peripheral.name!)
        }
        else{
            // 2022-07-10 No longer show devices with no name
            // BTDevices.append("no device name")
        }
        peripherals.append(peripheral)
        BTPicker.reloadAllComponents()
        setUserBtDevice()
        
    }
    
    @IBAction func ScanForBluetooth(sender: UIButton){
        BTDevices.removeAll()
        peripherals.removeAll()
        textDiagnostics.text += "ScanForBluetooth()...\n"
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
        let currentSelectedBT = BTPicker.selectedRow(inComponent: 0)
        textDiagnostics.text += currentSelectedBT.description + "\n"
        if (peripherals.count != 0){
            currentPeripheral = peripherals[currentSelectedBT]
            centralManager?.connect(currentPeripheral, options: nil)
        }
        
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
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        if let error = error {
            print("Error discovering service characteristics: \(error.localizedDescription)")
        }
        
        service.characteristics?.forEach({ characteristic in
            if let descriptors = characteristic.descriptors {
                print("DESCRIPTORS \(descriptors)")
            }
            let outString = "y"
            var data = outString.data(using: String.Encoding.ascii)
           
            for characteristic in service.characteristics! as [CBCharacteristic]{
                if(characteristic.uuid.uuidString == "FFE1")
                {
                    if (peripheral.state.rawValue == 2){
                    print("sending data")
                    peripheral.writeValue(data ?? Data() ,
                                          for: characteristic,
                                          type: CBCharacteristicWriteType.withoutResponse)
                        let noString = "n"
                        sleep(1)
                        data = noString.data(using: String.Encoding.ascii)
                        peripheral.writeValue(data ?? Data() ,
                                              for: characteristic,
                                              type: CBCharacteristicWriteType.withoutResponse)
                        sleep(1)
                        data = noString.data(using: String.Encoding.ascii)
                        peripheral.writeValue(data ?? Data() ,
                                              for: characteristic,
                                              type: CBCharacteristicWriteType.withoutResponse)
                        
                    }
                    
                    
                }
            }
            print("CHARACTERISTIC : \(characteristic.uuid.uuidString)")
            print(characteristic.properties)
            
        })
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
            self.disconnectFromDevice(peripheral)    })
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
            self.disconnectFromDevice(peripheral)
        })
        
    }

    func disconnectFromDevice (_ peripheral: CBPeripheral ) {
        if peripheral != nil {
            centralManager?.cancelPeripheralConnection(peripheral)
        }
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
        //Initialize CoreBluetooth Central Manager
        centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.main)
        
        // Connect data:
        self.BTPicker.delegate = self
        self.BTPicker.dataSource = self
        BTPicker.reloadAllComponents()
        
        //userDefs.removeObject(forKey: "btdevice")  // use to remove value you added
        currentBTDevice = userDefs.string(forKey:"btdevice")
        if (currentBTDevice != nil){
            print (currentBTDevice!)
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

