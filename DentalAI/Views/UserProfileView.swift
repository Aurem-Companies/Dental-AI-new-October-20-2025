import SwiftUI

// MARK: - User Profile View
struct UserProfileView: View {
    @State private var name = ""
    @State private var email = ""
    @State private var age = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        Form {
            Section("Personal Information") {
                TextField("Name", text: $name)
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                TextField("Age", text: $age)
                    .keyboardType(.numberPad)
            }
            
            Section("Dental History") {
                Text("Analysis History")
                    .foregroundColor(.secondary)
                Text("Export Data")
                    .foregroundColor(.blue)
                Text("Import Data")
                    .foregroundColor(.blue)
            }
            
            Section {
                Button("Save Changes") {
                    saveProfile()
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .navigationTitle("User Profile")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadProfile()
        }
        .alert("Profile Updated", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func loadProfile() {
        // Load user profile data
        name = "John Doe"
        email = "john@example.com"
        age = "30"
    }
    
    private func saveProfile() {
        // Save profile changes
        alertMessage = "Your profile has been updated successfully!"
        showingAlert = true
    }
}
