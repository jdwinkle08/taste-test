import SwiftUI
import Supabase

struct SignInView: View {
    @Binding var showSignIn: Bool
    @Binding var showSignUp: Bool
    var onSignedIn: (() -> Void)? = nil
    
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 24) {
            // Logo and Welcome Text
            VStack(spacing: 16) {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.blue)
    
                Text("Welcome Back 👋")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
            }
            .padding(.top, 40)
            
            // Input Fields
            VStack(spacing: 10) {
                CustomTextField(placeholder: "Email", text: $email)
                CustomSecureField(placeholder: "Password", text: $password)
            }
            .padding(.horizontal, 24)
            
            // Error Message
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            
            // Sign In Button
            Button(action: signIn) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else {
                    Text("Sign In")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
            }
            .padding(.horizontal, 24)
            .disabled(isLoading) // Only disable when loading
            
            // Navigation to Sign Up
            Button(action: {
                showSignIn = false
                showSignUp = true
            }) {
                Text("Don't have an account? Sign Up")
                    .font(.body)
                    .foregroundColor(.blue)
            }
            .padding(.bottom, 12)
        }
        .padding()
        .background(Color.white.edgesIgnoringSafeArea(.all))
    }

    // MARK: - Sign In
    
    func signIn() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "All fields are required."
            return
        }
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let client = SupabaseManager.shared.client

                // Sign in the user
                let session = try await client.auth.signIn(email: email, password: password)

                // Store the session
                SupabaseManager.shared.storeSessionInUserDefaults(session)

                DispatchQueue.main.async {
                    isLoading = false
                    print("SignInView: Calling onSignedIn")
                    onSignedIn?() // Trigger the callback
                }
            } catch {
                DispatchQueue.main.async {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        SignInView(
            showSignIn: .constant(true),    // Provide a constant binding for showSignIn
            showSignUp: .constant(false),   // Provide a constant binding for showSignUp
            onSignedIn: {                   // Provide a mock closure for onSignedIn
                print("Preview: onSignedIn called.")
            }
        )
    }
}
