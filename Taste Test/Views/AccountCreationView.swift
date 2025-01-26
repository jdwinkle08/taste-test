import SwiftUI

struct AccountCreationView: View {
    var body: some View {
        ZStack {
            Color.white // Set the background to white
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 24) {
                Spacer()
                    .frame(height: 10) // Reduce the height of the top spacer to move everything up
                
                // Logo and Welcome Text
                VStack(spacing: 16) {
                    // Icon and Welcome Text
                    VStack(spacing: 20) { // Reduce spacing between icon and text
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.blue)
                        
                        Text("Welcome 👋")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                    }
                    .padding(.bottom, 20) // Reduced padding to bring input fields closer
                    
                    // Text Input Fields
                    VStack(spacing: 15) { // Slightly reduce spacing between input fields for a tighter layout
                        HStack(spacing: 15) { // Reduce spacing between first and last name fields
                            CustomTextField(placeholder: "First Name")
                            CustomTextField(placeholder: "Last Name")
                        }
                        CustomTextField(placeholder: "Email")
                        CustomSecureField(placeholder: "Password") // Password field
                    }
                    .padding(.horizontal, 24)
                }
                
                Spacer() // Push the "Sign Up" button to the bottom
                
                // Sign Up Button
                Button(action: {
                    print("Sign Up Button Pressed")
                }) {
                    Text("Sign Up")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 30) // Reduced spacing at the bottom
            }
        }
    }
}

struct CustomTextField: View {
    let placeholder: String
    @State private var input: String = ""
    
    var body: some View {
        TextField("", text: $input)
            .placeholder(when: input.isEmpty) {
                Text(placeholder)
                    .foregroundColor(Color(.systemGray3)) // Light grey placeholder text
                    .fontWeight(.medium)
            }
            .padding(.vertical, 15) // Reduced vertical padding
            .padding(.horizontal, 12) // Reduced horizontal padding
            .background(Color(.systemGray6)) // Light grey background for the text box
            .cornerRadius(11)
            .font(.body)
    }
}

struct CustomSecureField: View {
    let placeholder: String
    @State private var input: String = ""
    
    var body: some View {
        SecureField("", text: $input)
            .placeholder(when: input.isEmpty) {
                Text(placeholder)
                    .foregroundColor(Color(.systemGray3)) // Light grey placeholder text
                    .fontWeight(.medium)
            }
            .padding(.vertical, 15) // Reduced vertical padding
            .padding(.horizontal, 12) // Reduced horizontal padding
            .background(Color(.systemGray6)) // Light grey background for the text box
            .cornerRadius(11)
            .font(.body)
    }
}

extension View {
    /// A helper modifier to show a placeholder in `SecureField` and `TextField`.
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

struct AccountCreationView_Previews: PreviewProvider {
    static var previews: some View {
        AccountCreationView()
    }
}
