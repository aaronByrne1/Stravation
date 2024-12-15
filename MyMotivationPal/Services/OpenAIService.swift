import Foundation

class OpenAIService {
    private let apiKey = "Insert key here" // Replace with your API key
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
        The user is running a \(distance)-kilometer race with a desired pace of \(desiredPace) minutes per kilometer. They are currently running at \(String(format: "%.2f", currentPace)) minutes per kilometer with a heart rate of \(heartRate) bpm.

        Generate a \(tone) motivational script. The script should be short (about 2-3 sentences), clearly finished, and should not end mid-sentence. End the script naturally and do not trail off. If this is the first script, provide an inspiring introduction. If a previous script is provided, follow it up in a way that feels continuous and relevant.

        Only return the motivational script without extra text.
        """

        if let prev = previousScript, !prev.isEmpty {
            userContent += "\n\nPrevious motivational script: \(prev)\n"
        } else {
            userContent += "\n\nNo previous script provided.\n"
        }

        // Include additional input if provided (e.g., recent audience messages)
        if let additional = additionalInput, !additional.isEmpty {
            userContent += "\n\nAdditional context:\n\(additional)\n"
        }

        let messages: [[String: String]] = [
            [
                "role": "system",
                "content": "You are a motivational running coach. Always produce a complete, coherent script that ends properly."
            ],
            [
                "role": "user",
                "content": userContent
            ]
        ]

        let parameters: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": messages,
            "max_tokens": 75,
            "temperature": 0.7
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