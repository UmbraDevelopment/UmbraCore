import Foundation

/// Extension for converting between Foundation types and UserDefaultsValueDTO
public extension UserDefaultsValueDTO {
    /// Create a UserDefaultsValueDTO from a Foundation object
    /// - Parameter object: The object to convert
    /// - Returns: A UserDefaultsValueDTO or nil if the object type is not supported
    static func from(object: Any?) -> UserDefaultsValueDTO? {
        guard let object = object else {
            return .null
        }

        switch object {
        case let value as String:
            return .string(value)
        case let value as Int:
            return .integer(value)
        case let value as Double:
            return .double(value)
        case let value as Bool:
            return .boolean(value)
        case let value as Data:
            return .data([UInt8](value))
        case let value as URL:
            return .url(value.absoluteString)
        case let value as Date:
            return .date(value.timeIntervalSince1970)
        case let value as [String]:
            return .stringArray(value)
        case let value as [Any]:
            // Convert array elements recursively
            var convertedArray: [UserDefaultsValueDTO] = []
            for item in value {
                if let converted = UserDefaultsValueDTO.from(object: item) {
                    convertedArray.append(converted)
                } else {
                    // If any element can't be converted, return nil
                    return nil
                }
            }
            return .array(convertedArray)
        case let value as [String: Any]:
            // Convert dictionary values recursively
            var convertedDict: [String: UserDefaultsValueDTO] = [:]
            for (key, dictValue) in value {
                if let converted = UserDefaultsValueDTO.from(object: dictValue) {
                    convertedDict[key] = converted
                } else {
                    // If any value can't be converted, skip it
                    continue
                }
            }
            return .dictionary(convertedDict)
        case is NSNull:
            return .null
        default:
            // Type not supported
            return nil
        }
    }

    /// Convert to a Foundation object
    /// - Returns: A Foundation object representation
    func toFoundationObject() -> Any? {
        switch self {
        case .string(let value):
            return value
        case .integer(let value):
            return value
        case .double(let value):
            return value
        case .boolean(let value):
            return value
        case .data(let value):
            return Data(value)
        case .url(let value):
            return URL(string: value)
        case .date(let value):
            return Date(timeIntervalSince1970: value)
        case .stringArray(let value):
            return value
        case .dictionary(let value):
            // Convert dictionary values recursively
            var convertedDict: [String: Any] = [:]
            for (key, dictValue) in value {
                if let converted = dictValue.toFoundationObject() {
                    convertedDict[key] = converted
                }
            }
            return convertedDict
        case .array(let value):
            // Convert array elements recursively
            var convertedArray: [Any] = []
            for item in value {
                if let converted = item.toFoundationObject() {
                    convertedArray.append(converted)
                }
            }
            return convertedArray
        case .null:
            return nil
        }
    }
}
