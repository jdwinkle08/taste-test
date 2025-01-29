import SwiftUI

struct MainView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showSignUp = false
    @State private var showSignIn = false // Added to manage SignInView

    var body: some View {
        Group {
            if authViewModel.isSignedIn {
                ContentView()
            } else {
                if showSignUp {
                    AccountCreationView(
                        showSignIn: $showSignIn,
                        showSignUp: $showSignUp,
                        onSignedUp: {
                            print("MainView: onSignedUp called.")
                            authViewModel.isSignedIn = true
                        }
                    )
                    .environmentObject(authViewModel)
                } else if showSignIn {
                    SignInView(
                        showSignIn: $showSignIn, // Pass the binding
                        showSignUp: $showSignUp,
                        onSignedIn: {
                            print("MainView: onSignedIn called.")
                            authViewModel.isSignedIn = true
                        }
                    )
                    .environmentObject(authViewModel)
                } else {
                    // Initial View: Choose to Sign In or Sign Up
                    VStack(spacing: 20) {
                        Image("mainLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 240, height: 240) // Adjust size as needed
//                            .padding(.bottom, 20) // Add spacing from the buttons
                    
                        Button(action: {
                            showSignUp = true
                        }) {
                            Text("Sign Up")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(width: 300, height: 50)
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                        
                        Button(action: {
                            showSignIn = true
                        }) {
                            Text("Sign In")
                                .font(.headline)
                                .foregroundColor(.blue)
                                .frame(width: 300, height: 50)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.blue, lineWidth: 2)
                                )
                        }
                    }
                }
            }
        }
        .onAppear {
            print("MainView appeared. isSignedIn = \(authViewModel.isSignedIn)")
        }
        .onChange(of: authViewModel.isSignedIn) { newValue in
            print("MainView: isSignedIn changed to \(newValue)")
        }
        .animation(.easeInOut, value: authViewModel.isSignedIn)
    }
}
