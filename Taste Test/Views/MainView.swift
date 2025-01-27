//
//  MainView.swift
//  Taste Test
//
//  Created by Jeff Winkle on 1/26/25.
//

import SwiftUI

struct MainView: View {
    @State private var showSignUp = true
    @State private var showSignIn = false

    var body: some View {
        if showSignUp {
            AccountCreationView(
                showSignIn: $showSignIn,
                showSignUp: $showSignUp 
            )
        } else if showSignIn {
            SignInView(showSignUp: $showSignUp)
        }
    }
}
