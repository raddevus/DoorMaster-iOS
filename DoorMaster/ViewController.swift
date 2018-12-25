//
//  ViewController.swift
//  DoorMaster
//
//  Created by roger deutsch on 12/25/18.
//  Copyright © 2018 Roger Deutsch. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
        
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return BTDevices.count
    }
    
    let userDefs = UserDefaults.standard
    var BTDevices : [String] = [String]()
    var currentBTDevice : String!
    
    @IBOutlet weak var BTPicker: UIPickerView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Connect data:
        self.BTPicker.delegate = self
        self.BTPicker.dataSource = self
        
        BTDevices = ["Item 1", "Item 2", "Item 3", "Item 4", "Item 5", "Item 6"]
        
        currentBTDevice = userDefs.string(forKey:"btdevice")
        if (currentBTDevice != nil){
            print (currentBTDevice)
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
            return BTDevices[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        userDefs.set(BTDevices[row], forKey:"btdevice")
        userDefs.synchronize()
        print(BTDevices[row])
        
    }


}

