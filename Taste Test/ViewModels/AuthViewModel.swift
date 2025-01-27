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

    struct User: Decodable {
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
            let session = try await supabaseManager.client.auth.signIn(
                email: email,
                password: password
            )

            supabaseManager.storeSessionInUserDefaults(session)

            let userIdString = session.user.id.uuidString

            let data = try await supabaseManager.client
                .from("users")
                .select("first_name, last_name, email")
                .eq("id", value: userIdString)
                .single()
                .execute()
            
            if let jsonData = try? JSONSerialization.data(withJSONObject: data),
               let user = try? JSONDecoder().decode(User.self, from: jsonData) {
                self.firstName = user.first_name
                self.lastName = user.last_name
                self.email = user.email
                self.isSignedIn = true
                return true
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
            try await supabaseManager.client.auth.setSession(
                accessToken: session.accessToken,
                refreshToken: session.refreshToken
            )
            isSignedIn = true

            let userIdString = session.user.id.uuidString

            let data = try await supabaseManager.client
                .from("users")
                .select("first_name, last_name, email")
                .eq("id", value: userIdString)
                .single()
                .execute()
            
            if let jsonData = try? JSONSerialization.data(withJSONObject: data),
               let user = try? JSONDecoder().decode(User.self, from: jsonData) {
                self.firstName = user.first_name
                self.lastName = user.last_name
                self.email = user.email
            }

        } catch {
            print("Failed to restore session: \(error)")
            isSignedIn = false
        }
    }
}
