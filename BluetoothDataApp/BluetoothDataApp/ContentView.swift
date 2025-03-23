import SwiftUI

struct ContentView: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @EnvironmentObject var dataStorageManager: DataStorageManager
    
    // State to track which tab is selected
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Device Scanner tab
            DeviceScannerView()
                .tabItem {
                    Label("Scan", systemImage: "antenna.radiowaves.left.and.right")
                }
                .tag(0)
            
            // Device Details tab (only enabled when a device is connected)
            DeviceDetailsView()
                .tabItem {
                    Label("Device", systemImage: "display")
                }
                .tag(1)
                .disabled(bluetoothManager.connectedDevice == nil)
            
            // Data Visualization tab
            DataVisualizationView()
                .tabItem {
                    Label("Data", systemImage: "chart.bar")
                }
                .tag(2)
                .disabled(dataStorageManager.deviceDataSets.isEmpty)
            
            // Import/Export tab
            ExportImportView()
                .tabItem {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
                .tag(3)
                .disabled(dataStorageManager.deviceDataSets.isEmpty)
        }
        .onChange(of: bluetoothManager.connectedDevice) { _, newValue in
            // If device disconnected and we're on the device tab, switch to scan tab
            if newValue == nil && selectedTab == 1 {
                selectedTab = 0
            }
        }
        .onChange(of: dataStorageManager.deviceDataSets.isEmpty) { _, isEmpty in
            // If data becomes empty and we're on data or share tab, switch to scan tab
            if isEmpty && (selectedTab == 2 || selectedTab == 3) {
                selectedTab = 0
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(BluetoothManager())
            .environmentObject(DataStorageManager())
    }
}
