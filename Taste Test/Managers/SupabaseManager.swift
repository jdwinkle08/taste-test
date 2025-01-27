import SwiftUI
import Supabase

final class SupabaseManager {
    static let shared = SupabaseManager()

    let client: SupabaseClient

    private init() {
        // 1) Make sure you have valid Supabase URL & Key in Info.plist or .xcconfig
        guard
            let supabaseURLString = Bundle.main.infoDictionary?["SUPABASE_URL"] as? String,
            let supabaseKey = Bundle.main.infoDictionary?["SUPABASE_ANON_KEY"] as? String,
            let supabaseURL = URL(string: supabaseURLString)
        else {
            fatalError("Missing or invalid Supabase configuration.")
        }

        // 2) Create the client
        client = SupabaseClient(supabaseURL: supabaseURL, supabaseKey: supabaseKey)
    }

    // MARK: - Manually Save or Clear Session

    /// Call this method **right after** the user signs in or the token refreshes.
    func storeSessionInUserDefaults(_ session: Session) {
        do {
            let data = try JSONEncoder().encode(session)
            let jsonString = String(data: data, encoding: .utf8)
            UserDefaults.standard.set(jsonString, forKey: "supabaseSession")
        } catch {
            print("Failed to encode session: \(error)")
        }
    }

    /// Call this when the user signs out.
    func clearSessionFromUserDefaults() {
        UserDefaults.standard.removeObject(forKey: "supabaseSession")
    }

    // MARK: - Restore Session (Async)

    /// Restores a previously saved session from UserDefaults and sets it on the Supabase client.
    func restoreSession() async -> Bool {
        guard
            let jsonString = UserDefaults.standard.string(forKey: "supabaseSession"),
            let data = jsonString.data(using: .utf8)
        else {
            // No session saved
            return false
        }

        do {
            // Decode the stored Session
            let session = try JSONDecoder().decode(Session.self, from: data)

            // For newer Supabase Swift, set session with token & refreshToken:
            try await client.auth.setSession(
                accessToken: session.accessToken,
                refreshToken: session.refreshToken
            )

            return true
        } catch {
            print("Failed to restore session: \(error)")
            return false
        }
    }
}
