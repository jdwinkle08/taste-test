import SwiftUI
import AVFoundation
import PhotosUI
import Vision
import Down
import Combine

final class KeyboardResponder: ObservableObject {
    @Published var currentHeight: CGFloat = 0

    private var cancellableSet: Set<AnyCancellable> = []

    init() {
        let keyboardShow = NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)
        let keyboardHide = NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)

        Publishers.Merge(keyboardShow, keyboardHide)
            .compactMap { notification in
                if let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                    let screenHeight = UIScreen.main.bounds.height
                    return screenHeight - frame.origin.y
                }
                return 0
            }
            .receive(on: RunLoop.main)
            .sink { [weak self] height in
                self?.currentHeight = height
            }
            .store(in: &cancellableSet)
    }

    deinit {
        cancellableSet.forEach { $0.cancel() }
    }
}

func cleanMarkdown(_ text: String) -> String {
    var cleanedText = text
    // Remove headers
    cleanedText = cleanedText.replacingOccurrences(of: "### ", with: "")
    cleanedText = cleanedText.replacingOccurrences(of: "## ", with: "")
    cleanedText = cleanedText.replacingOccurrences(of: "# ", with: "")
    cleanedText = cleanedText.replacingOccurrences(of: "\n-", with: "\n\n-") // Bullet points
    cleanedText = cleanedText.replacingOccurrences(of: "\n\n\n", with: "\n\n") // Collapse triple line breaks
    cleanedText = cleanedText.replacingOccurrences(of: "\n$", with: "", options: .regularExpression) // Remove final line break
    print("Cleaned Text: \(cleanedText)") // Debugging output
    return cleanedText
}

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @ObservedObject private var keyboard = KeyboardResponder()
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
    @State private var showRecommendationCards: Bool = true
    @State private var showSignUp = false
    @State private var isTyping: Bool = false // Tracks if the system is "typing"
    
    var body: some View {
            ZStack {
                Color.white.edgesIgnoringSafeArea(.all)
                // Main Content
                VStack {
                    // Header
                    HStack {
                        Button(action: {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            withAnimation {
                                isPaneOpen.toggle()
                            }
                        }) {
                            VStack(alignment: .leading, spacing: 4) {
                                Rectangle()
                                    .frame(width: 24, height: 3) // Top line
                                    .cornerRadius(1.5)
                                Rectangle()
                                    .frame(width: 24, height: 3) // Middle line
                                    .cornerRadius(1.5)
                                Rectangle()
                                    .frame(width: 16, height: 3) // Bottom line (shorter)
                                    .cornerRadius(1.5)
                            }
                            .foregroundColor(.blue)
                            .padding(20)
                        }
                        
                        Spacer()
                        
                        // Replace the greeting text with the company logo
                        Image("mainLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 108, height: 36) // Adjust size as needed
                            .frame(maxWidth: .infinity, alignment: .center) // Ensure centering
                        
                        // Invisible placeholder for alignment
                        Button(action: {}) {
                            VStack(alignment: .leading, spacing: 4) {
                                Rectangle()
                                    .frame(width: 24, height: 3) // Top line
                                    .cornerRadius(1.5)
                                Rectangle()
                                    .frame(width: 24, height: 3) // Middle line
                                    .cornerRadius(1.5)
                                Rectangle()
                                    .frame(width: 16, height: 3) // Bottom line (shorter)
                                    .cornerRadius(1.5)
                            }
                            .foregroundColor(.blue)
                            .padding(20)
                        }
                        .opacity(0) // Make the placeholder invisible
                        .accessibilityHidden(true) // Optional: Hide from accessibility
                    }
                    .padding(.bottom, 8)
                    
                    
                    // Chat Window
                    ScrollViewReader { scrollViewProxy in
                        ScrollView {
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(messages) { message in
                                    if message.isImage, let image = message.image {
                                        HStack {
                                            Spacer()
                                            Image(uiImage: image)
                                                .resizable()
                                                .scaledToFit()
                                                .frame(maxWidth: 250)
                                                .cornerRadius(20)
                                                .padding(.horizontal, 8)
                                        }
                                    } else {
                                        HStack {
                                            if message.isUser {
                                                Spacer()
                                                Text(cleanMarkdown(message.text).trimmingCharacters(in: .whitespacesAndNewlines))
                                                    .font(.system(size: 16))
                                                    .padding(.horizontal, 10)
                                                    .padding(.vertical, 8)
                                                    .background(Color.blue)
                                                    .foregroundColor(.white)
                                                    .cornerRadius(20)
                                                    .frame(maxWidth: 250, alignment: .trailing)
                                            } else {
                                                Text(cleanMarkdown(message.text).trimmingCharacters(in: .whitespacesAndNewlines))
                                                    .font(.system(size: 16))
                                                    .padding(.horizontal, 10)
                                                    .padding(.vertical, 8)
                                                    .background(Color(.systemGray5))
                                                    .foregroundColor(.black)
                                                    .cornerRadius(20)
                                                    .frame(maxWidth: 250, alignment: .leading)
                                                    .multilineTextAlignment(.leading)
                                                Spacer()
                                            }
                                        }
                                        .padding(.horizontal, 8)
                                    }
                                }
                                if isTyping {
                                    HStack {
                                        TypingIndicatorView()
                                        Spacer()
                                    }
                                    .padding(.horizontal, 8)
                                }
                            }
                            .padding(.top, 8)
//                            .padding(.bottom, keyboard.currentHeight) // Adjust for keyboard height
                            .id("BOTTOM") // Set a scroll marker
                        }
                        .onAppear {
                            // Scroll to the bottom when the view initially appears
                            scrollViewProxy.scrollTo("BOTTOM", anchor: .bottom)
                        }
                        .onChange(of: messages) { _ in
                            // Auto-scroll when a new message is added
                            withAnimation {
                                scrollViewProxy.scrollTo("BOTTOM", anchor: .bottom)
                            }
                        }
                        .onChange(of: keyboard.currentHeight) { _ in
                            // Scroll to the bottom when the keyboard height changes
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation {
                                    scrollViewProxy.scrollTo("BOTTOM", anchor: .bottom)
                                }
                            }
                        }
                    }
                    
                    // Instruction Rectangles
                    if showRecommendationCards {
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
                                ImagePicker(isPresented: $isCameraActive, selectedImage: $capturedImage, sourceType: .camera) { image in
                                    handleImage(image)
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
                    }
                    
                    // Input Box with Circular Button
                    HStack {
                        Button(action: {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            // Close keyboard before showing menu
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
                        
                        ZStack(alignment: .leading) {
                            TextField("Type Message", text: $currentMessage)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .padding(.trailing, 30) // Reserve space for the "Send" button
                                .cornerRadius(20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                                .gesture(
                                    DragGesture()
                                        .onChanged { value in
                                            if value.translation.height > 0 { // Detect downward swipe
                                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                            }
                                        }
                                )
                        }
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
                .blur(radius: isMenuVisible ? 8 : 0)
                
                // Tap Outside to Close Menu
                if isMenuVisible {
                    Color.black.opacity(0.01)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation {
                                isMenuVisible = false
                            }
                        }
                }
                
                // Side Pane
                if isPaneOpen {
                    Color.black.opacity(0.01)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation {
                                isPaneOpen = false
                            }
                        }
                }
                
                HStack {
                    VStack {
                        // Add the logo to the top of the side pane
                        Image("mainLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 180, height: 60) // Adjust size as needed
                            .padding(.top, 16) // Minimum padding
                            .padding(.top, UIApplication.safeAreaTopInset)
                            .padding(.bottom, 20) // Add spacing below the logo

                        Spacer()
                        
                        // Settings Button
//                        Button(action: {
//                            print("Settings button tapped!")
//                        }) {
//                            HStack {
//                                Image(systemName: "gear")
//                                    .font(.system(size: 16))
//                                    .foregroundColor(.gray)
//                                Text("Settings")
//                                    .font(.headline)
//                                    .foregroundColor(.gray)
//                            }
//                            .frame(maxWidth: .infinity)
//                            .padding()
//                            .background(Color(.systemGray5))
//                            .cornerRadius(10)
//                            .padding(.horizontal, 16)
//                        }
                        
                        // Sign Out Button
                        Button(action: {
                            Task {
                                authViewModel.signOut()
                            }
                        }) {
                            Text("Sign out")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                        }
                        .padding(.bottom, 32) // Add spacing at the bottom
                    }
                    .frame(width: 320)
                    .background(
                        Color.white
                            .cornerRadius(16, corners: [.topRight, .bottomRight])
                            .shadow(color: Color.black.opacity(0.15), radius: 6, x: 2, y: 0)
                    )
                    .edgesIgnoringSafeArea(.all)
                    Spacer()
                }
                .offset(x: isPaneOpen ? 0 : -320 + dragOffset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let translation = value.translation.width
                            dragOffset = max(-320, min(0, translation))
                        }
                        .onEnded { value in
                            if dragOffset > -120 {
                                withAnimation {
                                    isPaneOpen = true
                                }
                            } else {
                                withAnimation {
                                    isPaneOpen = false
                                }
                            }
                            dragOffset = 0
                        }
                )
                .animation(.easeInOut, value: isPaneOpen)
                
                // Pop-up Menu
                if isMenuVisible {
                    VStack(alignment: .leading, spacing: 30) {
                        Button(action: {
                            withAnimation {
                                isMenuVisible = false
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                isCameraActive = true
                            }
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
                        .fullScreenCover(isPresented: $isCameraActive) {
                            ImagePicker(isPresented: $isCameraActive, selectedImage: $capturedImage, sourceType: .camera) { image in
                                handleImage(image)
                            }
                            .ignoresSafeArea()
                        }
                        
                        Button(action: {
                            withAnimation {
                                isMenuVisible = false
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                isPhotoPickerActive = true
                            }
                        }) {
                            HStack(spacing: 22) {
                                Image("photosAppIcon")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 36, height: 36)
                                Text("Upload a Photo")
                                    .foregroundColor(.black)
                                    .font(.system(size: 24))
                            }
                        }
                    }
                    .scaleEffect(menuScale)
                    .opacity(menuOpacity)
                    .frame(width: 250)
                    .position(x: 138, y: UIScreen.main.bounds.height - 218) // Adjust position
                }
            }
            .sheet(isPresented: $isPhotoPickerActive) {
                ImagePicker(isPresented: $isPhotoPickerActive, selectedImage: $capturedImage, sourceType: .photoLibrary) { image in
                    handleImage(image)
                }
            }
        }
    
    func handleImage(_ image: UIImage?) {
        guard let image = image else { return }

        // Hide recommendation cards after the first user action
        if showRecommendationCards {
            showRecommendationCards = false
        }

        // Append the image to the chat UI
        messages.append(Message(image: image)) // Only the image appears in chat

        // Perform OCR on the uploaded image
        performOCR(on: image) { recognizedText in
            DispatchQueue.main.async {
                if !recognizedText.isEmpty {
//                    print("OCR Text Extracted: \(recognizedText)") // Debugging Output

                    // Pass the OCR text to OpenAI, without appending it to `messages`
                    callOpenAIAPI(for: recognizedText, isUserMessage: false)
                } else {
                    // If no text is found, inform the user
                    messages.append(Message(text: "This wasn't recognized as a menu, so there's not much I can recommend to you 😇", isUser: false))
                }
            }
        }
    }
    
    func performOCR(on image: UIImage, completion: @escaping (String) -> Void) {
        guard let cgImage = image.cgImage else {
            print("OCR failed: No CGImage found in the provided UIImage.")
            completion("")
            return
        }
        
        let request = VNRecognizeTextRequest { (request, error) in
            if let error = error {
                print("OCR Error: \(error)")
                completion("")
                return
            }
            
            let observations = request.results as? [VNRecognizedTextObservation] ?? []
            let recognizedText = observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
//            print("OCR Recognized Text: \(recognizedText)") // Debugging Output
            completion(recognizedText)
        }
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try requestHandler.perform([request])
            } catch {
                print("Error performing OCR: \(error)")
                completion("")
            }
        }
    }
    
    func sendMessage() {
        guard !currentMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // Hide recommendation cards after the first user action
        if showRecommendationCards {
            showRecommendationCards = false
        }
        
        let userMessage = Message(text: currentMessage, isUser: true)
        messages.append(userMessage)
        currentMessage = ""
        showSendButton = false
        callOpenAIAPI(for: userMessage.text)
    }
    
    func callOpenAIAPI(for message: String, isUserMessage: Bool = true) {
        isLoading = true
        isTyping = true
        
        guard let apiKey = Bundle.main.infoDictionary?["OPENAI_API_KEY"] as? String else {
            fatalError("API Key not found in Secrets.xcconfig")
        }

        let endpoint = "https://api.openai.com/v1/chat/completions"

        // Prepare the OpenAI API conversation history
        var openAIMessages: [[String: String]] = [
            ["role": "system", "content": """
            Give top 3 recommendations for food and/or drink from menu items sent. 
            Give each item name *without* list of ingredients, 
            followed by a 3-5 word description why you think I should order it. 
            Ensure you always include line breaks to separate items, but use plain text formatting (no headers or dashes or bullets) for human-readable display in an iMessage chat. Here is an example of how to format output: 
            
            I'd recommend...
            
            1. SPICY TONKOTSU: If you're looking for something warm
            
            2. MAMA'S GREEN CURRY CHICKEN: For a hearty and less spicy option
            
            3. SEAWEED SALAD: Great light option to share with the table
            """]
        ]

        // Add conversation history (excluding images)
        openAIMessages += messages.filter { !$0.isImage }.map { message in
            [
                "role": message.isUser ? "user" : "assistant",
                "content": message.text
            ]
        }

        // If this is OCR text (not a visible user message), append it to the OpenAI messages
        if !isUserMessage {
            openAIMessages.append(["role": "user", "content": message])
        }

        // Debugging: Log the compiled conversation
        print("OpenAI Messages Payload: \(openAIMessages)")

        let payload: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": openAIMessages
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
                isTyping = false
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

            print("OpenAI Response Content: \(content)") // Debugging Output

            DispatchQueue.main.async {
                // Append the assistant's response to the chat
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

// Image Picker Component
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    @Binding var selectedImage: UIImage?
    var sourceType: UIImagePickerController.SourceType = .camera
    var onImagePicked: (UIImage?) -> Void

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
                parent.onImagePicked(image)
            }
            parent.isPresented = false
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
        picker.sourceType = sourceType

        // Set full screen presentation
        picker.modalPresentationStyle = .fullScreen
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}

// Chat Message Model
struct Message: Identifiable, Equatable {
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

    static func == (lhs: Message, rhs: Message) -> Bool {
        return lhs.id == rhs.id
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

    struct TypingIndicatorView: View {
        @State private var isAnimating = false

        var body: some View {
            HStack(spacing: 6) {
                Circle()
                    .frame(width: 8, height: 8)
                    .foregroundColor(.gray)
                    .scaleEffect(isAnimating ? 0.5 : 1.0)
                    .animation(.easeInOut(duration: 0.6).repeatForever(), value: isAnimating)
                Circle()
                    .frame(width: 8, height: 8)
                    .foregroundColor(.gray)
                    .scaleEffect(isAnimating ? 0.5 : 1.0)
                    .animation(.easeInOut(duration: 0.6).repeatForever().delay(0.2), value: isAnimating)
                Circle()
                    .frame(width: 8, height: 8)
                    .foregroundColor(.gray)
                    .scaleEffect(isAnimating ? 0.5 : 1.0)
                    .animation(.easeInOut(duration: 0.6).repeatForever().delay(0.4), value: isAnimating)
            }
            .onAppear {
                isAnimating = true
            }
            .onDisappear {
                isAnimating = false
            }
        }
    }
