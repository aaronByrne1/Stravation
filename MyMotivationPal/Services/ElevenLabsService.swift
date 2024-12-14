import Foundation

class ElevenLabsService {
    private let apiKey = "<Insert Key here>" // Replace with your actual API key
    private let voiceID = "CA5Yl0Vmw08Q59GgjVyW" // Replace with a valid Eleven Labs voice ID
    private let endpoint = "https://api.elevenlabs.io/v1/text-to-speech"
    
    /// Generate speech audio from text using Eleven Labs API
    /// - Parameters:
    ///   - script: The text to convert into speech
    ///   - completion: Called with Data representing the audio content (in WAV format) or nil if failure
    func generateSpeech(script: String, completion: @escaping (Data?) -> Void) {
        guard let url = URL(string: "\(endpoint)/\(voiceID)") else {
            completion(nil)
            return
        }
        
        let parameters: [String: Any] = [
            "text": script,
            "model_id": "eleven_monolingual_v1",
            "voice_settings": [
                "stability": 0.3,
                "similarity_boost": 0.75
            ]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "xi-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
        } catch {
            print("JSON Serialization Error: \(error)")
            completion(nil)
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Eleven Labs API Error: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let data = data else {
                print("No data received from Eleven Labs")
                completion(nil)
                return
            }
            
            // Eleven Labs returns an audio file in binary. Just pass it back.
            completion(data)
        }
        task.resume()
    }
}
