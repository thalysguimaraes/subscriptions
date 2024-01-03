//
//  Magical3DButton.swift
//  Subscriptions
//
//  Created by Thalys Guimarães on 29/12/23.
//

import SwiftUI

import SwiftUI

struct Magical3DButton: View {
    var label: String
    var borderColor: Color
    var bodyColor: Color
    var width: CGFloat
    var height: CGFloat
    var textColor: Color
    var shadowColor: Color
    @State private var offset: Double = 0
    var action: () -> Void  // Closure for the action

    var body: some View {
        Button(action: {
            action() // Execute the passed closure
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .foregroundColor(borderColor)
                    .offset(x: 0, y: 4)
                    .shadow(color: shadowColor, radius: 1, x: 0, y: 3 - offset)
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .foregroundColor(bodyColor)
                    Text(label)
                        .bold()
                        .fontDesign(.rounded)
                        .foregroundColor(textColor)
                }
                .offset(x: 0, y: offset)
            }
        }
        .frame(width: width, height: height)
        .padding()
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { isPressing in
            withAnimation(.spring()) {
                offset = isPressing ? 3 : 0
            }
        }, perform: {})
    }
}


