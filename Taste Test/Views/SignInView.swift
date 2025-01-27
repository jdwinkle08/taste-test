import SwiftUI
import Supabase

struct SignInView: View {
    /// Controls whether we switch to the sign-up screen
    @Binding var showSignUp: Bool
    
    /// A callback to inform the parent (e.g. MainView) that sign-in succeeded
    var onSignedIn: (() -> Void)? = nil
    
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
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
                    showSignUp = true
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
            do {
                let client = SupabaseManager.shared.client

                // Attempt to sign in — returns a Session directly
                let session = try await client.auth.signIn(email: email, password: password)

                // Store the Session
                SupabaseManager.shared.storeSessionInUserDefaults(session)

                // Access the user if you want
                let user = session.user
                print("User signed in successfully. ID: \(user.id)")

                DispatchQueue.main.async {
                    isLoading = false
                    onSignedIn?() // Let parent know sign-in succeeded
                }
            } catch {
                DispatchQueue.main.async {
                    errorMessage = "Sign in failed: \(error.localizedDescription)"
                    isLoading = false
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
