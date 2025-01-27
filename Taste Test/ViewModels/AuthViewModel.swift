import SwiftUI
import Supabase

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var isSignedIn: Bool = false {
        didSet {
            print("AuthViewModel: isSignedIn updated to \(isSignedIn)")
        }
    }
    @Published var firstName: String = ""
    @Published var lastName: String = ""
    @Published var email: String = ""

    private let supabaseManager = SupabaseManager.shared

    struct User: Codable {
        let first_name: String
        let last_name: String
        let email: String
    }

    init() {
        Task {
            await restoreSession()
        }
    }

    // MARK: - Sign Out
    func signOut() {
        Task {
            do {
                try await supabaseManager.client.auth.signOut()
                isSignedIn = false
                clearUserData()
                clearSession()
            } catch {
                print("Error during sign out: \(error)")
            }
        }
    }

    // MARK: - Sign In
    func signIn(email: String, password: String) async -> Bool {
        do {
            // Attempt to sign in the user
            let session = try await supabaseManager.client.auth.signIn(
                email: email,
                password: password
            )

            // Store the session locally
            supabaseManager.storeSessionInUserDefaults(session)

            let userIdString = session.user.id.uuidString

            // Fetch user details from the "users" table
            let response = try await supabaseManager.client
                .from("users")
                .select("first_name, last_name, email")
                .eq("id", value: userIdString) // Ensure 'value:' label is used correctly
                .single()
                .execute() // Removed 'as: .object(User.self)'

            // **Logging: Check the type of response.data**
            print("Type of response.data: \(type(of: response.data))")

            // **Logging: Convert response.data to JSON string**
            if let jsonString = String(data: response.data, encoding: .utf8) {
                print("User data JSON: \(jsonString)")
            } else {
                print("Failed to convert user data to JSON string.")
            }

            // **Attempt to Decode the User Model**
            let user = try JSONDecoder().decode(User.self, from: response.data)

            // Assign user details
            self.firstName = user.first_name
            self.lastName = user.last_name
            self.email = user.email
            self.isSignedIn = true
            return true

        } catch let decodingError as DecodingError {
            switch decodingError {
            case .typeMismatch(let type, let context):
                print("Type '\(type)' mismatch:", context.debugDescription)
            case .valueNotFound(let type, let context):
                print("Value '\(type)' not found:", context.debugDescription)
            case .keyNotFound(let key, let context):
                print("Key '\(key)' not found:", context.debugDescription)
            case .dataCorrupted(let context):
                print("Data corrupted:", context.debugDescription)
            @unknown default:
                print("Unknown decoding error:", decodingError.localizedDescription)
            }
            return false
        } catch {
            print("AuthViewModel: Sign-in failed - \(error)")
            return false
        }
    }
    
    // MARK: - Helpers
    private func clearUserData() {
        firstName = ""
        lastName = ""
        email = ""
    }

    private func saveSession(_ session: Session) {
        do {
            let data = try JSONEncoder().encode(session)
            UserDefaults.standard.set(data, forKey: "supabaseSession")
        } catch {
            print("Failed to save session: \(error)")
        }
    }

    private func clearSession() {
        UserDefaults.standard.removeObject(forKey: "supabaseSession")
    }

    // MARK: - Restore Session
    private func restoreSession() async {
        guard
            let sessionData = UserDefaults.standard.data(forKey: "supabaseSession"),
            let session = try? JSONDecoder().decode(Session.self, from: sessionData)
        else {
            isSignedIn = false
            return
        }

        do {
            // Restore the session with Supabase
            try await supabaseManager.client.auth.setSession(
                accessToken: session.accessToken,
                refreshToken: session.refreshToken
            )
            isSignedIn = true

            let userIdString = session.user.id.uuidString

            // Fetch user details from the "users" table
            let response: PostgrestResponse<Data> = try await supabaseManager.client
                .from("users")
                .select("first_name, last_name, email")
                .eq("id", value: userIdString) // Corrected 'eq' method usage
                .single()
                .execute() // Removed 'as: .object(User.self)'

            // Decode the Data into User model
            let user = try JSONDecoder().decode(User.self, from: response.data)

            // Assign user details
            self.firstName = user.first_name
            self.lastName = user.last_name
            self.email = user.email

        } catch {
            print("Failed to restore session: \(error)")
            isSignedIn = false
        }
    }
}
