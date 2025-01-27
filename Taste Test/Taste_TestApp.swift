//
//  Taste_TestApp.swift
//  Taste Test
//
//  Created by Jeff Winkle on 1/23/25.
//

import SwiftUI

@main
struct TasteTestApp: App {
    /// Holds our sign-in state so we can show the correct screens.
    @StateObject private var authViewModel = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(authViewModel)
                .task {
                    // Attempt to restore a Supabase session on launch
                    let sessionRestored = await SupabaseManager.shared.restoreSession()
                    if sessionRestored {
                        authViewModel.isSignedIn = true
                    }
                }
        }
    }
}
