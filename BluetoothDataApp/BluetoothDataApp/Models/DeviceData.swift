import Foundation

/// A model representing data retrieved from a Bluetooth device
struct DeviceData: Identifiable, Codable {
    /// Unique identifier for this data set
    let id: UUID
    
    /// Name of the device that provided this data
    let deviceName: String
    
    /// Device identifier
    let deviceID: String
    
    /// When the data was retrieved
    let timestamp: Date
    
    /// The actual data from the device, stored as a dictionary
    let data: [String: Any]
    
    /// Creates a new DeviceData instance
    /// - Parameters:
    ///   - deviceName: The name of the device that provided the data
    ///   - deviceID: The identifier of the device
    ///   - timestamp: When the data was retrieved
    ///   - data: The actual data from the device
    init(deviceName: String, deviceID: String, timestamp: Date, data: [String: Any]) {
        self.id = UUID()
        self.deviceName = deviceName
        self.deviceID = deviceID
        self.timestamp = timestamp
        self.data = data
    }
}

// MARK: - Codable conformance for DeviceData
// This extension helps us encode/decode the data dictionary which isn't natively Codable
extension DeviceData {
    enum CodingKeys: String, CodingKey {
        case id, deviceName, deviceID, timestamp, data
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        deviceName = try container.decode(String.self, forKey: .deviceName)
        deviceID = try container.decode(String.self, forKey: .deviceID)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        
        // Decode the data dictionary from a nested JSON structure
        let dataString = try container.decode(String.self, forKey: .data)
        guard let jsonData = dataString.data(using: .utf8),
              let jsonObject = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: [CodingKeys.data],
                    debugDescription: "Could not decode data dictionary"
                )
            )
        }
        data = jsonObject
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(deviceName, forKey: .deviceName)
        try container.encode(deviceID, forKey: .deviceID)
        try container.encode(timestamp, forKey: .timestamp)
        
        // Encode the data dictionary into a JSON string
        let jsonData = try JSONSerialization.data(withJSONObject: data)
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            try container.encode(jsonString, forKey: .data)
        } else {
            throw EncodingError.invalidValue(
                data,
                EncodingError.Context(
                    codingPath: [CodingKeys.data],
                    debugDescription: "Could not encode data dictionary"
                )
            )
        }
    }
}
