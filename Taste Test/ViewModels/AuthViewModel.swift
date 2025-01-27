//
//  AuthViewModel.swift
//  Taste Test
//
//  Created by Jeff Winkle on 1/26/25.
//

import SwiftUI
import Supabase

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var isSignedIn: Bool = false {
        didSet {
            print("AuthViewModel: isSignedIn updated to \(isSignedIn)")
        }
    }
    private let supabaseManager = SupabaseManager.shared

    init() {
        // Attempt to restore the session on initialization
        Task {
            await restoreSession()
        }
    }

    func signOut() {
        Task {
            do {
                try await supabaseManager.client.auth.signOut()
                isSignedIn = false
                clearSession()
            } catch {
                print("Error during sign out: \(error)")
            }
        }
    }


    func signIn(email: String, password: String) async -> Bool {
        do {
            let session = try await SupabaseManager.shared.client.auth.signIn(
                email: email,
                password: password
            )
            SupabaseManager.shared.storeSessionInUserDefaults(session)
            await MainActor.run {
                isSignedIn = true
            }
            return true
        } catch {
            print("AuthViewModel: Sign-in failed - \(error)")
            return false
        }
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
        } catch {
            print("Failed to restore session: \(error)")
            isSignedIn = false
        }
    }
}
