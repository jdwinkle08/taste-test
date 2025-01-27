import SwiftUI

struct MainView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showSignUp = false
    
    init() {
        print("MainView initialized. isSignedIn = \(AuthViewModel().isSignedIn)")
    }

    var body: some View {
        Group {
            if authViewModel.isSignedIn {
                ContentView()
                    .environmentObject(authViewModel)
            } else {
                if showSignUp {
                    AccountCreationView(
                        showSignIn: .constant(false),
                        showSignUp: $showSignUp
                    )
                } else {
                    SignInView(
                        showSignUp: $showSignUp,
                        onSignedIn: {
                            print("SignInView: onSignedIn called.")
                            authViewModel.isSignedIn = true
                        }
                    )
                }
            }
        }
        .onAppear {
            print("MainView appeared. isSignedIn = \(authViewModel.isSignedIn)")
        }
        .onChange(of: authViewModel.isSignedIn) { newValue in
            print("MainView: isSignedIn changed to \(newValue)")
        }
    }
}
