import SwiftUI

struct ContentView: View {
    @State private var messages: [Message] = [] // Array of messages
    @State private var currentMessage: String = "" // Current text input
    @State private var showSendButton: Bool = false // Controls send button visibility
    @State private var isLoading: Bool = false
    
    var body: some View {
        VStack {
            // Chat Window
            ScrollView {
                VStack(alignment: .leading, spacing: 6) { // Smaller spacing between bubbles
                    ForEach(messages) { message in
                        HStack {
                            if message.isUser {
                                Spacer()
                                Text(message.text)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(20)
                                    .frame(maxWidth: 250, alignment: .trailing)
                            } else {
                                Text(message.text)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    .background(Color(.systemGray5))
                                    .foregroundColor(.black)
                                    .cornerRadius(20)
                                    .frame(maxWidth: 250, alignment: .leading)
                                Spacer()
                            }
                        }
                        .padding(.horizontal, 8) // Reduced horizontal padding for cleaner alignment
                    }
                }
                .padding(.top, 8) // Add a little spacing at the top of the chat
            }
            
            // Instruction Rectangles
            HStack(spacing: 10) { // Equal spacing between bubbles
                InstructionRectangle(
                    text: "First, take a photo of the menu ↗",
                    backgroundColor: Color.blue,
                    textColor: Color.white,
                    isBold: true
                )
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4) // Soft shadow with subtle offset
                InstructionRectangle(
                    text: "🥇 Get the top choices",
                    backgroundColor: Color(.systemGray5),
                    textColor: Color.black,
                    isBold: false
                )
                InstructionRectangle(
                    text: "🧑‍🍳 Ask follow ups",
                    backgroundColor: Color(.systemGray5),
                    textColor: Color.black,
                    isBold: false
                )
            }
            .frame(maxWidth: .infinity) // Ensures the HStack stretches across the available width
            .padding(.horizontal, 16) // Adds equal padding to the left and right of the entire group
            
            // Input Box
            HStack {
                TextField("Type Message", text: $currentMessage)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                    .autocorrectionDisabled(false) // Enables autocorrection
                    .textInputAutocapitalization(.sentences) // Capitalizes the first word in a sentence
                    .overlay(
                        HStack {
                            Spacer()
                            if showSendButton {
                                Button(action: sendMessage) {
                                    Image(systemName: "paperplane.fill")
                                        .foregroundColor(.blue)
                                        .padding(.trailing, 12)
                                }
                            }
                        }
                    )
                    .onChange(of: currentMessage) { newValue in
                        showSendButton = !newValue.isEmpty // Show/hide send button based on input
                    }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(.systemBackground))
    }
    
    func sendMessage() {
        guard !currentMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let userMessage = Message(text: currentMessage, isUser: true)
        messages.append(userMessage) // Add user's message
        currentMessage = "" // Clear the input box
        showSendButton = false // Hide send button
        
        // Call OpenAI API to get the response
        callOpenAIAPI(for: userMessage.text)
    }
    
    func callOpenAIAPI(for message: String) {
        isLoading = true
        guard let apiKey = Bundle.main.infoDictionary?["OPENAI_API_KEY"] as? String else {
            fatalError("API Key not found in Secrets.xcconfig")
        }
        let endpoint = "https://api.openai.com/v1/chat/completions"
        
        // Create request payload
        let payload: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": [
                ["role": "system", "content": "You are a helpful assistant."],
                ["role": "user", "content": message]
            ]
        ]
        
        // Convert payload to JSON
        guard let url = URL(string: endpoint),
              let httpBody = try? JSONSerialization.data(withJSONObject: payload) else {
            print("Error: Failed to create request payload.")
            isLoading = false
            return
        }
        
        // Create the request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = httpBody
        
        // Perform the API call
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
            }
            
            if let error = error {
                print("Error calling OpenAI API: \(error.localizedDescription)")
                return
            }
            
            // Log the HTTP response status code
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Response Status Code: \(httpResponse.statusCode)")
                if httpResponse.statusCode != 200 {
                    print("Unexpected HTTP status code.")
                }
            }
            
            // Log the raw data received
            if let data = data {
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Raw JSON response: \(jsonString)")
                }
            } else {
                print("Error: No data received from OpenAI API.")
                return
            }
            
            // Parse the JSON response
            do {
                guard let data = data,
                      let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    print("Error: Unable to parse JSON.")
                    return
                }
                print("Parsed JSON: \(json)")
                
                guard let choices = json["choices"] as? [[String: Any]],
                      let firstChoice = choices.first,
                      let messageDict = firstChoice["message"] as? [String: Any],
                      let content = messageDict["content"] as? String else {
                    print("Error: Missing 'choices' or 'message' in the response.")
                    return
                }
                
                // Add OpenAI's response to the chat
                let assistantMessage = Message(text: content, isUser: false)
                DispatchQueue.main.async {
                    self.messages.append(assistantMessage)
                }
            } catch {
                print("Error decoding JSON: \(error.localizedDescription)")
            }
        }.resume()
    }
}

// Custom view for instruction rectangles
struct InstructionRectangle: View {
    let text: String
    let backgroundColor: Color
    let textColor: Color
    let isBold: Bool

    var body: some View {
        Text(text)
            .font(.system(size: 14, weight: isBold ? .bold : .regular)) // Bold for the first rectangle
            .multilineTextAlignment(.leading) // Left-align text
            .lineLimit(2) // Ensures text wraps to two lines
            .padding(.horizontal, 12) // Inner padding for text
            .padding(.vertical, 8) // Inner padding for text
            .background(backgroundColor)
            .foregroundColor(textColor)
            .cornerRadius(12)
            .fixedSize(horizontal: false, vertical: true) // Dynamically resizes horizontally for content
    }
}

// Chat Message Model
struct Message: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool // True if sent by the user, false if received
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
