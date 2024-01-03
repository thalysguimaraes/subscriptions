//
//  SubscriptionSum.swift
//  Subscriptions
//
//  Created by Thalys Guimarães on 02/01/24.
//

import SwiftUI
import Combine

struct SubscriptionSum: View {
    @ObservedObject var subscriptionManager: SubscriptionManager
    @State private var selectedCurrency: String = "USD"
    @State private var conversionRate: Double = 0.20
    @State private var isLoading = false
    @State private var error: Error?
    @State private var cancellables = Set<AnyCancellable>()
    
    var body: some View {
        HStack {
            Image(systemName: "dollarsign.circle.fill")
                .foregroundColor(.white)
                .font(.title3)
            
            VStack(alignment: .leading) {
                Text("Cost (this month)")
                    .font(.subheadline)
                    .foregroundColor(.white)
                if isLoading {
                    ProgressView()
                } else if let error = error {
                    Text("Error fetching rates: \(error.localizedDescription)")
                } else {
                    Text(formatCurrency(convertedMonthlyCost(), currency: selectedCurrency))
                        .contentTransition(.numericText())
                        .font(.title2)
                        .bold()
                        .foregroundColor(.white)
                }
            }
            .padding(.leading, 8)
            
            Spacer()
            
            Picker("Currency", selection: $selectedCurrency) {
                Text("R$").tag("BRL")
                Text("$").tag("USD")
            }
            .pickerStyle(SegmentedPickerStyle())
            .frame(width: 100)
        }
        .padding()
        .background(Color.purple)
        .cornerRadius(10)
        .padding()
        .onAppear(perform: fetchConversionRate)
    }

    // Custom function to format the currency
    private func formatCurrency(_ amount: Double, currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: currency == "USD" ? "en_US" : "pt_BR")
        
        if currency == "USD" {
            formatter.currencySymbol = "$"
        } else if currency == "BRL" {
            formatter.currencySymbol = "R$"
            formatter.positiveFormat = "¤#,##0.00" // ¤ is the placeholder for the currency symbol
            formatter.negativeFormat = "-¤#,##0.00"
        }

        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
    }

    
    private func fetchConversionRate() {
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
                isLoading = false
                if case .failure(let error) = completion {
                    self.error = error
                    print("Error: \(error.localizedDescription)")
                }
            } receiveValue: { response in
                self.conversionRate = response.rates["BRL"] ?? 0.20
                print("Conversion Rate: \(self.conversionRate)")
            }
            .store(in: &cancellables)
    }
    
    
    private func apiCurrencyCode(for appCurrencyCode: String) -> String {
        switch appCurrencyCode {
        case "R$":
            return "BRL"
        case "$", "USD":
            return "USD"
        default:
            return appCurrencyCode
        }
    }
    
    private func convertedMonthlyCost() -> Double {
        let totalUSD = monthlyCost()
        // If selected currency is USD, return the total as is.
        // If it's BRL, convert it from USD to BRL.
        return selectedCurrency == "USD" ? totalUSD : totalUSD * conversionRate
    }
    
    private func monthlyCost() -> Double {
        subscriptionManager.subscriptions.reduce(0) { sum, subscription in
            let monthlyPrice = subscription.cycle == "Monthly" ? subscription.price : subscription.price / 12
            // If the subscription is in BRL, convert it to USD.
            // If it's already in USD, use it as is.
            let monthlyPriceInUSD = subscription.currency == "R$" ? monthlyPrice / conversionRate : monthlyPrice
            return sum + monthlyPriceInUSD
        }
    }
    
    struct RatesExchangeResponse: Codable {
        let base: String
        let rates: [String: Double]
    }
}
