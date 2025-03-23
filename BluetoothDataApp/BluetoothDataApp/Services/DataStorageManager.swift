import Foundation
import Combine

/// A class that manages storage and retrieval of device data
class DataStorageManager: ObservableObject {
    // MARK: - Published Properties
    
    /// The collection of device data sets that have been downloaded
    @Published var deviceDataSets: [DeviceData] = []
    
    // MARK: - Private Properties
    
    /// The file URL where data is persisted
    private let dataStoreURL: URL
    
    // MARK: - Initialization
    
    init() {
        // Get the documents directory
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        // Create a file URL for our data store
        dataStoreURL = documentsDirectory.appendingPathComponent("deviceData.json")
        
        // Load any existing data
        loadData()
    }
    
    // MARK: - Public Methods
    
    /// Adds a new device data set to the collection
    /// - Parameter data: The device data to add
    func addDeviceData(_ data: DeviceData) {
        // Add to the collection
        deviceDataSets.append(data)
        
        // Sort by timestamp, newest first
        deviceDataSets.sort { $0.timestamp > $1.timestamp }
        
        // Save changes
        saveData()
    }
    
    /// Removes a device data set at the specified index
    /// - Parameter index: The index of the data set to remove
    func removeDeviceData(at index: Int) {
        guard index >= 0 && index < deviceDataSets.count else { return }
        
        // Remove from the collection
        deviceDataSets.remove(at: index)
        
        // Save changes
        saveData()
    }
    
    /// Clears all device data sets
    func clearAllData() {
        // Remove all data
        deviceDataSets.removeAll()
        
        // Save changes
        saveData()
    }
    
    // MARK: - Private Methods
    
    /// Loads device data from persistent storage
    private func loadData() {
        do {
            // Check if the file exists
            guard FileManager.default.fileExists(atPath: dataStoreURL.path) else {
                // No file yet, that's fine for first run
                return
            }
            
            // Read the file data
            let data = try Data(contentsOf: dataStoreURL)
            
            // Decode the JSON data into our model
            let decoder = JSONDecoder()
            deviceDataSets = try decoder.decode([DeviceData].self, from: data)
            
            // Sort by timestamp, newest first
            deviceDataSets.sort { $0.timestamp > $1.timestamp }
        } catch {
            print("Error loading data: \(error.localizedDescription)")
            // Could show an alert to the user here
        }
    }
    
    /// Saves device data to persistent storage
    private func saveData() {
        do {
            // Encode the data as JSON
            let encoder = JSONEncoder()
            let data = try encoder.encode(deviceDataSets)
            
            // Write to the file
            try data.write(to: dataStoreURL)
        } catch {
            print("Error saving data: \(error.localizedDescription)")
            // Could show an alert to the user here
        }
    }
}
