//
//  SubscriptionManager.swift
//  Subscriptions
//
//  Created by Thalys Guimarães on 02/01/24.
//

import Foundation
import CoreData
import Combine
import SwiftUI

class SubscriptionManager: ObservableObject {
    @Published var subscriptions: [Subscription] = []
    @Published var conversionRate: Double = 0.20 // Default conversion rate
    @Published var isLoading: Bool = false
    @Published var error: Error?
    @Published var subscriptionsInBRL: [UUID: Double] = [:]
    private var cancellables = Set<AnyCancellable>()
    private let context = PersistenceController.shared.container.viewContext
    private let currencyMap = ["R$": "BRL", "$": "USD"]
    
    
    enum SubscriptionCycle {
        case monthly
        case yearly
        
        static func fromString(_ string: String) -> SubscriptionCycle? {
            switch string.lowercased() {
            case "monthly":
                return .monthly
            case "yearly":
                return .yearly
            default:
                return nil
            }
        }
    }
    
    
    
    
    func updateSubscriptionsWithBRLValues() {
        for index in 0..<subscriptions.count {
            let conversionRate = self.conversionRate
            subscriptions[index].priceInBRL = subscriptions[index].currency == "USD" ? subscriptions[index].price * conversionRate : subscriptions[index].price
        }
    }
    
    
    func normalizedAmountFor(subscription: Subscription) -> Double {
        let currencyCode = currencyMap[subscription.currency] ?? "USD" // Default to USD
        if currencyCode == "USD" {
            return subscription.price * conversionRate
        } else {
            return subscription.price
        }
    }
    
    init() {
        fetchConversionRate()
    }
    
    
    // Fetch conversion rate from the API
    func fetchConversionRate() {
        isLoading = true
        error = nil
        
        let apiKey = "2b5fd9d2-6683-4acc-97b7-a9a4e85b2a7c" // Replace with your actual API key
        let urlString = "https://api.ratesexchange.eu/client/latest?apikey=\(apiKey)&base=USD&symbols=BRL"
        
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }
        
        URLSession.shared.dataTaskPublisher(for: url)
            .tryMap { output in
                guard let response = output.response as? HTTPURLResponse, response.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                return output.data
            }
            .decode(type: RatesExchangeResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink { completion in
                self.isLoading = false
                if case .failure(let error) = completion {
                    self.error = error
                    print("Error: \(error.localizedDescription)")
                }
            } receiveValue: { response in
                self.conversionRate = response.rates["BRL"] ?? 0.20
                print("Conversion Rate: \(self.conversionRate)")
            }
            .store(in: &cancellables)
        //updateSharedTotalCost() // Call after fetching conversion rate
    }
    
    
    // Total cost of active subscriptions in USD
    var totalCostInUSD: Double {
        subscriptions.filter { $0.isActive }.reduce(0) { sum, subscription in
            let monthlyPriceInUSD = subscription.currency == "R$" ? subscription.price / conversionRate : subscription.price
            return sum + monthlyPriceInUSD
        }
    }
    
    // Total cost of active subscriptions in BRL
    var totalCostInBRL: Double {
        totalCostInUSD * conversionRate
    }
    
    // Fetch Subscriptions from CoreData
    func fetchSubscriptions(forMonth month: Date? = nil) {
        let request: NSFetchRequest<SubscriptionEntity> = SubscriptionEntity.fetchRequest()
        do {
            let subscriptionEntities = try context.fetch(request)
            var filteredSubscriptions = [Subscription]()
            
            for entity in subscriptionEntities {
                guard let cycleString = entity.cycle,
                      let cycle = SubscriptionCycle.fromString(cycleString),
                      let startDate = entity.startDate else {
                    continue // Skip if cycle or startDate is not available
                }
                
                let renewalDates = calculateRenewalDates(from: startDate, cycle: cycle)
                if let month = month {
                    let calendar = Calendar.current
                    let startOfMonth = calendar.startOfDay(for: calendar.dateInterval(of: .month, for: month)!.start)
                    let endOfMonth = calendar.dateInterval(of: .month, for: month)!.end
                    
                    if renewalDates.contains(where: { $0 >= startOfMonth && $0 < endOfMonth }) {
                        filteredSubscriptions.append(Subscription(entity: entity))
                    }
                } else {
                    filteredSubscriptions.append(Subscription(entity: entity))
                }
            }
            
            self.subscriptions = filteredSubscriptions
        } catch {
            print("Fetch failed: \(error)")
        }
        //updateSharedTotalCost() // Call after fetching subscriptions
    }
    
    
    func calculateRenewalDates(from startDate: Date, cycle: SubscriptionCycle) -> [Date] {
        var dates: [Date] = [startDate]
        var nextDate = startDate
        let calendar = Calendar.current
        
        while nextDate <= Date() {
            switch cycle {
            case .monthly:
                nextDate = calendar.date(byAdding: .month, value: 1, to: nextDate)!
            case .yearly:
                nextDate = calendar.date(byAdding: .year, value: 1, to: nextDate)!
            }
            
            if nextDate <= Date() {
                dates.append(nextDate)
            }
        }
        
        return dates
    }
    
    
    
