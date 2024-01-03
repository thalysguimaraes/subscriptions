//
//  SubscriptionCard.swift
//  Subscriptions
//
//  Created by Thalys Guimarães on 30/12/23.
//

import SwiftUI

struct SubscriptionCard: View {
    @ObservedObject var subscriptionManager: SubscriptionManager
    let subscription: Subscription
    @State private var showEditView = false
    
    var body: some View {
        Button(action: {
            showEditView = true
        }) {
            HStack {
                if let data = subscription.serviceLogo, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    Image(systemName: "photo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                VStack(alignment: .leading) {
                    Text(subscription.name).font(.headline)
                        .offset(y: 3)
                    
                    VStack(alignment: .leading) {
                        Text(subscription.cycle)
                            .font(.caption)
                            .foregroundColor(.accentColor)
                            .bold()
                        Text("Renews in \(daysUntilRenewal(from: subscription.startDate, cycle: subscription.cycle)) days")
                            .offset(y: -2)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .offset(y: -3)
                    .padding(.top, 0.1)
                }
                .padding(.leading, 8)

                Spacer()

                Text("\(formattedPrice())")
                    .font(.subheadline)
                    .foregroundStyle(Color.accentColor)
                    .bold()
            }
        }
        .sheet(isPresented: $showEditView) {
            SubscriptionView(subscriptionManager: subscriptionManager, subscription: subscription, isEditMode: true)
        }
    }
    
    func daysUntilRenewal(from startDate: Date, cycle: String) -> Int {
        let calendar = Calendar.current
        let nextRenewalDate = calculateNextRenewalDate(for: startDate, withCycle: cycle)
        let today = Date()
        return calendar.dateComponents([.day], from: today, to: nextRenewalDate).day ?? 0
    }

    private func calculateNextRenewalDate(for startDate: Date, withCycle cycle: String) -> Date {
        let calendar = Calendar.current
        var nextRenewalDate = startDate

        while nextRenewalDate <= Date() {
            if cycle == "Monthly" {
                nextRenewalDate = calendar.date(byAdding: .month, value: 1, to: nextRenewalDate) ?? Date()
            } else { // Assuming "Yearly"
                nextRenewalDate = calendar.date(byAdding: .year, value: 1, to: nextRenewalDate) ?? Date()
            }
        }
        return nextRenewalDate
    }
    
    private func formattedPrice() -> String {
        let priceString = String(format: "%.2f", subscription.price)
        let currencySymbol = currencySymbol(subscription.currency)
        return "\(currencySymbol)\(priceString)"
    }
    
    private func currencySymbol(_ currency: String) -> String {
        switch currency {
        case "R$":
            return "R$"
        case "$":
            return "$"
        default:
            return currency // Fallback in case of an unexpected value
        }
    }
}
