//
//  ContentView.swift
//  Sensor Reader
//
//  Created by Filip Zymek on 09/03/2022.
//

import SwiftUI
import Combine
import CoreBluetooth

class ViewModel: ObservableObject {
    
    private var cancellables: Set<AnyCancellable> = Set()
    
    init(_ service: BluetoothLEService) {
        service.$state.map {
            switch $0 {
            case .poweredOn:
                return "Powered On"
            case .poweredOff:
                return "Powered Off"
            case .resetting:
                return "Resetting"
            case .unauthorized:
                return "Unauthorized"
            case .unknown:
                return "Unknown"
            case .unsupported:
                return "Unsupported"
            default:
                return "Default"
            }
        }
        .receive(on: RunLoop.main)
        .assign(to: \ViewModel.stateDescription, on: self)
        .store(in: &cancellables)
        
        
        service.$iNodeAdvertismentDataFrame.filter {
            $0 != nil
        }
        .receive(on: RunLoop.main)
        .assign(to: \ViewModel.dataFrame, on: self)
        .store(in: &cancellables)

    }
    
    @Published var dataFrame: Data?
    @Published var stateDescription: String = ""
    
}

struct ContentView: View {
    
    @ObservedObject var viewModel: ViewModel
    
    init(_ service: BluetoothLEService) {
        viewModel = ViewModel(service)
    }
    
    var body: some View {
        VStack {
            if let data = viewModel.dataFrame {
                let decoder = iNodeCareSensorHTDataDecoder(data: data)
                let temp = decoder.temperature?.decimalString
                let hum = decoder.humidity?.decimalString
                let battery = decoder.batteryLevel?.decimalString
                let voltage = decoder.batteryVoltage?.decimalString
                
                Text("Ostatni odczyt z czujnika")
                    .font(.title)
                
                ScrollView {
                    Spacer()
                    
                    VStack(spacing: 24) {
                        DataRow(title: "Temperatura:", value: temp, unit: " \u{2103}")
                            .modifier(CardWithShadow())
                        DataRow(title: "Wilgotność:", value: hum, unit: " %")
                            .modifier(CardWithShadow())
                        DataRow(title: "Poziom baterii:", value: battery, unit: " %")
                            .modifier(CardWithShadow())
                        DataRow(title: "Napięcie baterii:", value: voltage, unit: " V")
                            .modifier(CardWithShadow())
                    }
                    .padding(4)
                    
                    Spacer()
                    
                }.padding(.top, 8)
                
            } else {
                HStack {
                    Spacer()
                    ProgressView("Szukam czujnika...")
                    Spacer()
                }
            }
        }
        .padding([.leading, .trailing], 16)
    }    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(BluetoothLEService())
    }
}
