import Foundation

class Environment {
    static let shared = Environment()

    private var variables: [String: String] = [:]

    private init() {
        guard let path = Bundle.main.path(forResource: ".env", ofType: nil) else {
            //print("No .env file found")
            return
        }
        
        do {
            let data = try String(contentsOfFile: path, encoding: .utf8)
            let lines = data.split(whereSeparator: \.isNewline)
            
            for line in lines {
                let parts = line.split(separator: "=", maxSplits: 1)
                if parts.count == 2 {
                    let key = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
                    let value = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                    variables[key] = value
                }
                //print("Loaded .env values:")
                for (key, value) in variables {
                    //print("\(key): \(value)")
                }

            }
        } catch {
            //print("Failed to load .env file: \(error.localizedDescription)")
        }
    }

    func get(_ key: String) -> String? {
        return variables[key]
    }
}
