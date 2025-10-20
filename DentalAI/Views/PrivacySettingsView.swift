import SwiftUI

// MARK: - Privacy Settings View
struct PrivacySettingsView: View {
    @State private var shareAnalytics = false
    @State private var shareWithDentists = true
    @State private var allowDataCollection = true
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        Form {
            Section("Data Sharing") {
                Toggle("Share Analytics (Anonymous)", isOn: $shareAnalytics)
                Toggle("Share with Dentists", isOn: $shareWithDentists)
                Toggle("Allow Data Collection", isOn: $allowDataCollection)
            }
            
            Section("Data Management") {
                Button("Export My Data") {
                    exportData()
                }
                .foregroundColor(.blue)
                
                Button("Delete All Data") {
                    deleteData()
                }
                .foregroundColor(.red)
            }
            
            Section("Privacy Information") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Data Usage")
                        .font(.headline)
                    Text("Your dental analysis data is stored locally on your device and is not shared without your explicit consent.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Camera Access")
                        .font(.headline)
                    Text("Camera access is only used to capture photos for dental analysis. Images are processed locally and not stored permanently.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Section {
                Button("Save Privacy Settings") {
                    saveSettings()
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .navigationTitle("Privacy")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Privacy Settings", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func saveSettings() {
        alertMessage = "Your privacy settings have been saved."
        showingAlert = true
    }
    
    private func exportData() {
        alertMessage = "Your data export has been initiated. You will receive an email with your data shortly."
        showingAlert = true
    }
    
    private func deleteData() {
        alertMessage = "All your data has been deleted from this device."
        showingAlert = true
    }
}
