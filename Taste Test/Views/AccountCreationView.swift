import SwiftUI
import Supabase

struct AccountCreationView: View {
    /// Controls whether we switch to the sign-in screen
    @Binding var showSignIn: Bool
    
    /// Controls whether we're currently showing the sign-up screen
    @Binding var showSignUp: Bool
    
    /// A callback to inform the parent (e.g. MainView) that sign-up succeeded
    var onSignedUp: (() -> Void)? = nil
    
    @State private var firstName = ""
    @State private var lastName = ""
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

                Text("Welcome 👋")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
            }
            .padding(.top, 40)
            
            // Input Fields
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    CustomTextField(placeholder: "First Name", text: $firstName)
                    CustomTextField(placeholder: "Last Name", text: $lastName)
                }
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
            
            // Sign Up Button
            Button(action: createAccount) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Sign Up")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
            }
            .padding(.horizontal, 24)
            .disabled(isLoading)
//            .disabled(isLoading || email.isEmpty || password.isEmpty || firstName.isEmpty || lastName.isEmpty)
            
            // Navigation to Sign In
            Button(action: {
                showSignIn = true
                showSignUp = false
            }) {
                Text("Already have an account? Sign In")
                    .font(.body)
                    .foregroundColor(.blue)
            }
            .padding(.bottom, 12)
        }
        .padding()
        .background(Color.white.edgesIgnoringSafeArea(.all))
    }

    // MARK: - Create Account
    
    func createAccount() {
        guard !email.isEmpty, !password.isEmpty, !firstName.isEmpty, !lastName.isEmpty else {
            errorMessage = "All fields are required."
            return
        }
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let client = SupabaseManager.shared.client

                // 1) Sign up the user
                _ = try await client.auth.signUp(
                    email: email,
                    password: password,
                    data: [
                        "first_name": AnyJSON(firstName),
                        "last_name": AnyJSON(lastName)
                    ]
                )

                // 2) Sign in for a valid session
                let session = try await client.auth.signIn(email: email, password: password)

                // 2a) Store that session
                SupabaseManager.shared.storeSessionInUserDefaults(session)

                // Because session.user is NOT optional:
                let user = session.user
                let userId = user.id.uuidString

                // 3) Insert user data
                _ = try await client
                    .from("users")
                    .insert([
                        "id": AnyJSON(userId),
                        "first_name": AnyJSON(firstName),
                        "last_name": AnyJSON(lastName),
                        "email": AnyJSON(email)
                    ])
                    .execute()

                DispatchQueue.main.async {
                    isLoading = false
                    onSignedUp?()
                }
            } catch {
                DispatchQueue.main.async {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Optional: Checking Session
    
    /// Example usage if you want to manually restore a session:
    func checkSession() {
        // Because restoreSession() is async, we wrap it in Task:
        Task {
            let sessionRestored = await SupabaseManager.shared.restoreSession()
            if sessionRestored {
                // e.g., let the parent know we’re signed in
                DispatchQueue.main.async {
                    onSignedUp?()
                }
            }
        }
    }
}

// MARK: - Custom Text Fields

struct CustomTextField: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        TextField("", text: $text)
            .placeholder(when: text.isEmpty) {
                Text(placeholder)
                    .foregroundColor(Color(.systemGray3))
                    .fontWeight(.medium)
            }
            .padding(.vertical, 15)
            .padding(.horizontal, 12)
            .background(Color(.systemGray6))
            .cornerRadius(11)
            .font(.body)
    }
}

struct CustomSecureField: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        SecureField("", text: $text)
            .placeholder(when: text.isEmpty) {
                Text(placeholder)
                    .foregroundColor(Color(.systemGray3))
                    .fontWeight(.medium)
            }
            .padding(.vertical, 15)
            .padding(.horizontal, 12)
            .background(Color(.systemGray6))
            .cornerRadius(11)
            .font(.body)
    }
}

// MARK: - Placeholder Extension

extension View {
    /// A helper modifier to show a placeholder in `SecureField` and `TextField`.
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

// MARK: - Preview

struct AccountCreationView_Previews: PreviewProvider {
    static var previews: some View {
        StatefulPreviewWrapper(false) { showSignIn in
            StatefulPreviewWrapper(true) { showSignUp in
                AccountCreationView(
                    showSignIn: showSignIn,
                    showSignUp: showSignUp
                )
            }
        }
    }
}