    // Helper method to fetch data for a selected month
    func fetchDataForSelectedMonth(selectedMonth: Date) {
        fetchSubscriptions(forMonth: selectedMonth)
    }
    
    // Add a new Subscription
    func addSubscription(_ subscription: Subscription) {
        if !subscriptions.contains(where: { $0.id == subscription.id }) {
            let newSubscriptionEntity = SubscriptionEntity(context: context)
            newSubscriptionEntity.updateWithSubscription(subscription)
            saveContext()
            subscriptions.append(subscription)
        } else {
            // Handle the case where a subscription with the same UUID already exists
            print("Duplicate subscription detected: \(subscription.id)")
        }
    }

    
    // Update an existing Subscription
    func updateSubscription(_ subscription: Subscription) {
        let request: NSFetchRequest<SubscriptionEntity> = SubscriptionEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", subscription.id as CVarArg)
        do {
            let results = try context.fetch(request)
            if let entityToUpdate = results.first {
                entityToUpdate.updateWithSubscription(subscription)
                saveContext()
                if let index = subscriptions.firstIndex(where: { $0.id == subscription.id }) {
                    subscriptions[index] = subscription // Update the subscriptions array
                }
            }
        } catch {
            print("Update failed: \(error)")
        }
        //updateSharedTotalCost() // Call after updating a subscription
    }
    
    // Delete a Subscription
    func deleteSubscription(_ subscription: Subscription) {
        let request: NSFetchRequest<SubscriptionEntity> = SubscriptionEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", subscription.id as CVarArg)
        do {
            let results = try context.fetch(request)
            if let entityToDelete = results.first {
                context.delete(entityToDelete)
                saveContext()
                if let index = subscriptions.firstIndex(where: { $0.id == subscription.id }) {
                    subscriptions.remove(at: index) // Remove from the subscriptions array
                }
            }
        } catch {
            print("Delete failed: \(error)")
        }
        //updateSharedTotalCost() // Call after deleting a subscription
    }
    
    // Save the context
    private func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
                print("Context saved successfully.")
            } catch {
                print("Error saving context: \(error)")
            }
        }
    }
}

struct RatesExchangeResponse: Codable {
    let base: String
    let rates: [String: Double]
}

extension SubscriptionManager {
    func isSubscriptionActive(_ subscription: Subscription, forMonth month: Date) -> Bool {
        let cycleString = subscription.cycle
        let startDate = subscription.startDate
        
        guard let cycle = SubscriptionCycle.fromString(cycleString) else {
            return false
        }
        
        let renewalDates = calculateRenewalDates(from: startDate, cycle: cycle)
        let calendar = Calendar.current
        let startOfMonth = calendar.startOfDay(for: calendar.dateInterval(of: .month, for: month)!.start)
        let endOfMonth = calendar.dateInterval(of: .month, for: month)!.end
        
        return renewalDates.contains(where: { $0 >= startOfMonth && $0 < endOfMonth })
    }
}

extension SubscriptionManager {
    func cleanSubscriptions() {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = SubscriptionEntity.fetchRequest()
        
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try context.execute(batchDeleteRequest)
            // After deleting, clear the subscriptions array
            subscriptions.removeAll()
            print("All subscriptions deleted successfully.")
        } catch {
            print("Error deleting subscriptions: \(error)")
        }
    }
}

extension SubscriptionManager {
    func updateSharedTotalCost() {
        // Calculate total cost
        let totalCost = totalCostInUSD // or totalCostInBRL based on your requirement
        
//        // Update shared UserDefaults
//        if let sharedDefaults = UserDefaults(suiteName: "group.com.nooma.Subscriptions") {
//            sharedDefaults.set(totalCost, forKey: "totalCost")
//        }
    }
}

extension SubscriptionManager {
    func isDataAvailableForMonth(_ month: Date) -> Bool {
        for subscription in subscriptions {
            if isSubscriptionActive(subscription, forMonth: month) {
                return true
            }
        }
        return false
    }
}

extension SubscriptionManager {
    func fetchSubscriptions(forMonth month: Date, completion: @escaping () -> Void) {
        // Fetch subscriptions logic
        // Call completion() when data fetching is done
    }

    func fetchConversionRate(completion: @escaping () -> Void) {
        // Fetch conversion rate logic
        // Call completion() when data fetching is done
    }
}
