//
//  AnalyticsView.swift
//  Subscriptions
//
//  Created by Thalys Guimarães on 04/01/24.
//

import SwiftUI
import CoreData
import Charts

struct AnalyticsView: View {
    @ObservedObject var subscriptionManager: SubscriptionManager
    @State private var selectedMonth: Date = Date()
    @State private var currentConversionRate: Double = 0.20
    @State private var selectedCurrency: String = UserDefaults.standard.string(forKey: "defaultCurrency") ?? "USD"
    
    enum Timeframe: String, CaseIterable, Identifiable {
        case thisMonth = "This Month"
        case lastMonth = "Last Month"
        var id: String { self.rawValue }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 18) {
                    MonthNavigationView(selectedMonth: $selectedMonth)
                        .padding(.horizontal)
                        .background(Color(UIColor.secondarySystemBackground).opacity(0.6))
                        .cornerRadius(18)
                    
                    contentBasedOnSubscriptions()
                }
                .padding()
            }
            .background(Color(UIColor.systemBackground))
            .navigationBarTitle("Analytics", displayMode: .automatic)
            .onAppear {
                updateSelectedCurrency()
                fetchDataIfNeeded()
            }
            .onChange(of: selectedMonth) { _ in
                fetchDataIfNeeded()
            }
        }
    }
    
    private func fetchDataIfNeeded() {
        if !subscriptionManager.isDataAvailableForMonth(selectedMonth) {
            subscriptionManager.fetchDataForSelectedMonth(selectedMonth: selectedMonth)
        }
        updateSelectedCurrency()
    }
    
    private func updateSelectedCurrency() {
        if let storedCurrency = UserDefaults.standard.string(forKey: "defaultCurrency") {
            selectedCurrency = storedCurrency
        }
    }
    
    @ViewBuilder
    private func contentBasedOnSubscriptions() -> some View {
        if activeSubscriptionsForMonth.isEmpty {
            EmptyAnalytics()
        } else {
            analyticsContent()
        }
    }
    
    @ViewBuilder
    private func analyticsContent() -> some View {
        VStack(spacing: 24) {
            SpendingSummaryView(subscriptionManager: subscriptionManager,
                                selectedCurrency: selectedCurrency,
                                selectedMonth: selectedMonth)
            BarChartView(subscriptionManager: subscriptionManager,
                         month: selectedMonth,
                         selectedCurrency: selectedCurrency)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground).opacity(0.6))
        .cornerRadius(18)
        
        VStack {
            sectionHeader(symbol: "dollarsign.square.fill", title: "Subscriptions by currency")
            CurrencyChartView(subscriptionManager: subscriptionManager, month: selectedMonth, selectedCurrency: selectedCurrency)
                .padding()
                .cornerRadius(12)
        }
        .padding(.top, 18)
        .background(Color(UIColor.secondarySystemBackground).opacity(0.6))
        .cornerRadius(18)
    }
    
    private var activeSubscriptionsForMonth: [Subscription] {
        subscriptionManager.subscriptions.filter { subscription in
            subscriptionManager.isSubscriptionActive(subscription, forMonth: selectedMonth)
        }
    }
    
    private func fetchDataForSelectedMonth() {
        subscriptionManager.fetchDataForSelectedMonth(selectedMonth: selectedMonth)
        if let storedCurrency = UserDefaults.standard.string(forKey: "defaultCurrency") {
            selectedCurrency = storedCurrency
        }
    }
    
    private func sectionHeader(symbol: String, title: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: symbol)
                .foregroundColor(.secondary)
                .font(.headline)
                .opacity(0.4)
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .bold()
        }
    }
}

struct EmptyAnalytics: View {
    var body: some View {
        VStack {
            Spacer()
            Text("🥲")
                .font(.largeTitle)
                .padding(.bottom, 8)
            
            Text("No subscriptions found for this month.\nPlease add subscriptions or select another month.")
                .foregroundColor(.secondary)
                .font(.headline)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(.top)
        
    }
}



struct SpendingSummaryView: View {
    @ObservedObject var subscriptionManager: SubscriptionManager
    var selectedCurrency: String
    var selectedMonth: Date
    
