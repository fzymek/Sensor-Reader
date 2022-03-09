//
//  BluetoothLEService.swift
//  Sensor Reader
//
//  Created by Filip Zymek on 09/03/2022.
//

import Foundation
import CoreBluetooth
import SwiftUI

class BluetoothLEService: NSObject, ObservableObject {
    
    @Published var state: CBManagerState?
    
    private var centralManager: CBCentralManager?
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
}

extension BluetoothLEService: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        self.state = central.state
        
        if central.state == .poweredOn {
//            startScanning()
        } else {
            //do smth else
        }
    }
    
}
