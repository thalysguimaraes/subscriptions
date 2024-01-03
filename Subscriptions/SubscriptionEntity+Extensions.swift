//
//  SubscriptionEntity+Extensions.swift
//  Subscriptions
//
//  Created by Thalys Guimarães on 02/01/24.
//

import CoreData

extension SubscriptionEntity {
    func update(from subscription: Subscription) {
        self.id = subscription.id
        self.serviceLogo = subscription.serviceLogo
        self.name = subscription.name
        self.price = subscription.price
        self.currency = subscription.currency
        self.cycle = subscription.cycle
        self.startDate = subscription.startDate
        self.remindMe = subscription.remindMe
    }
}
