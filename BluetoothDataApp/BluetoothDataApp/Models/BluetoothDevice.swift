import Foundation
import CoreBluetooth

/// A model representing a Bluetooth device that can be discovered, connected to, and interacted with
struct BluetoothDevice: Identifiable {
    /// Unique identifier for the device
    let id = UUID()
    
    /// The peripheral identifier from CoreBluetooth
    let identifier: UUID
    
    /// The human-readable name of the device (can be nil)
    let name: String?
    
    /// The signal strength (RSSI) value in dBm
    var rssi: Int?
    
    /// Advertising data from the device
    var advertisementData: [String: Any]
    
    /// The peripheral object from CoreBluetooth
    var peripheral: CBPeripheral
    
    /// Creates a new BluetoothDevice from a discovered peripheral
    /// - Parameters:
    ///   - peripheral: The CoreBluetooth peripheral
    ///   - advertisementData: The advertisement data dictionary
    ///   - rssi: The signal strength value
    init(peripheral: CBPeripheral, advertisementData: [String: Any], rssi: Int) {
        self.peripheral = peripheral
        self.identifier = peripheral.identifier
        self.name = peripheral.name
        self.rssi = rssi
        self.advertisementData = advertisementData
    }
}

// MARK: - Equatable conformance
extension BluetoothDevice: Equatable {
    static func == (lhs: BluetoothDevice, rhs: BluetoothDevice) -> Bool {
        return lhs.identifier == rhs.identifier
    }
}
