import Foundation
struct Profile: Decodable {
  let username: String?
  let fullName: String?
  let website: String?

  enum CodingKeys: String, CodingKey {
    case username
    case fullName = "full_name"
    case website
  }
}

struct UpdateProfileParams: Encodable {
  let username: String
  let fullName: String
  let website: String

  enum CodingKeys: String, CodingKey {
    case username
    case fullName = "full_name"
    case website
  }
}

struct Run: Codable, Identifiable {
    let id: UUID
    let user_id: UUID
    let start_time: String
    let route: [[Double]]
    let is_active: Bool
}

struct NewRun: Codable {
    let user_id: UUID
    let start_time: String
    let route: [[Double]]
    let is_active: Bool
}



struct RunMessage: Decodable, Encodable, Identifiable {
    let id: UUID?
    let run_id: UUID
    let sender: String
    let message: String
    let timestamp: Date
}
