//
//  ViewModifiers.swift
//  Sensor Reader
//
//  Created by Filip Zymek on 18/03/2022.
//

import Foundation
import SwiftUI


struct CardWithShadow: ViewModifier {
    func body(content: Content) -> some View {
        return
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.04), radius: 4)
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.gray, lineWidth: 1)
                content
            }
    }
}
