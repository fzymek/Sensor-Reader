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

    }
    
    @Published var stateDescription: String = ""
    
}

struct ContentView: View {
    
    @ObservedObject private var viewModel: ViewModel
    
    init(_ service: BluetoothLEService) {
        viewModel = ViewModel(service)
    }
    
    var body: some View {
        VStack {
            Text("Hello, world!")
                .font(.title)
                .foregroundColor(Color.red)
                .padding()
        
            Text("BT service state \(viewModel.stateDescription)")
                    .padding()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(BluetoothLEService())
    }
}
