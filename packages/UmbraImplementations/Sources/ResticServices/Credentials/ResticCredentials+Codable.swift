import Foundation
import ResticInterfaces

// Add Codable conformance to ResticCredentials to support JSON serialization
extension ResticCredentials: Codable {
  enum CodingKeys: String, CodingKey {
    case repositoryIdentifier
    case password
  }

  public init(from decoder: Decoder) throws {
    let container=try decoder.container(keyedBy: CodingKeys.self)
    let repositoryID=try container.decode(String.self, forKey: .repositoryIdentifier)
    let password=try container.decode(String.self, forKey: .password)
    self.init(repositoryIdentifier: repositoryID, password: password)
  }

  public func encode(to encoder: Encoder) throws {
    var container=encoder.container(keyedBy: CodingKeys.self)
    try container.encode(repositoryIdentifier, forKey: .repositoryIdentifier)
    try container.encode(password, forKey: .password)
  }
}
