//
//  Sensor_ReaderApp.swift
//  Sensor Reader
//
//  Created by Filip Zymek on 09/03/2022.
//

import SwiftUI
import UIKit
import CoreBluetooth
import CocoaLumberjackSwift

@main
struct Sensor_ReaderApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    private let btService = BluetoothLEService()
    
    var body: some Scene {
        WindowGroup {
            ContentView(ViewModel(btService))
        }
    }
    
}


class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
          
        let fileLogger = DDFileLogger()
        fileLogger.rollingFrequency = 60 * 60 * 24
        fileLogger.logFileManager.maximumNumberOfLogFiles = 3
        DDLog.add(fileLogger)
        DDLog.add(DDOSLogger.sharedInstance)
        
        return true
    }
    
}
