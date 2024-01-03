import SwiftUI

struct SettingsView: View {
    @State private var selectedCurrency = "USD"
    @State private var selectedIcon = "AppIconDefault"  // Default icon is now "AppIconDefault"
    @ObservedObject var subscriptionManager: SubscriptionManager
    @State private var showingCleanDataAlert = false  // New state variable for the alert
    
    init(subscriptionManager: SubscriptionManager) {
        self.subscriptionManager = subscriptionManager
        // Initialize selectedIcon based on the current app icon
        if let currentIcon = UIApplication.shared.alternateIconName {
            _selectedIcon = State(initialValue: currentIcon)
        } else {
            _selectedIcon = State(initialValue: "AppIcon") // Your default icon name
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    currencySection
                    appIconSection
                    supportSection
                }
                .padding()
            }
            .background(Color(UIColor.systemBackground))
            .navigationBarTitle("Settings")
            .onDisappear {
                UserDefaults.standard.set(selectedCurrency, forKey: "defaultCurrency")
                UIApplication.shared.setAlternateIconName(selectedIcon)
            }
        }
    }
    
    private var currencySection: some View {
        VStack(spacing: 16) {
            sectionHeader(symbol: "dollarsign.circle.fill", title: "Default Currency")
            
            Text("We support 🇺🇸 and 🇧🇷 currencies, but Analytics will be presented on the one you set as default")
                .font(.footnote)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Picker("Select an option", selection: $selectedCurrency) {
                Text("USD").tag("USD")
                Text("BRL").tag("BRL")
            }
            .onChange(of: selectedCurrency) { newValue in
                UserDefaults.standard.set(newValue, forKey: "defaultCurrency")
            }
            .pickerStyle(SegmentedPickerStyle())
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground).opacity(0.6))
        .cornerRadius(12)
    }
    
    private var supportSection: some View {
        VStack(spacing: 16) {
            sectionHeader(symbol: "bubble.right.fill", title: "About")
            
            Text("This app was built independently by Thalys Guimarães with the objective of learning Swift and SwfitUI")
                .font(.footnote)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            HStack(spacing:0){
                
                
                Magical3DButton(
                    label: "Support",
                    borderColor: Color(UIColor.secondarySystemBackground),
                    bodyColor: Color(UIColor.systemBackground),
                    width: 130,
                    height: 50,
                    textColor: .primary,
                    shadowColor: Color(UIColor.systemBackground),
                    action: {
                        sendSupportEmail()
                    }
                )
                
                Magical3DButton(
                    label: "Clean data",
                    borderColor: Color(red: 0.9, green: 0.1, blue: 0.1),
                    bodyColor: .red,
                    width: 130,
                    height: 50,
                    textColor: .white,
                    shadowColor: Color(red: 0.9, green: 0.1, blue: 0.1),
                    action: {
                        showingCleanDataAlert = true
                    }
                )
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground).opacity(0.6))
        .cornerRadius(12)
        .alert(isPresented: $showingCleanDataAlert) {
            Alert(
                title: Text("Clean data"),
                message: Text("This action will delete all your active subscriptions. Be careful!"),
                primaryButton: .destructive(Text("Delete All")) {
                    subscriptionManager.cleanSubscriptions()
                },
                secondaryButton: .cancel()
            )
        }
        
        //.padding()
        .background(Color(UIColor.secondarySystemBackground).opacity(0.6))
        .cornerRadius(12)
    }
    
    private var appIconSection: some View {
        VStack(spacing: 16) {
            sectionHeader(symbol: "heart.fill", title: "App Icon")
            
            appIconOption("Default", iconName: "AppIcon", previewIconName: "PreviewAppIconDefault")
            Divider()
            appIconOption("Linear", iconName: "AppIconLinear", previewIconName: "PreviewAppIconLinear")
            Divider()
            appIconOption("Steddy", iconName: "AppIconSteddy", previewIconName: "PreviewAppIconSteddy")
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground).opacity(0.6))
        .cornerRadius(12)
    }
    
    private func sectionHeader(symbol: String, title: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: symbol)
                .foregroundColor(.purple)
                .font(.headline)  // Adjusted font size to match title
                .opacity(0.4)
            Text(title)
                .font(.headline)
                .foregroundColor(.purple)
                .bold()
        }
    }
    
    private func appIconOption(_ title: String, iconName: String, previewIconName: String) -> some View {
        HStack {
            Image(previewIconName) // Use preview image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 48, height: 48)
                .cornerRadius(8)
                .padding(.trailing, 8)
            
            Text(title)
            
            Spacer()
            
            if selectedIcon == iconName {
                Image(systemName: "checkmark")
                    .foregroundColor(.purple)
            }
        }
        .onTapGesture {
            selectedIcon = iconName
            changeAppIcon(to: iconName)
        }
    }
    
    
    private func changeAppIcon(to iconName: String) {
        let isDefaultIcon = iconName == "AppIcon"
        
        UIApplication.shared.setAlternateIconName(isDefaultIcon ? nil : iconName) { error in
            if let error = error {
                print("Error changing app icon: \(error.localizedDescription)")
            } else {
                print("App icon changed successfully to \(iconName)")
            }
        }
    }
    
    
}

private func sendSupportEmail() {
        guard let url = URL(string: "mailto:mail@thalys.design") else { return }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
