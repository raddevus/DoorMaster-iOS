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
    @IBOutlet var currentDeviceName : UILabel!
    
    @IBOutlet weak var BTPicker: UIPickerView!
   
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        textDiagnostics.text += "* centralMgr DidUpdateState() *\n"
  
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
            if (!BTDevices.contains(peripheral.name!)){
                BTDevices.append(peripheral.name!)
            }
            if (!peripherals.contains(peripheral)){
                
                peripherals.append(peripheral)
                textDiagnostics.text += "peripheral added: \(peripheral.name!)\n"
            }
            
        }
        else{
            // 2022-07-10 No longer show devices with no name
            // BTDevices.append("no device name")
            textDiagnostics.text += "\(peripheral.identifier)"
        }
       
        
        BTPicker.reloadAllComponents()
        setUserBtDevice()
        
    }
    
    @IBAction func ScanForBluetooth(sender: UIButton){
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
        textDiagnostics.text += "peripherals.count : \(peripherals.count)\n"
        
        currentPeripheral = getCurrentPeripheral()
        if (currentPeripheral == nil){
            textDiagnostics.text += "### Couldn't get BT Device! ###\n"
            return;
        }
        textDiagnostics.text += "CONNECT\n"
        centralManager?.connect(currentPeripheral, options: nil)
        textDiagnostics.text += "called it!\n"
    }
    
    func getCurrentPeripheral() -> CBPeripheral!{
        for btItem in peripherals{
            textDiagnostics.text += "XXX btItem \(btItem.name!) currentDeviceName.text \(currentDeviceName.text!) XXX\n"
            if (btItem.name! == currentDeviceName.text!){
                textDiagnostics.text += "ZZZ got one!!!  ZZZ\n"
                return btItem;
            }
        }
        return nil;
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        textDiagnostics.text += "************************\n"
        textDiagnostics.text += "Connection complete"
        textDiagnostics.text += "Peripheral info: \(currentPeripheral!)\n"
        
        //Stop Scan- We don't need to scan once we've connected to a peripheral. We got what we came for.
        centralManager?.stopScan()
        textDiagnostics.text += "Scan Stopped\n"
        
        //Erase data that we might have
        data.length = 0
        
        //Discovery callback
        peripheral.delegate = self
        //Only look for services that matches transmit uuid
        peripheral.discoverServices(nil)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        textDiagnostics.text += "\(central.description) -- \(error!.localizedDescription)"
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        textDiagnostics.text += "*********************************\n"
        
        if ((error) != nil) {
            textDiagnostics.text += "Error discovering services: \(error!.localizedDescription)\n"
            return
        }
        
        guard let services = peripheral.services else {
            return
        }
        //We need to discover the all characteristic
        for service in services {
            
            peripheral.discoverCharacteristics(nil, for: service)
        }
        textDiagnostics.text += "Discovered Services:\(services)\n"
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        if let error = error {
            textDiagnostics.text += "Error discovering service characteristics: \(error.localizedDescription)\n"
        }
        
        service.characteristics?.forEach({ characteristic in
            if let descriptors = characteristic.descriptors {
                textDiagnostics.text += "DESCRIPTORS \(descriptors)\n"
            }
            let outString = "y"
            var data = outString.data(using: String.Encoding.ascii)
           
            for characteristic in service.characteristics! as [CBCharacteristic]{
                if(characteristic.uuid.uuidString == "FFE1")
                {
                    if (peripheral.state.rawValue == 2){
                        textDiagnostics.text += "SENDING data\n"
                    peripheral.writeValue(data ?? Data(),
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
                else if (characteristic.uuid.uuidString == "2A19") {
                    textDiagnostics.text += "writing data...\n"
                    peripheral.writeValue(data ?? Data() ,
                                          for: characteristic,
                                          type: CBCharacteristicWriteType.withoutResponse)
                }
                else{
                    textDiagnostics.text += "uuid :  \(characteristic.uuid.uuidString)\n"
                }
            }
            textDiagnostics.text += "CHARACTERISTIC : \(characteristic.uuid.uuidString)\n"
            textDiagnostics.text += "\(characteristic.properties)\n"
            
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
    
    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverIncludedServicesFor service:CBService,
                    error: Error?){
        textDiagnostics.text += "Peripheral error: \(error!.localizedDescription)\n"
    }

    func disconnectFromDevice (_ peripheral: CBPeripheral ) {
        centralManager?.cancelPeripheralConnection(peripheral)
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
            self.centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.main)
        
        // Connect data:
        self.BTPicker.delegate = self
        self.BTPicker.dataSource = self
        BTPicker.reloadAllComponents()
            textDiagnostics.text += "Loading picker...\n"
        //userDefs.removeObject(forKey: "btdevice")  // use to remove value you added
        currentBTDevice = userDefs.string(forKey:"btdevice")
        if (currentBTDevice != nil){
            currentDeviceName.text = currentBTDevice;
            print (currentBTDevice!)
        }
            
        setUserBtDevice()
        
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
            return BTDevices[row]
    }
    
    func setUserBtDevice(){
        let itemIndex = getUserSavedBTDevice();
        //textDiagnostics.text += "got userSavedDevice : \(itemIndex)\n"
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
        currentDeviceName.text = BTDevices[row]
        
    }


}

