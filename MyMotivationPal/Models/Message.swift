import Foundation

struct Message: Identifiable {
    let id: UUID = UUID()
    let sender: String
    let text: String
    let timestamp: Date
}
