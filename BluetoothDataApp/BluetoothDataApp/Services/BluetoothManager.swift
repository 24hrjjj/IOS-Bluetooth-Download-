import Foundation
import CoreBluetooth
import Combine

/// A class that manages all Bluetooth Low Energy (BLE) functionality
class BluetoothManager: NSObject, ObservableObject {
    // MARK: - Published Properties
    
    /// The current state of the Bluetooth manager/adapter
    @Published var state: CBManagerState = .unknown
    
    /// The list of discovered devices during scanning
    @Published var discoveredDevices: [BluetoothDevice] = []
    
    /// The currently connected device, if any
    @Published var connectedDevice: BluetoothDevice?
    
    /// The most recent error that occurred during Bluetooth operations
    @Published var error: Error?
    
    /// Services discovered for the connected device
    @Published var discoveredServices: [CBService]?
    
    // MARK: - Private Properties
    
    /// The central manager that handles BLE scanning and connections
    private var centralManager: CBCentralManager!
    
    /// Whether a scan is currently in progress
    private var isScanning = false
    
    /// Completion handler for the current connection attempt
    private var connectionHandler: ((Bool, Error?) -> Void)?
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // MARK: - Public Methods
    
    /// Starts scanning for BLE devices
    func startScan() {
        guard state == .poweredOn else {
            error = BluetoothError.bluetoothNotReady
            return
        }
        
        if !isScanning {
            // Clear any previous errors
            error = nil
            
            // Start scanning for all available services
            centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
            isScanning = true
        }
    }
    
    /// Stops the current scan
    func stopScan() {
        if isScanning {
            centralManager.stopScan()
            isScanning = false
        }
    }
    
    /// Clears the list of discovered devices
    func clearDiscoveredDevices() {
        discoveredDevices.removeAll()
    }
    
    /// Connects to a specific device
    /// - Parameters:
    ///   - device: The device to connect to
    ///   - completion: A callback that will be invoked when the connection completes or fails
    func connect(device: BluetoothDevice, completion: @escaping (Bool, Error?) -> Void) {
        guard state == .poweredOn else {
            completion(false, BluetoothError.bluetoothNotReady)
            return
        }
        
        // Store the completion handler for later
        connectionHandler = completion
        
        // Clear any previous errors
        error = nil
        
        // Attempt to connect to the peripheral
        centralManager.connect(device.peripheral, options: nil)
    }
    
    /// Disconnects from the currently connected device
    func disconnect() {
        if let device = connectedDevice {
            centralManager.cancelPeripheralConnection(device.peripheral)
        }
    }
    
    // MARK: - Private Helper Methods
    
    /// Updates a device in the discovered devices list or adds it if not already present
    /// - Parameters:
    ///   - peripheral: The peripheral to update
    ///   - advertisementData: The advertisement data for the peripheral
    ///   - rssi: The signal strength for the peripheral
    private func updateDiscoveredDevice(peripheral: CBPeripheral, advertisementData: [String: Any], rssi: NSNumber) {
        // Create a device object from the discovered peripheral
        let device = BluetoothDevice(peripheral: peripheral, advertisementData: advertisementData, rssi: rssi.intValue)
        
        // Update the list of discovered devices
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Check if we already have this device in our list
            if let index = self.discoveredDevices.firstIndex(where: { $0.identifier == device.identifier }) {
                // Update existing device
                self.discoveredDevices[index] = device
            } else {
                // Add new device
                self.discoveredDevices.append(device)
            }
        }
    }
    
    /// Discovers the services and characteristics of a connected peripheral
    /// - Parameter peripheral: The peripheral to discover services for
    private func discoverServices(for peripheral: CBPeripheral) {
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }
}

// MARK: - CBCentralManagerDelegate

extension BluetoothManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.state = central.state
            
            // Handle state changes
            switch central.state {
            case .poweredOn:
                // Bluetooth is ready, we can scan or connect
                break
            case .poweredOff:
                // Bluetooth is turned off
                self.isScanning = false
                self.connectedDevice = nil
                self.discoveredDevices.removeAll()
                self.error = BluetoothError.bluetoothPoweredOff
            case .unauthorized:
                self.error = BluetoothError.bluetoothUnauthorized
            case .unsupported:
                self.error = BluetoothError.bluetoothUnsupported
            default:
                break
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        // Ignore devices with no name if desired
        // if peripheral.name == nil { return }
        
        // Update our list of discovered devices
        updateDiscoveredDevice(peripheral: peripheral, advertisementData: advertisementData, rssi: RSSI)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        // Look up the BluetoothDevice that corresponds to this peripheral
        guard let device = discoveredDevices.first(where: { $0.identifier == peripheral.identifier }) else {
            connectionHandler?(false, BluetoothError.deviceNotFound)
            connectionHandler = nil
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Update the connected device
            self.connectedDevice = device
            
            // Start discovering services
            self.discoverServices(for: peripheral)
            
            // Call the completion handler with success
            self.connectionHandler?(true, nil)
            self.connectionHandler = nil
        }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Update the error
            self.error = error ?? BluetoothError.connectionFailed
            
            // Call the completion handler with failure
            self.connectionHandler?(false, self.error)
            self.connectionHandler = nil
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Update state for disconnection
            if self.connectedDevice?.identifier == peripheral.identifier {
                self.connectedDevice = nil
                self.discoveredServices = nil
            }
            
            // If this was an unexpected disconnection, set the error
            if let error = error {
                self.error = error
            }
        }
    }
}

// MARK: - CBPeripheralDelegate

extension BluetoothManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            DispatchQueue.main.async { [weak self] in
                self?.error = error
            }
            return
        }
        
        guard let services = peripheral.services else { return }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Update discovered services
            self.discoveredServices = services
            
            // Discover characteristics for each service
            for service in services {
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            DispatchQueue.main.async { [weak self] in
                self?.error = error
            }
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Update the services list to refresh the UI with discovered characteristics
            if let index = self.discoveredServices?.firstIndex(where: { $0.uuid == service.uuid }) {
                self.discoveredServices?[index] = service
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            DispatchQueue.main.async { [weak self] in
                self?.error = error
            }
            return
        }
        
        // Handle characteristic value update
        // This could be used to process data received from notifications
        // or read operations
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            DispatchQueue.main.async { [weak self] in
                self?.error = error
            }
            return
        }
        
        // Handle write completion
        // This could be used to track when a write operation completes
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            DispatchQueue.main.async { [weak self] in
                self?.error = error
            }
            return
        }
        
        // Handle notification state update
        // This could be used to track when a notification is enabled/disabled
    }
}

// MARK: - BluetoothError

/// Custom error enum for Bluetooth-related errors
enum BluetoothError: Error, LocalizedError {
    case bluetoothNotReady
    case bluetoothPoweredOff
    case bluetoothUnauthorized
    case bluetoothUnsupported
    case deviceNotFound
    case connectionFailed
    case serviceNotFound
    case characteristicNotFound
    case operationFailed
    
    var errorDescription: String? {
        switch self {
        case .bluetoothNotReady:
            return "Bluetooth is not ready"
        case .bluetoothPoweredOff:
            return "Bluetooth is powered off"
        case .bluetoothUnauthorized:
            return "Bluetooth permission not granted"
        case .bluetoothUnsupported:
            return "Bluetooth is not supported on this device"
        case .deviceNotFound:
            return "Device not found"
        case .connectionFailed:
            return "Failed to connect to device"
        case .serviceNotFound:
            return "Required service not found on device"
        case .characteristicNotFound:
            return "Required characteristic not found on device"
        case .operationFailed:
            return "Operation failed"
        }
    }
}
