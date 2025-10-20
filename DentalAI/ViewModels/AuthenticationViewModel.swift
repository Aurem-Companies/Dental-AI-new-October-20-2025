import Foundation
import SwiftUI
import Combine

// MARK: - Authentication View Model
class AuthenticationViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentUser: User?
    
    private let dataManager = DataManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        checkAuthenticationStatus()
    }
    
    // MARK: - Authentication Methods
    func signIn(email: String, password: String) {
        isLoading = true
        errorMessage = nil
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // For demo purposes, accept any email/password
            if !email.isEmpty && !password.isEmpty {
                self.currentUser = User(
                    id: UUID(),
                    email: email,
                    name: email.components(separatedBy: "@").first?.capitalized ?? "User",
                    createdAt: Date()
                )
                self.isAuthenticated = true
                self.saveUserSession()
                print("✅ Authentication successful for user: \(self.currentUser?.email ?? "unknown")")
            } else {
                self.errorMessage = "Please enter valid email and password"
            }
            self.isLoading = false
        }
    }
    
    func signUp(name: String, email: String, password: String, confirmPassword: String) {
        isLoading = true
        errorMessage = nil
        
        // Validate input
        guard !name.isEmpty else {
            errorMessage = "Please enter your name"
            isLoading = false
            return
        }
        
        guard isValidEmail(email) else {
            errorMessage = "Please enter a valid email address"
            isLoading = false
            return
        }
        
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            isLoading = false
            return
        }
        
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match"
            isLoading = false
            return
        }
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.currentUser = User(
                id: UUID(),
                email: email,
                name: name,
                createdAt: Date()
            )
            self.isAuthenticated = true
            self.saveUserSession()
            print("✅ Sign up successful for user: \(self.currentUser?.email ?? "unknown")")
            self.isLoading = false
        }
    }
    
    func signOut() {
        currentUser = nil
        isAuthenticated = false
        clearUserSession()
    }
    
    // MARK: - Private Methods
    private func checkAuthenticationStatus() {
        if let userData = UserDefaults.standard.data(forKey: "currentUser"),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            currentUser = user
            isAuthenticated = true
        }
    }
    
    private func saveUserSession() {
        if let user = currentUser,
           let userData = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(userData, forKey: "currentUser")
        }
    }
    
    private func clearUserSession() {
        UserDefaults.standard.removeObject(forKey: "currentUser")
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}

// MARK: - User Model
struct User: Codable, Identifiable {
    let id: UUID
    let email: String
    let name: String
    let createdAt: Date
    
    init(id: UUID = UUID(), email: String, name: String, createdAt: Date = Date()) {
        self.id = id
        self.email = email
        self.name = name
        self.createdAt = createdAt
    }
}