    var body: some View {
        HStack {
            Spacer()
            VStack {
                Text("\(activeSubscriptionCount)")
                    .font(.title)
                    .bold()
                    .foregroundStyle(Color.purple)
                
                Text("Renewed subs")
                    .font(.caption)
                    .foregroundColor(Color.secondary)
            }
            Spacer()
            VStack {
                Text(formatCurrency(totalAmountSpent, currency: selectedCurrency))
                    .font(.title)
                    .bold()
                    .foregroundStyle(Color.purple)
                
                Text("Spent so far")
                    .font(.caption)
                    .foregroundColor(Color.secondary)
            }
            
            .onChange(of: selectedMonth) { newMonth in
                subscriptionManager.fetchDataForSelectedMonth(selectedMonth: newMonth)
            }
            .padding(.all, 10)
            
            Spacer()
        }
        
    }
    
    private func formatCurrency(_ amount: Double, currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
    }
    
    private var activeSubscriptionCount: Int {
        subscriptionManager.subscriptions.filter { subscription in
            subscriptionManager.isSubscriptionActive(subscription, forMonth: selectedMonth)
        }.count
    }
    
    private var totalAmountSpent: Double {
        let totalInUSD = subscriptionManager.subscriptions.reduce(0) { total, subscription in
            if subscriptionManager.isSubscriptionActive(subscription, forMonth: selectedMonth) {
                let monthlyPriceInUSD = subscription.currency == "R$" ? subscription.price / subscriptionManager.conversionRate : subscription.price
                return total + monthlyPriceInUSD
            }
            return total
        }
        // Convert the total from USD to the selected currency if needed
        return selectedCurrency == "USD" ? totalInUSD : totalInUSD * subscriptionManager.conversionRate
    }
}




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


private func sectionHeader(symbol: String, title: String) -> some View {
    VStack(spacing: 4) {
        Image(systemName: symbol)
            .foregroundColor(.secondary)
            .font(.headline)  // Adjusted font size to match title
            .opacity(0.4)
        Text(title)
            .font(.subheadline)
            .foregroundColor(.secondary)
            .bold()
    }
}



struct BarChartView: View {
    @ObservedObject var subscriptionManager: SubscriptionManager
    var month: Date
    @State private var normalizedData: [Int: Double] = [:]
    var selectedCurrency: String // Add this property
    
    private let currencyMapping: [String: String] = [
        "$": "USD",
        "R$": "BRL"
    ]
    
    var body: some View {
        Chart {
            ForEach(Array(normalizedData.keys.sorted()), id: \.self) { day in
                if let totalAmount = normalizedData[day] {
                    BarMark(
                        x: .value("Day of Month", day),
                        y: .value("Amount (\(selectedCurrency))", totalAmount) // Display currency dynamically
                    )
                    .foregroundStyle(Color.purple)
                }
            }
        }
        .chartYAxis {
            AxisMarks(preset: .extended, position: .leading)
        }
        .chartXAxis {
            AxisMarks(preset: .extended, position: .bottom) { _ in
                AxisGridLine()
                AxisTick()
                AxisValueLabel(centered: true)
            }
        }
        .onAppear {
            prepareChartData()
        }
        .onChange(of: month) { _ in
            prepareChartData()
        }
    }
    
    private func prepareChartData() {
        // Update this function to fetch the data as needed for the selected month
        subscriptionManager.fetchSubscriptions(forMonth: month)
        subscriptionManager.fetchConversionRate()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.normalizedData = self.calculateNormalizedData()
        }
    }
    
    private func calculateNormalizedData() -> [Int: Double] {
        var newNormalizedData: [Int: Double] = [:]
        let calendar = Calendar.current
        
        for subscription in subscriptionManager.subscriptions.filter({ $0.isActive }) {
            let dayOfMonth = calendar.component(.day, from: subscription.startDate)
            
            var normalizedAmount = subscription.price
            
            // Check if the subscription currency differs from the default currency
            if let mappedCurrency = currencyMapping[subscription.currency], mappedCurrency != selectedCurrency {
                // Convert subscription price to the selected currency
                if selectedCurrency == "BRL" {
                    normalizedAmount *= subscriptionManager.conversionRate
                    print("Converted \(subscription.currency) to \(selectedCurrency) for \(subscription.name): \(subscription.price) \(subscription.currency) -> \(normalizedAmount) \(selectedCurrency)")
                } else if selectedCurrency == "USD" {
                    normalizedAmount /= subscriptionManager.conversionRate
                    print("Converted \(subscription.currency) to \(selectedCurrency) for \(subscription.name): \(subscription.price) \(subscription.currency) -> \(normalizedAmount) \(selectedCurrency)")
                }
            }
            
            newNormalizedData[dayOfMonth, default: 0] += normalizedAmount
        }
        
        return newNormalizedData
    }
}

