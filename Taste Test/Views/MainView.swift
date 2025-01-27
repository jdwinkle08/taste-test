import SwiftUI

struct MainView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showSignUp = false
    
    // Remove the init() since it creates a new instance of AuthViewModel
    
    var body: some View {
        Group {
            if authViewModel.isSignedIn {
                ContentView()
                // Remove .environmentObject(authViewModel) since it's already passed down from the parent
            } else {
                if showSignUp {
                    AccountCreationView(
                        showSignIn: .constant(false),
                        showSignUp: $showSignUp
                    )
                        .environmentObject(authViewModel) // Add this
                } else {
                    SignInView(
                        showSignUp: $showSignUp,
                        onSignedIn: {
                            print("SignInView: onSignedIn called.")
                            // authViewModel.isSignedIn will be set by the AuthViewModel.signIn() method
                            // so you can remove setting it manually here
                        }
                    )
                        .environmentObject(authViewModel) // Add this
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
