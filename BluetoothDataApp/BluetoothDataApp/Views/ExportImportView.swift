import SwiftUI
import UniformTypeIdentifiers

struct ExportImportView: View {
    @EnvironmentObject var dataStorageManager: DataStorageManager
    
    @State private var selectedDataSetIndex = 0
    @State private var isExporting = false
    @State private var isImporting = false
    @State private var showImportOptions = false
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var importedData: DeviceData?
    
    var body: some View {
        NavigationView {
            VStack {
                if dataStorageManager.deviceDataSets.isEmpty {
                    // Empty state view
                    emptyStateView()
                } else {
                    // Export view
                    VStack(spacing: 20) {
                        Text("Share Data Between Devices")
                            .font(.headline)
                            .padding(.top)
                        
                        // Data set picker for export
                        dataSetPickerSection()
                        
                        // Data preview
                        dataPreviewSection()
                        
                        // Export button
                        exportButtonSection()
                    }
                    .padding()
                }
                
                Spacer()
                
                // Import button - always visible
                importButtonSection()
            }
            .navigationTitle("Export & Import")
            .sheet(isPresented: $isExporting) {
                if let currentData = currentDataSet {
                    exportSheet(data: currentData)
                }
            }
            .fileImporter(
                isPresented: $isImporting,
                allowedContentTypes: [UTType.json],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result)
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text(alertTitle),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .sheet(isPresented: $showImportOptions) {
                if let importedData = importedData {
                    importOptionsSheet(data: importedData)
                }
            }
        }
    }
    
    // Computed property to get current data set
    private var currentDataSet: DeviceData? {
        if dataStorageManager.deviceDataSets.isEmpty || selectedDataSetIndex >= dataStorageManager.deviceDataSets.count {
            return nil
        }
        return dataStorageManager.deviceDataSets[selectedDataSetIndex]
    }
    
    // Empty state view
    private func emptyStateView() -> some View {
        VStack(spacing: 20) {
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Data to Export")
                .font(.title2)
            
            Text("Connect to a device and download data before exporting.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // Data set picker section
    private func dataSetPickerSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Select Data to Export")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Picker("Select Data Set", selection: $selectedDataSetIndex) {
                ForEach(0..<dataStorageManager.deviceDataSets.count, id: \.self) { index in
                    let data = dataStorageManager.deviceDataSets[index]
                    Text("\(data.deviceName) (\(formatDate(data.timestamp)))")
                        .tag(index)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    // Data preview section
    private func dataPreviewSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Data Preview")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            if let currentData = currentDataSet {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Device:")
                            .fontWeight(.bold)
                        Text(currentData.deviceName)
                    }
                    
                    HStack {
                        Text("Recorded:")
                            .fontWeight(.bold)
                        Text(formatDate(currentData.timestamp))
                    }
                    
                    HStack {
                        Text("Size:")
                            .fontWeight(.bold)
                        
                        // Estimate data size
                        if let jsonData = try? JSONSerialization.data(withJSONObject: currentData.data) {
                            Text("\(formatDataSize(jsonData.count))")
                        } else {
                            Text("Unknown")
                        }
                    }
                    
                    // Display reading count if available
                    if let readings = currentData.data["readings"] as? [[String: Any]] {
                        HStack {
                            Text("Readings:")
                                .fontWeight(.bold)
                            Text("\(readings.count)")
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
    
    // Export button section
    private func exportButtonSection() -> some View {
        Button(action: {
            isExporting = true
        }) {
            HStack {
                Image(systemName: "square.and.arrow.up")
                Text("Export Data")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .disabled(dataStorageManager.deviceDataSets.isEmpty)
    }
    
    // Import button section
    private func importButtonSection() -> some View {
        Button(action: {
            isImporting = true
        }) {
            HStack {
                Image(systemName: "square.and.arrow.down")
                Text("Import Data")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
    }
    
    // Export sheet
    private func exportSheet(data: DeviceData) -> some View {
        // Convert data to exportable JSON
        if let jsonData = try? JSONEncoder().encode(data),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return AnyView(
                VStack {
                    Text("Export Data")
                        .font(.headline)
                        .padding()
                    
                    Text("Share this file with another device running this app")
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    // ShareLink is a SwiftUI view that provides a standard share sheet
                    ShareLink(
                        item: jsonString,
                        preview: SharePreview(
                            "Device Data: \(data.deviceName)",
                            image: Image(systemName: "antenna.radiowaves.left.and.right")
                        )
                    ) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share")
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .padding()
                    
                    Button("Cancel") {
                        isExporting = false
                    }
                    .padding()
                }
                .padding()
            )
        } else {
            return AnyView(
                VStack {
                    Text("Error preparing data for export")
                        .foregroundColor(.red)
                    Button("Cancel") {
                        isExporting = false
                    }
                    .padding()
                }
                .padding()
            )
        }
    }
    
    // Import options sheet
    private func importOptionsSheet(data: DeviceData) -> some View {
        VStack(spacing: 20) {
            Text("Import Data")
                .font(.headline)
                .padding()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Data Details")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Device:")
                            .fontWeight(.bold)
                        Text(data.deviceName)
                    }
                    
                    HStack {
                        Text("Recorded:")
                            .fontWeight(.bold)
                        Text(formatDate(data.timestamp))
                    }
                    
                    // Display reading count if available
                    if let readings = data.data["readings"] as? [[String: Any]] {
                        HStack {
                            Text("Readings:")
                                .fontWeight(.bold)
                            Text("\(readings.count)")
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
            .padding(.horizontal)
            
            Text("Would you like to import this data?")
            
            HStack(spacing: 20) {
                Button(action: {
                    // Cancel import
                    showImportOptions = false
                }) {
                    Text("Cancel")
                        .frame(minWidth: 100)
                        .padding()
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                Button(action: {
                    // Confirm import
                    dataStorageManager.addDeviceData(data)
                    
                    // Show success message
                    alertTitle = "Import Successful"
                    alertMessage = "The data from \(data.deviceName) has been successfully imported."
                    showAlert = true
                    
                    // Close sheet
                    showImportOptions = false
                }) {
                    Text("Import")
                        .frame(minWidth: 100)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding()
        }
        .padding()
    }
    
    // Handle file import result
    private func handleFileImport(_ result: Result<[URL], Error>) {
        do {
            guard let selectedFile = try result.get().first else {
                throw ImportError.noFileSelected
            }
            
            // Start accessing the security-scoped resource
            if selectedFile.startAccessingSecurityScopedResource() {
                defer {
                    selectedFile.stopAccessingSecurityScopedResource()
                }
                
                let data = try Data(contentsOf: selectedFile)
                let decoder = JSONDecoder()
                let deviceData = try decoder.decode(DeviceData.self, from: data)
                
                // Store the imported data and show options
                importedData = deviceData
                showImportOptions = true
            } else {
                throw ImportError.accessDenied
            }
        } catch let decodingError as DecodingError {
            alertTitle = "Import Error"
            alertMessage = "The file is not in the correct format: \(decodingError.localizedDescription)"
            showAlert = true
        } catch {
            alertTitle = "Import Error"
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }
    
    // Helper function to format date
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // Helper function to format data size
    private func formatDataSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
    
    // Custom import errors
    enum ImportError: Error, LocalizedError {
        case noFileSelected
        case accessDenied
        
        var errorDescription: String? {
            switch self {
            case .noFileSelected:
                return "No file was selected"
            case .accessDenied:
                return "Could not access the selected file"
            }
        }
    }
}

struct ExportImportView_Previews: PreviewProvider {
    static var previews: some View {
        ExportImportView()
            .environmentObject(DataStorageManager())
    }
}
