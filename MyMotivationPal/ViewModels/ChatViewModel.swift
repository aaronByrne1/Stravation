//import Foundation
//import Combine
//
//class ChatViewModel: ObservableObject {
//    @Published var messages: [Message] = []
//    @Published var aiResponse: String = ""
//
//    private var supabaseService: SupabaseService
//    private var elevenLabsAPI: ElevenLabsAPI
//
//    private var cancellables = Set<AnyCancellable>()
//
//    init(supabase: SupabaseService, elevenLabs: ElevenLabsAPI) {
//        self.supabaseService = supabase
//        self.elevenLabsAPI = elevenLabs
//
//        // Listen for incoming messages from Supabase in real-time
//        supabaseService.messagePublisher
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] newMessage in
//                self?.messages.append(newMessage)
//                self?.respondToNewMessage(newMessage)
//            }
//            .store(in: &cancellables)
//    }
//
//    func respondToNewMessage(_ message: Message) {
//        // Here you could formulate a prompt for Eleven Labs
//        // For example: "My friend said: \(message.text). Summarize this in a funny way."
//        let prompt = "My friend said: \(message.text). Respond with a humorous summary."
//
//        elevenLabsAPI.getAIResponse(for: prompt) { [weak self] responseText in
//            DispatchQueue.main.async {
//                self?.aiResponse = responseText
//            }
//        }
//    }
//}
