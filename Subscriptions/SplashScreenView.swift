//
//  SplashScreenView.swift
//  Subscriptions
//
//  Created by Thalys Guimarães on 02/01/24.
//

import SwiftUI

struct SplashScreenView: View {
    @State private var isActive = false
    @State private var size = 0.1
    @State private var opacity = 0.0
    
    var body: some View {
        
        if isActive {
            ContentView()
                .transition(.opacity)
        }
        
        else {
            ZStack {
                //Color.purple
                VStack {
                    Image("PreviewAppIconDefault")
                        .resizable()
                        .aspectRatio(contentMode: /*@START_MENU_TOKEN@*/.fill/*@END_MENU_TOKEN@*/)
                        .frame(width: 100, height: 100)
                        .cornerRadius(24)
                }
                .scaleEffect(size)
                .opacity(opacity)
                .onAppear {
                    withAnimation(.spring()) {
                        self.size = 1
                        self.opacity = 1
                    }
                }
            }
            .ignoresSafeArea(.all)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0)
                {
                    withAnimation {
                        self.isActive = true
                    }
                }
            }
        }
        
    }
}


#Preview {
    SplashScreenView()
}
