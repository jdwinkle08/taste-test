import SwiftUI
import Supabase

struct AccountCreationView: View {
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isSignedUp = false

    var body: some View {
        NavigationView {
            if isSignedUp {
                ContentView()
                    .navigationBarBackButtonHidden(true)
            } else {
                ZStack {
                    Color.white.edgesIgnoringSafeArea(.all)

                    VStack(spacing: 24) {
                        Spacer().frame(height: 30)

                        // Logo and Welcome Text
                        VStack(spacing: 16) {
                            VStack(spacing: 4) {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .frame(width: 100, height: 100)
                                    .foregroundColor(.blue)

                                Text("Welcome 👋")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.black)
                            }
                            .padding(.bottom, 20)

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
                        }

                        Spacer()

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
                        .padding(.bottom, 80)
                        .disabled(isLoading || email.isEmpty || password.isEmpty || firstName.isEmpty || lastName.isEmpty)
                    }
                }
                .onAppear {
                    checkSession()
                }
            }
        }
    }

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

                // Sign up the user
                _ = try await client.auth.signUp(
                    email: email,
                    password: password,
                    data: [
                        "first_name": AnyJSON(firstName),
                        "last_name": AnyJSON(lastName)
                    ]
                )

                // Explicitly sign in to get a valid session
                let signInResponse = try await client.auth.signIn(
                    email: email,
                    password: password
                )

                let userId = signInResponse.user.id.uuidString

                // Insert user data into the "users" table
                _ = try await client.from("users").insert([
                    "id": AnyJSON(userId),
                    "first_name": AnyJSON(firstName),
                    "last_name": AnyJSON(lastName),
                    "email": AnyJSON(email)
                ]).execute()

                isSignedUp = true
                isLoading = false
            } catch {
                isLoading = false
                errorMessage = "\(error.localizedDescription)"
                print("Signup Error: \(error)")
            }
        }
    }

    func checkSession() {
        Task {
            let sessionRestored = await SupabaseManager.shared.restoreSession()
            if sessionRestored {
                DispatchQueue.main.async {
                    isSignedUp = true
                }
            }
        }
    }
}

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

struct AccountCreationView_Previews: PreviewProvider {
    static var previews: some View {
        AccountCreationView()
    }
}

final class SupabaseManager {
    static let shared = SupabaseManager()

    let client: SupabaseClient

    private init() {
        guard
            let supabaseURLString = Bundle.main.infoDictionary?["SUPABASE_URL"] as? String,
            let supabaseKey = Bundle.main.infoDictionary?["SUPABASE_ANON_KEY"] as? String,
            let supabaseURL = URL(string: supabaseURLString)
        else {
            fatalError("Missing or invalid Supabase configuration in Secrets.xcconfig")
        }

        client = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: supabaseKey
        )
    }

    func restoreSession() async -> Bool {
        do {
            let session = try await client.auth.session
            print("Restored session: \(session)")
            return true
        } catch {
            print("Failed to restore session: \(error)")
            return false
        }
    }
}
