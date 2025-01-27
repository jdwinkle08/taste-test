//
//  MainView.swift
//  Taste Test
//
//  Created by Jeff Winkle on 1/26/25.
//

import SwiftUI

struct MainView: View {
    @EnvironmentObject var authViewModel: AuthViewModel // tracks isSignedIn
    @State private var showSignUp = false

    var body: some View {
        if authViewModel.isSignedIn {
            // Logged-in content
            ContentView()
        } else {
            // Not logged in; decide if we’re signing in or signing up
            if showSignUp {
                AccountCreationView(
                    showSignIn: .constant(false),
                    showSignUp: $showSignUp
                )
            } else {
                SignInView(
                  showSignUp: $showSignUp,
                  onSignedIn: {
                    // Tells MainView (or AuthViewModel) we’re now signed in
                    authViewModel.isSignedIn = true
                  }
                )
            }
        }
    }
}
