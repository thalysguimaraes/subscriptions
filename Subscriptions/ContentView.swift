//
//  ContentView.swift
//  Subscriptions
//
//  Created by Thalys Guimarães on 29/12/23.
//

import SwiftUI

struct ContentView: View {
    @State private var showModal = false
    @StateObject var subscriptionManager = SubscriptionManager()
    

    var body: some View {
        TabView {
            NavigationView {
                VStack {
                    if subscriptionManager.subscriptions.isEmpty {
                        EmptyStateView(showModal: $showModal)
                            .environmentObject(subscriptionManager)
                    } else {
                        SubscriptionSum(subscriptionManager: subscriptionManager)
                        List {
                            ForEach(subscriptionManager.subscriptions, id: \.id) { subscription in
                                SubscriptionCard(subscriptionManager: subscriptionManager, subscription: subscription)
                            }
                            .onDelete(perform: deleteSubscription)
                        }
                    }
                }
                .navigationTitle("Subscriptions")
                .navigationBarTitleDisplayMode(.large)
                .navigationBarItems(trailing: addButton)
                .onAppear {
                    subscriptionManager.fetchSubscriptions()
                }
            }
            .tabItem {
                Image(systemName: "list.bullet")
                Text("Subscriptions")
            }
            
            AnalyticsView(subscriptionManager: subscriptionManager)
                            .tabItem {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                Text("Analytics")
                }
            SettingsView(subscriptionManager: subscriptionManager)

        .tabItem {
            Image(systemName: "gearshape.fill")
            Text("Settings")
        }
}
        .accentColor(Color.purple)
        .onAppear {
            subscriptionManager.fetchSubscriptions()
        }
    }

    var addButton: some View {
        Button(action: {
            showModal = true
        }) {
            Text("Add new").bold()
        }
        .sheet(isPresented: $showModal) {
            SubscriptionView(subscriptionManager: subscriptionManager,
                             subscription: Subscription(name: "",
                                                        price: 0.0,
                                                        currency: "R$",
                                                        cycle: "Monthly",
                                                        startDate: Date(),
                                                        remindMe: false,
                                                        priceInBRL: 0.0),
                             isEditMode: false)
        }
    }

    private func deleteSubscription(at offsets: IndexSet) {
        offsets.forEach { index in
            let subscriptionToDelete = subscriptionManager.subscriptions[index]
            subscriptionManager.deleteSubscription(subscriptionToDelete)
        }
    }
}

struct EmptyStateView: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @Binding var showModal: Bool
    
    var body: some View {
        VStack {
            Spacer()
            ColorAnimationView()
                .padding(.bottom, 32.0)
            Text("You still don't have any\n subscriptions added")
                .foregroundColor(.secondary)
                .font(.headline)
                .multilineTextAlignment(.center)
            
            Magical3DButton(
                label: "Add new",
                borderColor: Color(red: 0.3, green: 0, blue: 0.4),
                bodyColor: .purple,
                width: 120,
                height: 50,
                textColor: .white,
                shadowColor: Color(red: 0.3, green: 0, blue: 0.4),
                action: {
                showModal = true
            }
            )

            Spacer()
        }
        .offset(y: -24)
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
