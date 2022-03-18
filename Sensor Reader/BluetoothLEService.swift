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
    
    private var centralManager: CBCentralManager?
    private var discoveredDevices: Set<CBPeripheral> = Set()
    private var sensor: CBPeripheral!
    
    private var numberOfServices = 0
    private var numberOfCharacteristics = 0
    private var serviceCharacteristicsMap: [CBService: [CBCharacteristic]] = [:]
    private var characteristicDescriptorMap: [CBCharacteristic: [CBDescriptor]] = [:]
    
    private let queue: OperationQueue = {
        let q = OperationQueue()
        q.name = "scanning-queue"
        q.maxConcurrentOperationCount = 1
        return q
    }()
    
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
        discoveredDevices.insert(peripheral)
        if let name = peripheral.name, name == "iNode-4412D2" {
            DDLogInfo("Stopping scan. Connecting to \(peripheral.displayName)...")
            DDLogInfo("Ad data for \(peripheral.displayName) = \(advertisementData)")
            
            decodeManufacturerData(advertisementData[advertismentManufacturerDataKey] as? Data)
            
            centralManager?.stopScan()
            centralManager?.connect(peripheral, options: nil)
        }
    }
    
    private func decodeManufacturerData(_ data: Data?) {
        guard let data = data, data.count > 0 else {
            DDLogInfo("No advertisment data to decode. ")
            return
        }
        // https://docs.google.com/document/d/1hcBpZ1RSgHRL6wu4SlTq2bvtKSL5_sFjXMu_HRyWZiQ/edit#heading=h.etvbnk7prj7v
        let groupsAndBatteryData = data.subdata(in: 2..<4)
        let temperatureData = data.subdata(in: 8..<10)
        let humidityData = data.subdata(in: 10..<12)
//        let rawTime1Data = data.subdata(with: NSRange(13...14))
//        let rawTime2Data = data.subdata(with: NSRange(15...16))
        
        
        // Battery data
        let groupAndBatteryInt = groupsAndBatteryData.withUnsafeBytes { $0.load(as: UInt16.self) }
        let battery = (groupAndBatteryInt >> 12 ) & 0x0F
        let batteryLevel: Float
        if battery == 1 {
            batteryLevel = 100
        } else {
            batteryLevel = 10 * (Float(min(battery, 11)) - 1)
        }
        let batteryVoltage = (batteryLevel - 10) * 1.2 / 100 + 1.8
        
        DDLogInfo("Battery level \(batteryLevel)%, voltage: \(batteryVoltage) V")
        
        
        // temperature data
        let temperatureInt = temperatureData.withUnsafeBytes { $0.load(as: UInt16.self) }
        var temperature = (175.72 * Double(temperatureInt) * 4 / 65536) - 46.85
        if temperature < -30 { temperature = -30 }
        if temperature > 70 { temperature = 70 }
        DDLogInfo(String(format: "Temperature: %.2f C", temperature))
        
        //humidity
        let rawHumidity = humidityData.withUnsafeBytes { $0.load(as: UInt16.self) }
        var humidity = (125 * Double(rawHumidity) * 4 / 65536) - 6
        if humidity < 1 { humidity = 1 }
        if humidity > 100 { humidity = 100 }
        DDLogInfo(String(format: "Humidity: %.2f %%", humidity))
        
    }
}

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



extension CBPeripheral {
    var displayName: String {
        return name ?? identifier.uuidString
    }
}



//<90 9b 01b0 0000 0000 cf19 2c13 0400 5231 c275071e d42c7afa>
