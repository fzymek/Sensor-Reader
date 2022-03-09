//
//  Sensor_ReaderApp.swift
//  Sensor Reader
//
//  Created by Filip Zymek on 09/03/2022.
//

import SwiftUI
import CoreBluetooth

@main
struct Sensor_ReaderApp: App {
    
    private let btService = BluetoothLEService()
    
    var body: some Scene {
        WindowGroup {
            ContentView(btService)
        }
    }
    
}
