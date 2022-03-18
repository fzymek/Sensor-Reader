//
//  BluetoothLEService.swift
//  Sensor Reader
//
//  Created by Filip Zymek on 09/03/2022.
//

import Foundation
import CoreBluetooth
import SwiftUI
import CocoaLumberjackSwift

class BluetoothLEService: NSObject, ObservableObject {
    
    let advertismentManufacturerDataKey = "kCBAdvDataManufacturerData"
    
    @Published var state: CBManagerState?
    @Published var iNodeAdvertismentDataFrame: Data?
    @Published var iNodeRSSI: NSNumber = 0
    
    private var centralManager: CBCentralManager?
    
    
    /*
    private var sensor: CBPeripheral!
    private var numberOfServices = 0
    private var numberOfCharacteristics = 0
    private var serviceCharacteristicsMap: [CBService: [CBCharacteristic]] = [:]
    private var characteristicDescriptorMap: [CBCharacteristic: [CBDescriptor]] = [:]
     */
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    
    func startScanning() {
        DDLogInfo("Starting BT Scan...")
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
        DDLogInfo("Found \(peripheral.displayName), \(RSSI) dB")
        if let name = peripheral.name, name == "iNode-4412D2" {
            DDLogInfo("Ad data for \(peripheral.displayName) = \(advertisementData)")
            self.iNodeAdvertismentDataFrame = advertisementData[advertismentManufacturerDataKey] as? Data
            self.iNodeRSSI = RSSI
        }
    }
    
    private func decodeManufacturerData(_ data: Data?) {
    }
}

// Following code is not needed at the moment
// Basic data can be decoded from advertisment frame
// This code is a ground work for later use when I can connect to peripheral and talk directly to it instead of just using broadcast data
/*
extension BluetoothLEService: CBPeripheralDelegate {
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        DDLogInfo("Connected to \(peripheral.displayName)")
        sensor = peripheral
        sensor.delegate = self
        
        discoveredDevices.removeAll()
        
        DDLogInfo("Starting service discovery for \(sensor.displayName)")
        sensor.discoverServices(nil)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        DDLogInfo("Disconnected from \(peripheral.displayName)")
        if let error = error {
            DDLogInfo("Error: \(error.localizedDescription)")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        DDLogInfo("Failed connection to \(peripheral.displayName) due to \(error?.localizedDescription ?? "Unknown error")")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        DDLogInfo("Discovered services for \(peripheral.displayName)")
        
        guard let services = peripheral.services else {
            DDLogInfo("No services found for \(peripheral.displayName), disconnecting...")
            sensor = nil
            return
        }
        
        numberOfServices = services.count
        for s in services {
            DDLogInfo("Discovering characteristics for service \(s.description) on peripheral: \(peripheral.displayName)")
            peripheral.discoverCharacteristics(nil, for: s)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        if let error = error {
            DDLogInfo("Disconnecting due to error when discovering characteristics for service \(service.description). Error: \(error.localizedDescription)")
            sensor = nil
        }
        
        DDLogInfo("Discovered characteristics for service \(service.description) on \(peripheral.displayName)")
        guard let characteristics = service.characteristics else {
            DDLogInfo("No characteristics found for \(service.description), disconnecting...")
            sensor = nil
            return
        }
        
        serviceCharacteristicsMap[service] = characteristics
        numberOfCharacteristics += characteristics.count
        
        if serviceCharacteristicsMap.keys.count == numberOfServices {
            for (service, char) in serviceCharacteristicsMap {
                for c in char {
                    peripheral.discoverDescriptors(for: c)
                }
            }
        }
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            DDLogInfo("Error when scanning for descriptors of \(characteristic.uuid). Error: \(error.localizedDescription)")
            return
        }
        
        guard let descriptors = characteristic.descriptors else {
            DDLogInfo("No descriptors found found for \(characteristic.uuid)")
            return
        }
        
        characteristicDescriptorMap[characteristic] = descriptors
        
        if characteristicDescriptorMap.keys.count == numberOfCharacteristics {
            for (s, chars) in serviceCharacteristicsMap {
                DDLogInfo("Service: \(s.uuid)")
                for c in chars {
                    DDLogInfo("Characteristic: \(c.uuid) -> value \(String(describing: c.value))")
                    for d in characteristicDescriptorMap[c] ?? [] {
                        DDLogInfo("Descriptor: \(d.uuid)")
                    }
                    peripheral.readValue(for: c)
                }
            }
            
            DDLogInfo("Start reading values of characteristis ...")
            for c in characteristicDescriptorMap.keys {
                peripheral.readValue(for: c)
            }
            
            sensor = nil
        }
    
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            DDLogInfo("Error when reading value of \(characteristic.uuid). Error: \(error.localizedDescription)")
            return
        }
        
        guard let value = characteristic.value else {
            DDLogInfo("No value found for \(characteristic.uuid)")
            return
        }
        
        DDLogInfo("Value of \(characteristic.uuid) = \(String(data: value, encoding: .utf8) ?? "unknown")")
    }
        
}




 
*/
