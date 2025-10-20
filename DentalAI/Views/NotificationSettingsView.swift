import SwiftUI

// MARK: - Notification Settings View
struct NotificationSettingsView: View {
    @State private var analysisReminders = true
    @State private var weeklyReports = true
    @State private var dentalTips = false
    @State private var appointmentReminders = true
    @State private var showingAlert = false
    
    var body: some View {
        Form {
            Section("Analysis & Reports") {
                Toggle("Analysis Reminders", isOn: $analysisReminders)
                Toggle("Weekly Health Reports", isOn: $weeklyReports)
                Toggle("Dental Health Tips", isOn: $dentalTips)
            }
            
            Section("Appointments") {
                Toggle("Appointment Reminders", isOn: $appointmentReminders)
            }
            
            Section("Notification Timing") {
                HStack {
                    Text("Daily Reminder Time")
                    Spacer()
                    Text("9:00 AM")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Weekly Report Day")
                    Spacer()
                    Text("Monday")
                        .foregroundColor(.secondary)
                }
            }
            
            Section {
                Button("Save Settings") {
                    saveSettings()
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Settings Saved", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text("Your notification preferences have been updated.")
        }
    }
    
    private func saveSettings() {
        // Save notification settings
        showingAlert = true
    }
}
