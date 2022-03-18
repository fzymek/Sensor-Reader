//
//  CBPeripheral+Extensions.swift
//  Sensor Reader
//
//  Created by Filip Zymek on 18/03/2022.
//

import Foundation
import CoreBluetooth

extension CBPeripheral {
    var displayName: String {
        return name ?? identifier.uuidString
    }
}
