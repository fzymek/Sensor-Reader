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
    
    
    func startScanning() {
        centralManager?.scanForPeripherals(withServices: nil, options: nil)
    }
    
}

extension BluetoothLEService: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        self.state = central.state
        
        if central.state == .poweredOn {
            startScanning()
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("\(peripheral), \(peripheral.services)")
    }
}

extension BluetoothLEService: CBPeripheralDelegate {
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to \(peripheral)")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("Finished service discovery with error \(error?.localizedDescription ?? "")")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverIncludedServicesFor service: CBService, error: Error?) {
        print("discovered service: \(service)")
        
    }
    
}
