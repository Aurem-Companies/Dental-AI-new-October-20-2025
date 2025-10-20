import SwiftUI

// MARK: - Authentication View
struct AuthenticationView: View {
    @StateObject private var authViewModel = AuthenticationViewModel()
    @State private var isSignUp = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.white]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Header
                        headerSection
                        
                        // Form
                        if isSignUp {
                            SignUpForm(authViewModel: authViewModel)
                        } else {
                            SignInForm(authViewModel: authViewModel)
                        }
                        
                        // Toggle
                        toggleSection
                    }
                    .padding()
                }
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            // App Icon
            Text("🦷")
                .font(.system(size: 80))
            
            // Title
            Text("DentalAI")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            // Subtitle
            Text(isSignUp ? "Create your account" : "Welcome back")
                .font(.title2)
                .foregroundColor(.secondary)
        }
        .padding(.top, 40)
    }
    
    // MARK: - Toggle Section
    private var toggleSection: some View {
        HStack {
            Text(isSignUp ? "Already have an account?" : "Don't have an account?")
                .foregroundColor(.secondary)
            
            Button(isSignUp ? "Sign In" : "Sign Up") {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isSignUp.toggle()
                }
            }
            .foregroundColor(.blue)
            .fontWeight(.semibold)
        }
        .font(.body)
    }
}

// MARK: - Sign In Form
struct SignInForm: View {
    @ObservedObject var authViewModel: AuthenticationViewModel
    @State private var email = ""
    @State private var password = ""
    
    var body: some View {
        VStack(spacing: 20) {
            // Email Field
            CustomTextField(
                title: "Email",
                text: $email,
                placeholder: "Enter your email",
                icon: "envelope.fill"
            )
            
            // Password Field
            CustomTextField(
                title: "Password",
                text: $password,
                placeholder: "Enter your password",
                icon: "lock.fill",
                isSecure: true
            )
            
            // Error Message
            if let errorMessage = authViewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
            
            // Sign In Button
            Button(action: {
                authViewModel.signIn(email: email, password: password)
            }) {
                HStack {
                    if authViewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Text("Sign In")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(authViewModel.isLoading || email.isEmpty || password.isEmpty)
            
            // Forgot Password
            Button("Forgot Password?") {
                // Handle forgot password
            }
            .font(.caption)
            .foregroundColor(.blue)
        }
        .padding(.horizontal)
    }
}

// MARK: - Sign Up Form
struct SignUpForm: View {
    @ObservedObject var authViewModel: AuthenticationViewModel
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    
    var body: some View {
        VStack(spacing: 20) {
            // Name Field
            CustomTextField(
                title: "Full Name",
                text: $name,
                placeholder: "Enter your full name",
                icon: "person.fill"
            )
            
            // Email Field
            CustomTextField(
                title: "Email",
                text: $email,
                placeholder: "Enter your email",
                icon: "envelope.fill"
            )
            
            // Password Field
            CustomTextField(
                title: "Password",
                text: $password,
                placeholder: "Create a password",
                icon: "lock.fill",
                isSecure: true
            )
            
            // Confirm Password Field
            CustomTextField(
                title: "Confirm Password",
                text: $confirmPassword,
                placeholder: "Confirm your password",
                icon: "lock.fill",
                isSecure: true
            )
            
            // Error Message
            if let errorMessage = authViewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
            
            // Sign Up Button
            Button(action: {
                authViewModel.signUp(
                    name: name,
                    email: email,
                    password: password,
                    confirmPassword: confirmPassword
                )
            }) {
                HStack {
                    if authViewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Text("Sign Up")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(authViewModel.isLoading || name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty)
        }
        .padding(.horizontal)
    }
}

// MARK: - Custom Text Field
struct CustomTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let icon: String
    var isSecure: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.secondary)
                    .frame(width: 20)
                
                if isSecure {
                    SecureField(placeholder, text: $text)
                        .textFieldStyle(PlainTextFieldStyle())
                } else {
                    TextField(placeholder, text: $text)
                        .textFieldStyle(PlainTextFieldStyle())
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

// MARK: - Preview
struct AuthenticationView_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticationView()
    }
}
