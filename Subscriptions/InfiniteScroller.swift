//
//  InfiniteScroller.swift
//  Subscriptions
//
//  Created by Thalys Guimarães on 29/12/23.
//

import SwiftUI

struct ColorAnimationView: View {

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size.width / 4

            InfiniteScroller(contentWidth: size * 4) {
                HStack(spacing: 0) {
                    ColorView(size: size, color: Color.purple.opacity(0.3), symbolName: "gamecontroller.fill")
                    ColorView(size: size, color: Color.purple.opacity(0.2), symbolName: "tv.inset.filled")
                    ColorView(size: size, color: Color.purple.opacity(0.3), symbolName: "music.quarternote.3")
                    ColorView(size: size, color: Color.purple.opacity(0.2), symbolName: "car.fill")

                }
            }
        }
        .frame(height: 100.0)
    }
}

struct ColorView: View {
    var size: CGFloat
    var color: Color
    var symbolName: String

    var body: some View {
        VStack {
            Image(systemName: symbolName)
            .resizable()
            .scaledToFit()
            .frame(width: size * 0.6, height: size * 0.6)
            .foregroundColor(.purple)  // add color for your SF Symbol here
        }
        .frame(width: size, height: size, alignment: .center)
        .background(color)
    }
}


struct InfiniteScroller<Content: View>: View {
    var contentWidth: CGFloat
    var content: (() -> Content)
    
    @State
    var xOffset: CGFloat = 0

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    content()
                    content()
                }
                .offset(x: xOffset, y: 0)
        }
        .disabled(true)
        .onAppear {
            withAnimation(.linear(duration: 5).repeatForever(autoreverses: false)) {
                xOffset = -contentWidth
            }
        }
    }
}
