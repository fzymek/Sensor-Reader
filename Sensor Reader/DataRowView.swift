//
//  DataRowView.swift
//  Sensor Reader
//
//  Created by Filip Zymek on 18/03/2022.
//

import Foundation
import SwiftUI

struct DataRow: View {
    let title: String
    let value: String?
    let unit: String
    
    var body: some View {
        HStack {
            Text("\(title)")
            Spacer()
            Text("\(value ?? "--") \(unit)")
        }
        .padding()
        .foregroundColor(valueTextColor(hasData: value != nil))
    }
    
    private func valueTextColor(hasData: Bool) -> Color {
        return hasData ? Color.green : Color.red
    }
}


struct DataRow_Preview: PreviewProvider {
    static var previews: some View {
        Group {
            DataRow(title: "Temperature:", value: "50", unit: " \u{2103}")
        }
    }
}
