import SwiftUI
import CoreBluetooth

struct DeviceDetailsView: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @EnvironmentObject var dataStorageManager: DataStorageManager
    
    @State private var isDownloading = false
    @State private var downloadProgress: Double = 0
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                // Main content
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        if let device = bluetoothManager.connectedDevice {
                            // Device information card
                            deviceInfoCard(device)
                            
                            // Services and characteristics section
                            characteristicsSection()
                            
                            // Download button
                            downloadButton()
                        } else {
                            // No device connected state
                            noDeviceConnectedView()
                        }
                    }
                    .padding()
                }
                
                // Overlay progress view when downloading
                if isDownloading {
                    downloadingOverlay()
                }
            }
            .navigationTitle("Device Details")
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text(alertTitle),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // Device Information Card
    private func deviceInfoCard(_ device: BluetoothDevice) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(device.name ?? "Unnamed Device")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: {
                    bluetoothManager.disconnect()
                }) {
                    Text("Disconnect")
                        .foregroundColor(.red)
                }
            }
            
            Divider()
            
            HStack {
                Label("UUID", systemImage: "number")
                Spacer()
                Text(device.identifier.uuidString)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            HStack {
                Label("Connection", systemImage: "antenna.radiowaves.left.and.right")
                Spacer()
                Text("Connected")
                    .foregroundColor(.green)
            }
            
            if let rssi = device.rssi {
                HStack {
                    Label("Signal Strength", systemImage: "wifi")
                    Spacer()
                    Text("\(rssi) dBm")
                        .foregroundColor(signalColor(for: rssi))
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    // Services and characteristics section
    private func characteristicsSection() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Available Services")
                .font(.headline)
            
            if let services = bluetoothManager.discoveredServices, !services.isEmpty {
                ForEach(services, id: \.uuid) { service in
                    serviceRow(service)
                }
            } else {
                Text("Discovering services...")
                    .foregroundColor(.gray)
                    .padding()
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    // Individual service row
    private func serviceRow(_ service: CBService) -> some View {
        VStack(alignment: .leading) {
            Text("Service: \(service.uuid.uuidString)")
                .font(.subheadline)
                .padding(.vertical, 5)
            
            if let characteristics = service.characteristics, !characteristics.isEmpty {
                ForEach(characteristics, id: \.uuid) { characteristic in
                    characteristicRow(characteristic)
                }
            } else {
                Text("No characteristics found")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.leading)
            }
            
            Divider()
        }
    }
    
    // Individual characteristic row
    private func characteristicRow(_ characteristic: CBCharacteristic) -> some View {
        VStack(alignment: .leading) {
            Text("Characteristic: \(characteristic.uuid.uuidString)")
                .font(.caption)
                .padding(.leading)
            
            HStack {
                Text("Properties:")
                    .font(.caption)
                
                if characteristic.properties.contains(.read) {
                    Text("Read")
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(4)
                }
                
                if characteristic.properties.contains(.write) {
                    Text("Write")
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(4)
                }
                
                if characteristic.properties.contains(.notify) {
                    Text("Notify")
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.orange.opacity(0.2))
                        .cornerRadius(4)
                }
            }
            .padding(.leading)
        }
    }
    
    // Download button
    private func downloadButton() -> some View {
        Button(action: {
            downloadData()
        }) {
            HStack {
                Image(systemName: "arrow.down.doc")
                Text("Download Data")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .disabled(bluetoothManager.discoveredServices?.isEmpty ?? true || isDownloading)
    }
    
    // No device connected view
    private func noDeviceConnectedView() -> some View {
        VStack(spacing: 20) {
            Image(systemName: "antenna.radiowaves.left.and.right.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Device Connected")
                .font(.title2)
            
            Text("Go to the Scanner tab to connect to a device")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    // Downloading overlay
    private func downloadingOverlay() -> some View {
        ZStack {
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                Text("Downloading Data...")
                    .font(.headline)
                    .foregroundColor(.white)
                
                ProgressView(value: downloadProgress, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle())
                    .frame(width: 200)
                
                Text("\(Int(downloadProgress * 100))%")
                    .foregroundColor(.white)
                
                Button(action: {
                    cancelDownload()
                }) {
                    Text("Cancel")
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
                .padding(.top)
            }
            .padding()
            .background(Color.gray.opacity(0.9))
            .cornerRadius(15)
        }
    }
    
    // Function to download data from the device
    private func downloadData() {
        guard let device = bluetoothManager.connectedDevice else { return }
        
        isDownloading = true
        downloadProgress = 0.0
        
        // Simulate a download with increasing progress
        let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
        
        var subscription: Cancellable? = nil
        subscription = timer.sink { _ in
            if downloadProgress < 1.0 {
                downloadProgress += 0.1
                
                // Update UI to show progress
                if downloadProgress >= 1.0 {
                    // Download complete
                    downloadProgress = 1.0
                    isDownloading = false
                    
                    // Create a new DeviceData entry with the downloaded data
                    let deviceData = DeviceData(
                        deviceName: device.name ?? "Unknown Device",
                        deviceID: device.identifier.uuidString,
                        timestamp: Date(),
                        data: generateSampleData()
                    )
                    
                    // Save the data
                    dataStorageManager.addDeviceData(deviceData)
                    
                    // Show success alert
                    alertTitle = "Download Complete"
                    alertMessage = "Data has been successfully downloaded from the device."
                    showAlert = true
                    
                    // Cancel the timer
                    subscription?.cancel()
                }
            }
        }
    }
    
    // Function to cancel the download
    private func cancelDownload() {
        isDownloading = false
        alertTitle = "Download Cancelled"
        alertMessage = "The data download has been cancelled."
        showAlert = true
    }
    
    // Helper function to generate color for signal strength
    private func signalColor(for rssi: Int) -> Color {
        if rssi > -60 {
            return .green
        } else if rssi > -80 {
            return .orange
        } else {
            return .red
        }
    }
    
    // Helper function to generate sample data (in a real app, this would be actual data from the device)
    private func generateSampleData() -> [String: Any] {
        // Generate some random data to simulate device readings
        let readings = (0..<20).map { i -> [String: Any] in
            let timestamp = Date().addingTimeInterval(Double(-i * 60)) // 1 minute intervals going backward
            return [
                "timestamp": timestamp.timeIntervalSince1970,
                "value1": Double.random(in: 20...35), // e.g., temperature
                "value2": Double.random(in: 40...100), // e.g., humidity
                "value3": Int.random(in: 900...1100) // e.g., pressure
            ]
        }
        
        return [
            "device_info": [
                "firmware": "v1.2.3",
                "battery": Int.random(in: 20...100),
                "lastCalibration": Date().addingTimeInterval(-86400 * Double.random(in: 1...30)).timeIntervalSince1970
            ],
            "readings": readings
        ]
    }
}

struct DeviceDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        DeviceDetailsView()
            .environmentObject(BluetoothManager())
            .environmentObject(DataStorageManager())
    }
}
