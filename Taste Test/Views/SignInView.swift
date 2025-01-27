import SwiftUI
import Supabase

struct SignInView: View {
    @EnvironmentObject var authViewModel: AuthViewModel // Use AuthViewModel
    @Binding var showSignUp: Bool
    var onSignedIn: (() -> Void)? = nil // Callback when signed in

    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            Text("Sign In View: isSignedIn = \(authViewModel.isSignedIn.description)")
            Color.white.edgesIgnoringSafeArea(.all)

            VStack(spacing: 24) {
                Spacer().frame(height: 30)

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
                .padding(.bottom, 20)

                // Input Fields
                VStack(spacing: 10) {
                    CustomTextField(placeholder: "Email", text: $email)
                    CustomSecureField(placeholder: "Password", text: $password)
                }
                .padding(.horizontal, 24)

                Spacer()

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
                            .frame(maxWidth: .infinity)
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
                .disabled(isLoading || email.isEmpty || password.isEmpty)

                // Create Account Button
                Button(action: {
                    showSignUp = true // Navigate to AccountCreationView
                }) {
                    Text("Don't have an account? Create one")
                        .font(.body)
                        .foregroundColor(.blue)
                }
                .padding(.bottom, 12)
            }
        }
    }

    func signIn() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields."
            return
        }

        isLoading = true
        errorMessage = nil

        Task {
            let success = await authViewModel.signIn(email: email, password: password)
            DispatchQueue.main.async {
                isLoading = false
                if success {
                    // Sign-in succeeded, isSignedIn will update automatically
                    print("authViewModel: \(success)")
                    print("User signed in successfully.")
                } else {
                    errorMessage = "Sign in failed. Please check your credentials."
                }
            }
        }
    }
}

struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        StatefulPreviewWrapper(false) { showSignUp in
            SignInView(showSignUp: showSignUp)
        }
    }
}
