//
//  Subscription.swift
//  Subscriptions
//
//  Created by Thalys Guimarães on 02/01/24.
//

import Foundation

// Subscription model
struct Subscription: Identifiable {
    var id: UUID
    var serviceLogo: Data?
    var name: String
    var price: Double
    var currency: String
    var cycle: String
    var startDate: Date
    var remindMe: Bool
    var priceInBRL: Double
    var reminderDate: Date?
    
    // Custom initializer for new subscriptions
    init(id: UUID = UUID(), serviceLogo: Data? = nil, name: String, price: Double, currency: String, cycle: String, startDate: Date, remindMe: Bool, priceInBRL: Double, reminderDate: Date? = nil) {
        self.id = id
        self.serviceLogo = serviceLogo
        self.name = name
        self.price = price
        self.currency = currency
        self.cycle = cycle
        self.startDate = startDate
        self.remindMe = remindMe
        self.priceInBRL = priceInBRL
        self.reminderDate = reminderDate
    }
    
    // Initializer to create Subscription from SubscriptionEntity
    init(entity: SubscriptionEntity) {
        self.id = entity.id ?? UUID()
        self.serviceLogo = entity.serviceLogo
        self.name = entity.name ?? ""
        self.price = entity.price
        self.currency = entity.currency ?? ""
        self.cycle = entity.cycle ?? ""
        self.startDate = entity.startDate ?? Date()
        self.remindMe = entity.remindMe
        self.priceInBRL = entity.priceInBRL
        self.reminderDate = entity.reminderDate
    }
    
    // isActive computed property
    var isActive: Bool {
        let calendar = Calendar.current
        let today = Date()
        
        guard startDate <= today else { return false }
        
        let nextRenewalDate: Date
        if cycle == "Monthly" {
            nextRenewalDate = calendar.date(byAdding: .month, value: 1, to: startDate) ?? Date.distantFuture
        } else { // Assuming "Yearly"
            nextRenewalDate = calendar.date(byAdding: .year, value: 1, to: startDate) ?? Date.distantFuture
        }
        
        return nextRenewalDate > today
    }

    func priceInBRL(conversionRate: Double) -> Double {
        if currency == "USD" {
            return price * conversionRate
        } else {
            return price
        }
    }
}

extension SubscriptionEntity {
    func updateWithSubscription(_ subscription: Subscription) {
        self.id = subscription.id
        self.serviceLogo = subscription.serviceLogo
        self.name = subscription.name
        self.price = subscription.price
        self.currency = subscription.currency
        self.cycle = subscription.cycle
        self.startDate = subscription.startDate
        self.remindMe = subscription.remindMe
        self.priceInBRL = subscription.priceInBRL
        self.reminderDate = subscription.reminderDate
    }
}
