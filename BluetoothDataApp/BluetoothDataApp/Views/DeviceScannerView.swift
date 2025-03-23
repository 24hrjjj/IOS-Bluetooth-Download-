import SwiftUI
import CoreBluetooth

struct DeviceScannerView: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager
    
    // Local state for UI control
    @State private var isScanning = false
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            VStack {
                // Header section with scan button
                HStack {
                    Text("Available Devices")
                        .font(.headline)
                    Spacer()
                    Button(action: {
                        toggleScan()
                    }) {
                        HStack {
                            Image(systemName: isScanning ? "stop.circle" : "play.circle")
                            Text(isScanning ? "Stop" : "Scan")
                        }
                        .padding(8)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
                .padding()
                
                // Status indicator
                if bluetoothManager.state != .poweredOn {
                    StatusView(state: bluetoothManager.state)
                }
                
                // Devices list
                if bluetoothManager.discoveredDevices.isEmpty {
                    EmptyStateView(isScanning: isScanning)
                } else {
                    List {
                        ForEach(bluetoothManager.discoveredDevices) { device in
                            DeviceRow(device: device)
                                .onTapGesture {
                                    connectToDevice(device)
                                }
                        }
                    }
                    .refreshable {
                        // Pull to refresh resets and starts a new scan
                        bluetoothManager.stopScan()
                        bluetoothManager.clearDiscoveredDevices()
                        bluetoothManager.startScan()
                        isScanning = true
                    }
                }
            }
            .navigationTitle("Device Scanner")
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text(alertTitle),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onChange(of: bluetoothManager.state) { _, newState in
                handleStateChange(newState)
            }
            .onChange(of: bluetoothManager.error) { _, newError in
                if let error = newError {
                    alertTitle = "Error"
                    alertMessage = error.localizedDescription
                    showAlert = true
                }
            }
            .onAppear {
                if bluetoothManager.state == .poweredOn && !isScanning {
                    bluetoothManager.startScan()
                    isScanning = true
                }
            }
            .onDisappear {
                if isScanning {
                    bluetoothManager.stopScan()
                    isScanning = false
                }
            }
        }
    }
    
    // Toggle scanning on/off
    private func toggleScan() {
        if isScanning {
            bluetoothManager.stopScan()
        } else {
            bluetoothManager.clearDiscoveredDevices()
            bluetoothManager.startScan()
        }
        isScanning.toggle()
    }
    
    // Handle connection to a device
    private func connectToDevice(_ device: BluetoothDevice) {
        if isScanning {
            bluetoothManager.stopScan()
            isScanning = false
        }
        
        bluetoothManager.connect(device: device) { success, error in
            if !success {
                alertTitle = "Connection Failed"
                alertMessage = error?.localizedDescription ?? "Could not connect to the device."
                showAlert = true
            }
        }
    }
    
    // Handle Bluetooth state changes
    private func handleStateChange(_ state: CBManagerState) {
        switch state {
        case .poweredOn:
            if !isScanning {
                bluetoothManager.startScan()
                isScanning = true
            }
        case .poweredOff:
            isScanning = false
            alertTitle = "Bluetooth is Off"
            alertMessage = "Please turn on Bluetooth to use this app."
            showAlert = true
        case .unauthorized:
            isScanning = false
            alertTitle = "Bluetooth Permission"
            alertMessage = "Please allow Bluetooth permission in Settings."
            showAlert = true
        case .unsupported:
            isScanning = false
            alertTitle = "Unsupported"
            alertMessage = "Bluetooth is not supported on this device."
            showAlert = true
        default:
            isScanning = false
        }
    }
}

// Status view displays Bluetooth state
struct StatusView: View {
    let state: CBManagerState
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            Text(stateMessage)
                .font(.footnote)
        }
        .padding()
        .background(Color.yellow.opacity(0.2))
        .cornerRadius(8)
        .padding(.horizontal)
    }
    
    var stateMessage: String {
        switch state {
        case .poweredOff:
            return "Bluetooth is turned off. Please enable Bluetooth."
        case .unauthorized:
            return "Bluetooth permission is required. Please check settings."
        case .unsupported:
            return "Bluetooth is not supported on this device."
        case .resetting:
            return "Bluetooth is resetting. Please wait..."
        case .unknown:
            return "Bluetooth state is unknown."
        default:
            return "Bluetooth is not ready."
        }
    }
}

// Empty state view when no devices are found
struct EmptyStateView: View {
    let isScanning: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: isScanning ? "antenna.radiowaves.left.and.right" : "bluetooth")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text(isScanning ? "Scanning for devices..." : "No devices found")
                .font(.headline)
            
            if isScanning {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            } else {
                Text("Press 'Scan' to start looking for devices")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gray.opacity(0.1))
    }
}

// Individual device row in the list
struct DeviceRow: View {
    let device: BluetoothDevice
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(device.name ?? "Unnamed Device")
                    .font(.headline)
                Text(device.identifier.uuidString)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .contentShape(Rectangle())
    }
}

struct DeviceScannerView_Previews: PreviewProvider {
    static var previews: some View {
        DeviceScannerView()
            .environmentObject(BluetoothManager())
    }
}
