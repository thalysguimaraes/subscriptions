//
//  SubscriptionView.swift
//  Subscriptions
//
//  Created by Thalys Guimarães on 30/12/23.
//

import SwiftUI
import UserNotifications

struct SubscriptionView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var subscriptionManager: SubscriptionManager
    @State private var subscription: Subscription
    @State private var serviceLogo: UIImage?
    @State private var showingImagePicker = false
    @State private var remindOptions = ["7 days", "3 days", "1 day"]
    @State private var selectedReminderOption = "7 days"
    var isEditMode: Bool

    let availableServices = ["copilot", "netflix", "spotify"] // Add all your service names here

    init(subscriptionManager: SubscriptionManager, subscription: Subscription, isEditMode: Bool = false) {
        self.subscriptionManager = subscriptionManager
        self._subscription = State(initialValue: subscription)
        self.isEditMode = isEditMode
        if let data = subscription.serviceLogo, let image = UIImage(data: data) {
            self._serviceLogo = State(initialValue: image)
        }
    }
    
    
    private func saveSubscription() {
        if let serviceLogoImage = serviceLogo {
                    subscription.serviceLogo = serviceLogoImage.pngData()
                }

                // Calculate and set the reminder date
                if subscription.remindMe {
                    subscription.reminderDate = calculateReminderDate()
                    scheduleNotification() // Schedule the notification
                } else {
                    subscription.reminderDate = nil
                }

            if isEditMode {
                subscriptionManager.updateSubscription(subscription)
            } else {
                subscriptionManager.addSubscription(subscription)
                subscriptionManager.fetchSubscriptions() // Refetch the subscriptions
            }
            presentationMode.wrappedValue.dismiss()
        }
    
    private func scheduleNotification() {
            guard let reminderDate = subscription.reminderDate else { return }

            let content = UNMutableNotificationContent()
            content.title = "Subscription Renewal Reminder"
            content.body = "\(subscription.name) subscription is due for renewal."
            content.sound = UNNotificationSound.default

            let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)

            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error scheduling notification: \(error.localizedDescription)")
                } else {
                    print("Notification scheduled for \(subscription.name) on \(reminderDate)")
                }
            }
        }

    private func calculateReminderDate() -> Date? {
        let calendar = Calendar.current
        let daysBefore: Int

        switch selectedReminderOption {
        case "7 days":
            daysBefore = 7
        case "3 days":
            daysBefore = 3
        case "1 day":
            daysBefore = 1
        default:
            return nil
        }

        // Calculate the next renewal date
        let nextRenewalDate: Date?
        switch subscription.cycle {
        case "Monthly":
            nextRenewalDate = calendar.date(byAdding: .month, value: 1, to: subscription.startDate)
        case "Yearly":
            nextRenewalDate = calendar.date(byAdding: .year, value: 1, to: subscription.startDate)
        default:
            nextRenewalDate = nil
        }

        // Calculate the reminder date by subtracting 'daysBefore' from the next renewal date
        if let nextRenewalDate = nextRenewalDate {
            let reminderDate = calendar.date(byAdding: .day, value: -daysBefore, to: nextRenewalDate)
            return reminderDate
        } else {
            return nil
        }
    }

    
    
    var body: some View {
        NavigationView {
            VStack {
                Form {
                    Section {
                        HStack {
                            Text("Service name")
                            Spacer()
                            TextField("Enter name", text: $subscription.name)
                                .multilineTextAlignment(.trailing)
                                .onChange(of: subscription.name) { [subscription] newName in
                                    print("Name changed to: \(newName)")
                                    updateServiceLogo(with: newName)
                                }
                        }
                        .padding(.vertical, 8)

                        Button(action: {
                            self.showingImagePicker = true
                        }) {
                            ZStack {
                                Circle()
                                    .foregroundColor(.purple.opacity(0.1))
                                    .frame(width: 80, height: 80)
                                if let serviceLogo = serviceLogo {
                                    Image(uiImage: serviceLogo)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 60, height: 60)
                                        .clipShape(Circle())
                                } else {
                                    Image(systemName: "camera.fill")
                                        .frame(width: 60, height: 60)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical)
                    }


                    Section(header: Text("Subscription details")) {
                        Picker("Currency", selection: $subscription.currency) {
                            Text("R$").tag("R$")
                            Text("$").tag("$")
                        }
                        
                        HStack {
                            Text("Price")
                            Spacer()
                            TextField("0.00", value: $subscription.price, formatter: NumberFormatter())
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }

                        Picker("Cycle", selection: $subscription.cycle) {
                            Text("Monthly").tag("Monthly")
                            Text("Yearly").tag("Yearly")
                        }

                        DatePicker("Start Date", selection: $subscription.startDate, displayedComponents: .date)
                    }

                    Section(header: Text("Reminders")) {
                        Toggle("Renewal reminder", isOn: $subscription.remindMe)
                            .padding(.vertical, 4)

                        if subscription.remindMe {
                            Picker("Remind me:", selection: $selectedReminderOption) {
                                ForEach(remindOptions, id: \.self) {
                                    Text($0)
                                }
                            }
                            .padding(.vertical, 8)
                            .pickerStyle(SegmentedPickerStyle())
                        }
                    }
                }

                if isEditMode {
                    Button("Delete Subscription") {
                        subscriptionManager.deleteSubscription(subscription)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                }
            }
            .navigationBarTitle(isEditMode ? "Edit Subscription" : "New Subscription", displayMode: .inline)
            .navigationBarItems(trailing: Button(isEditMode ? "Update" : "Save") {
                saveSubscription()
                print("Saving/Updating subscription: \(subscription)")
                if let serviceLogoImage = serviceLogo {
                    subscription.serviceLogo = serviceLogoImage.pngData()
                }
                if isEditMode {
                    subscriptionManager.updateSubscription(subscription)
                } else {
                    subscriptionManager.addSubscription(subscription)
                    subscriptionManager.fetchSubscriptions() // Refetch the subscriptions
                }
                presentationMode.wrappedValue.dismiss()
            })
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: self.$serviceLogo)
            }
        }
    }

    private func updateServiceLogo(with name: String) {
        let matchedService = findBestMatch(for: name)
        if let imageName = matchedService {
            serviceLogo = UIImage(named: imageName)
        }
    }

    private func findBestMatch(for name: String) -> String? {
        let lowercasedName = name.lowercased()
        for service in availableServices {
            if lowercasedName.similarity(to: service) > 0.9 {
                return service
            }
        }
        return nil
    }
}

extension String {
    func similarity(to other: String) -> Double {
        let commonPrefixLength = commonPrefix(with: other).count
        let maxLength = max(self.count, other.count)
        return Double(commonPrefixLength) / Double(maxLength)
    }
}