struct CurrencyChartView: View {
    @ObservedObject var subscriptionManager: SubscriptionManager
    var month: Date
    var selectedCurrency: String
    @State private var chartData: [(String, Double)] = []
    
    var body: some View {
        Chart {
            ForEach(chartData, id: \.0) { data in
                BarMark(
                    x: .value("Currency", data.0),
                    y: .value("Total", data.1)
                )
                .foregroundStyle(Color.purple)
            }
        }
        
        .chartYAxis {
            AxisMarks(preset: .extended, position: .leading)
        }
        .chartXAxis {
            AxisMarks(preset: .extended, position: .bottom) { _ in
                AxisGridLine()
                AxisTick()
                AxisValueLabel(centered: true)
            }
        }
        
        .onAppear {
            prepareChartData()
        }
        .onChange(of: month) {
            prepareChartData()
        }
        .onChange(of: selectedCurrency) { _ in
            prepareChartData()
        }
    }
    
    private func prepareChartData() {
        subscriptionManager.fetchSubscriptions(forMonth: month)
        subscriptionManager.fetchConversionRate()
        
        let (selectedCurrencyAmount, otherCurrencyAmount) = calculateChartData(subscriptions: subscriptionManager.subscriptions, forMonth: month)
        
        if selectedCurrency == "USD" {
            chartData = [("USD", selectedCurrencyAmount), ("BRL", otherCurrencyAmount)]
        } else if selectedCurrency == "BRL" {
            chartData = [("BRL", selectedCurrencyAmount), ("USD", otherCurrencyAmount)]
        }
    }
    
    private func calculateChartData(subscriptions: [Subscription], forMonth month: Date) -> (Double, Double) {
        var selectedCurrencyAmount: Double = 0.0
        var otherCurrencyAmount: Double = 0.0
        
        for subscription in subscriptions {
            if subscriptionManager.isSubscriptionActive(subscription, forMonth: month) {
                if let mappedCurrency = mapCurrency(subscription.currency) {
                    let amount = subscription.price
                    
                    if mappedCurrency == selectedCurrency {
                        selectedCurrencyAmount += amount
                    } else {
                        otherCurrencyAmount += amount
                    }
                }
            }
        }
        
        return (selectedCurrencyAmount, otherCurrencyAmount)
    }
    
    private func mapCurrency(_ currency: String) -> String? {
        let currencyMapping: [String: String] = [
            "$": "USD",
            "R$": "BRL"
        ]
        
        return currencyMapping[currency]
    }
}


struct MonthNavigationView: View {
    @Binding var selectedMonth: Date
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy" // Format for month and year
        return formatter
    }()
    
    var body: some View {
        HStack {
            Button(action: {
                self.changeMonth(by: -1)
            }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.primary) // Default color
            }
            
            Spacer()
            
            Text(dateFormatter.string(from: selectedMonth))
                .bold()
                .foregroundColor(.purple)
                .frame(minWidth: 0, maxWidth: .infinity)
            
            Spacer()
            
            Button(action: {
                self.changeMonth(by: 1)
            }) {
                Image(systemName: "chevron.right")
                    .foregroundColor(isFutureMonth() ? .secondary : .primary)
            }
            .disabled(isFutureMonth())
        }
        .padding()
    }
    
    private func changeMonth(by months: Int) {
        if let newMonth = Calendar.current.date(byAdding: .month, value: months, to: selectedMonth), !isFutureMonth(for: newMonth) {
            selectedMonth = newMonth
        }
    }
    
    private func isFutureMonth(for date: Date? = nil) -> Bool {
        let comparisonDate = date ?? selectedMonth
        let nextMonth = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .month, value: 1, to: Date())!)
        return comparisonDate >= nextMonth
    }
}


struct AnalyticsView_Previews: PreviewProvider {
    static var previews: some View {
        AnalyticsView(subscriptionManager: SubscriptionManager())
    }
}
