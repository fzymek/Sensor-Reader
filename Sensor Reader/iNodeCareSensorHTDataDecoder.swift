//
//  iNodeCareSensorHTDataDecoder.swift
//  Sensor Reader
//
//  Created by Filip Zymek on 18/03/2022.
//

import Foundation

/// For BLE frame description see:
/// https://docs.google.com/document/d/1hcBpZ1RSgHRL6wu4SlTq2bvtKSL5_sFjXMu_HRyWZiQ/edit#heading=h.etvbnk7prj7v
struct iNodeCareSensorHTDataDecoder {
    private let batteryBytesDataRange = 2..<4
    private let temperatureBytesDataRange = 8..<10
    private let humidityBytesDataRange = 10..<12
    
    let data: Data?
    
    var temperature: Double? {
        guard let data = data else {
            return nil
        }
        
        let temperatureData = data.subdata(in: temperatureBytesDataRange)
        let temperatureInt = temperatureData.withUnsafeBytes { $0.load(as: UInt16.self) }
        var temperature = (175.72 * Double(temperatureInt) * 4 / 65536) - 46.85
        if temperature < -30 { temperature = -30 }
        if temperature > 70 { temperature = 70 }
        
        return temperature
    }
    
    var humidity: Double? {
        guard let data = data else {
            return nil
        }
        
        let humidityData = data.subdata(in: humidityBytesDataRange)
        let rawHumidity = humidityData.withUnsafeBytes { $0.load(as: UInt16.self) }
        var humidity = (125 * Double(rawHumidity) * 4 / 65536) - 6
        if humidity < 1 { humidity = 1 }
        if humidity > 100 { humidity = 100 }
        
        return humidity
    }
    
    var batteryLevel: Double? {
        guard let data = data else {
            return nil
        }
        
        let groupsAndBatteryData = data.subdata(in: batteryBytesDataRange)
        let groupAndBatteryInt = groupsAndBatteryData.withUnsafeBytes { $0.load(as: UInt16.self) }
        let battery = (groupAndBatteryInt >> 12 ) & 0x0F
        
        let batteryLevel: Double
        
        if battery == 1 {
            batteryLevel = 100
        } else {
            batteryLevel = 10 * (Double(min(battery, 11)) - 1)
        }
        return batteryLevel
    }
    
    var batteryVoltage: Double? {
        guard let level = batteryLevel else {
            return nil
        }
        
        let batteryVoltage = (level - 10) * 1.2 / 100 + 1.8
        return batteryVoltage
    }
}
