import SwiftUI
import AVFoundation
import PhotosUI

struct ContentView: View {
    @State private var messages: [Message] = [] // Array of messages
    @State private var currentMessage: String = "" // Current text input
    @State private var showSendButton: Bool = false // Controls send button visibility
    @State private var isCameraActive: Bool = false // Camera activation state
    @State private var capturedImage: UIImage? = nil // Captured image from the camera
    @State private var isPaneOpen: Bool = false // Side pane toggle
    @State private var dragOffset: CGFloat = 0.0 // Tracks drag offset for the pane
    @State private var isLoading: Bool = false // Tracks if an OpenAI request is in progress
    @State private var isMenuVisible: Bool = false // Camera option menu visibility
    @State private var menuScale: CGFloat = 0.8 // Initial scale for the menu
    @State private var menuOpacity: Double = 0.0 // Initial opacity for the menu
    @State private var isPhotoPickerActive: Bool = false // Photo picker activation state


    var body: some View {
        ZStack {
            // Main Content
            VStack {
                // Header
                HStack {
                    // Menu Button
                    Button(action: {
                        withAnimation {
                            isPaneOpen.toggle()
                        }
                    }) {
                        Image(systemName: "line.horizontal.3")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.blue)
                    }
                    .padding(.leading, 16)

                    Spacer()

                    // Header Text with "Jeff" bolded
                    Text("Hey, ")
                        .font(.system(size: 18))
                        .foregroundColor(.black)
                    +
                    Text("Jeff")
                        .font(.system(size: 18))
                        .foregroundColor(.black)
                    +
                    Text(" 👋")
                        .font(.system(size: 18))
                        .foregroundColor(.black)

                    Spacer()

                    // Placeholder for symmetry
                    Spacer().frame(width: 40) // Matches the width of the button
                }
                .padding(.top, 16) // Adjust based on notch height
                .padding(.bottom, 8)

                // Chat Window
                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(messages) { message in
                            if message.isImage, let image = message.image {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: 250)
                                    .cornerRadius(20)
                                    .padding(.horizontal, 8)
                            } else {
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
                                .padding(.horizontal, 8)
                            }
                        }
                    }
                    .padding(.top, 8)
                }

                // Instruction Rectangles
                HStack(spacing: 10) {
                    Button(action: {
                        isCameraActive = true
                    }) {
                        Text("First, take a photo of the menu ↗")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .cornerRadius(12)
                            .scaleEffect(isCameraActive ? 0.95 : 1.0)
                            .animation(.easeInOut(duration: 0.2), value: isCameraActive)
                            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .fullScreenCover(isPresented: $isCameraActive) {
                        ImagePicker(isPresented: $isCameraActive, selectedImage: $capturedImage) { image in
                            if let image = image {
                                messages.append(Message(image: image))
                            }
                        }
                    }

                    InstructionRectangle(
                        text: "🥇 See the top choices",
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
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)

                // Input Box with Circular Button
                HStack {
                    // Circular Button
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0)) {
                            isMenuVisible.toggle()
                            if isMenuVisible {
                                menuScale = 1.0
                                menuOpacity = 1.0
                            } else {
                                menuScale = 0.8
                                menuOpacity = 0.0
                            }
                        }
                    }) {
                        Circle()
                            .fill(Color(.systemGray5))
                            .frame(width: 35, height: 35)
                            .overlay(
                                Image(systemName: "plus")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 18))
                            )
                    }

                    // Text Input Field
                    TextField("Type Message", text: $currentMessage)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                        .autocorrectionDisabled(false)
                        .textInputAutocapitalization(.sentences)
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
                            showSendButton = !newValue.isEmpty
                        }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .blur(radius: isMenuVisible ? 8 : 0) // Blur background when menu is visible

            // Tap Outside to Close Menu
            if isMenuVisible {
                Color.black.opacity(0.01) // Transparent tappable background
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation {
                            isMenuVisible = false
                        }
                    }
            }

            // Pop-up Menu
            if isMenuVisible {
                VStack(alignment: .leading, spacing: 30) {
                    Button(action: {
                        isMenuVisible = false
                        isCameraActive = true
                    }) {
                        HStack(spacing: 22) {
                            Image("cameraAppIcon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 36, height: 36)
                            Text("Take a Picture")
                                .foregroundColor(.black)
                                .font(.system(size: 24))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Button(action: {
                        isMenuVisible = false
                        isPhotoPickerActive = true
                    }) {
                        HStack(spacing: 22) {
                            Image("photosAppIcon") // Use the custom photos icon
                                .resizable()
                                .scaledToFit()
                                .frame(width: 36, height: 36)
                            Text("Upload a Photo")
                                .foregroundColor(.black)
                                .font(.system(size: 24))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(width: 250)
                .position(x: 150, y: UIScreen.main.bounds.height - 218) // Adjusts position above the button
            }
        }
        .sheet(isPresented: $isPhotoPickerActive) {
            ImagePicker(isPresented: $isPhotoPickerActive, selectedImage: $capturedImage) { image in
                if let image = image {
                    messages.append(Message(image: image))
                }
            }
        }
        .fullScreenCover(isPresented: $isCameraActive) {
            ImagePicker(isPresented: $isCameraActive, selectedImage: $capturedImage) { image in
                if let image = image {
                    messages.append(Message(image: image))
                }
            }
        }
    }
    
    func sendMessage() {
        guard !currentMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let userMessage = Message(text: currentMessage, isUser: true)
        messages.append(userMessage)
        currentMessage = ""
        showSendButton = false

        // Call OpenAI API
        callOpenAIAPI(for: userMessage.text)
    }

    func callOpenAIAPI(for message: String) {
        isLoading = true
        guard let apiKey = Bundle.main.infoDictionary?["OPENAI_API_KEY"] as? String else {
            fatalError("API Key not found in Secrets.xcconfig")
        }
        let endpoint = "https://api.openai.com/v1/chat/completions"

        let payload: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": [
                ["role": "system", "content": "You are a helpful assistant."],
                ["role": "user", "content": message]
            ]
        ]

        guard let url = URL(string: endpoint),
              let httpBody = try? JSONSerialization.data(withJSONObject: payload) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = httpBody

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
            }

            if let error = error {
                print("Error calling OpenAI API: \(error.localizedDescription)")
                return
            }

            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let firstChoice = choices.first,
                  let messageDict = firstChoice["message"] as? [String: Any],
                  let content = messageDict["content"] as? String else {
                print("Invalid response from OpenAI API")
                return
            }

            DispatchQueue.main.async {
                messages.append(Message(text: content, isUser: false))
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
            .font(.system(size: 14, weight: isBold ? .bold : .regular))
            .multilineTextAlignment(.leading)
            .lineLimit(2)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(backgroundColor)
            .foregroundColor(textColor)
            .cornerRadius(12)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// Image picker component
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    @Binding var selectedImage: UIImage?
    var onImagePicked: (UIImage?) -> Void

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            parent.isPresented = false
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
                parent.onImagePicked(image)
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isPresented = false
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.cameraDevice = .rear
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}

// Chat Message Model
struct Message: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
    let isImage: Bool
    let image: UIImage?

    init(text: String, isUser: Bool) {
        self.text = text
        self.isUser = isUser
        self.isImage = false
        self.image = nil
    }

    init(image: UIImage) {
        self.text = ""
        self.isUser = true
        self.isImage = true
        self.image = image
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect,
                                byRoundingCorners: corners,
                                cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
