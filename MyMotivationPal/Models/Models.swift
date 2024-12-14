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
