import SwiftUI

@main
struct BluetoothDataAppApp: App {
    // Create instances of our managers as environment objects so they can be accessed throughout the app
    @StateObject private var bluetoothManager = BluetoothManager()
    @StateObject private var dataStorageManager = DataStorageManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(bluetoothManager)
                .environmentObject(dataStorageManager)
        }
    }
}
