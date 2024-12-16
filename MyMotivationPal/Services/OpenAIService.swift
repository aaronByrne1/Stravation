import Foundation

class OpenAIService {
    private let apiKey = "Insert your OpenAI API Key" // Replace with your API key
    private let endpoint = "https://api.openai.com/v1/chat/completions"
    
    func generateMotivationalScript(
        distance: String,
        desiredPace: String,
        currentPace: Double,
        heartRate: Int,
        tone: String,
        previousScript: String? = nil,
        additionalInput: String? = nil,
        completion: @escaping (String?) -> Void
    ) {
        guard let url = URL(string: endpoint) else {
            print("Invalid URL")
            completion(nil)
            return
        }

        print("OpenAI Chat API hit")

        // Build the user prompt
        // Include instructions to keep it short and ensure it doesn't end mid-sentence.
        var userContent = """
        The runner is targeting a pace of \(desiredPace) minutes per kilometer over a distance of \(distance) kilometers. They are currently running at a pace of \(String(format: "%.2f", currentPace)) minutes per kilometer, with a heart rate of \(heartRate) bpm.

        Supporter messages:
        \(additionalInput ?? "No messages yet.").

        Generate a motivational script that is funny, harsh, and motivating. Include the runner's heart rate, current pace, target pace, target distance, and supporter messages naturally in the text. Ensure the script is dynamic and unique each time. Keep it no more than 6 sentences.
        """

        let messages: [[String: String]] = [
            [
                "role": "system",
                "content": "You are a motivational running coach. Your tone is funny, harsh, and inspiring. Always include the runner's heart rate, current pace, desired pace, target distance, and supporter messages in your script."
            ],
            [
                "role": "user",
                "content": userContent
            ]
        ]

        let parameters: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": messages,
            "max_tokens": 200, // Increased token limit for a richer response
            "temperature": 0.8 // Slightly increased randomness for varied results
        ]




        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
        } catch {
            print("JSON Serialization Error: \(error.localizedDescription)")
            completion(nil)
            return
        }

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            // Handle errors first
            if let error = error {
                print("OpenAI API Error: \(error.localizedDescription)")
                completion(nil)
                return
            }

            guard let data = data else {
                print("OpenAI API Error: No data received")
                completion(nil)
                return
            }

            // Debugging the raw response if needed
            // print("Raw response: \(String(data: data, encoding: .utf8) ?? "No readable data")")

            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let message = choices.first?["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    let script = content.trimmingCharacters(in: .whitespacesAndNewlines)
                    completion(script)
                } else {
                    print("OpenAI API: Unexpected response format")
                    completion(nil)
                }
            } catch {
                print("JSON Parsing Error: \(error.localizedDescription)")
                completion(nil)
            }
        }
        task.resume()
    }
}
