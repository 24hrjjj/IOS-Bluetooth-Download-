import SwiftUI
import Charts

struct DataVisualizationView: View {
    @EnvironmentObject var dataStorageManager: DataStorageManager
    
    @State private var selectedDataSetIndex = 0
    @State private var showDeleteAlert = false
    
    var body: some View {
        NavigationView {
            VStack {
                if dataStorageManager.deviceDataSets.isEmpty {
                    // Empty state view
                    emptyStateView()
                } else {
                    // Data set selector
                    dataSetPicker()
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            // Current data set info card
                            if let currentData = currentDataSet {
                                dataInfoCard(currentData)
                                
                                // Data visualizations
                                dataVisualizationCards(currentData)
                            }
                        }
                        .padding()
                    }
                    
                    // Action buttons
                    HStack {
                        Button(action: {
                            showDeleteAlert = true
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete Data")
                            }
                            .padding()
                            .foregroundColor(.white)
                            .background(Color.red)
                            .cornerRadius(10)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Data Visualization")
            .alert(isPresented: $showDeleteAlert) {
                Alert(
                    title: Text("Delete Data"),
                    message: Text("Are you sure you want to delete this data set? This action cannot be undone."),
                    primaryButton: .destructive(Text("Delete")) {
                        deleteCurrentDataSet()
                    },
                    secondaryButton: .cancel()
                )
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
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Data Available")
                .font(.title2)
            
            Text("Connect to a device and download data to visualize it here.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // Data set picker
    private func dataSetPicker() -> some View {
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
    }
    
    // Data info card
    private func dataInfoCard(_ data: DeviceData) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Device Information")
                    .font(.headline)
                Spacer()
                Text(formatDate(data.timestamp))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Divider()
            
            HStack {
                Label("Device", systemImage: "display")
                Spacer()
                Text(data.deviceName)
            }
            
            HStack {
                Label("ID", systemImage: "number")
                Spacer()
                Text(data.deviceID)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            if let deviceInfo = data.data["device_info"] as? [String: Any] {
                if let firmware = deviceInfo["firmware"] as? String {
                    HStack {
                        Label("Firmware", systemImage: "memorychip")
                        Spacer()
                        Text(firmware)
                    }
                }
                
                if let battery = deviceInfo["battery"] as? Int {
                    HStack {
                        Label("Battery", systemImage: "battery.100")
                        Spacer()
                        Text("\(battery)%")
                            .foregroundColor(batteryColor(level: battery))
                    }
                }
                
                if let calibration = deviceInfo["lastCalibration"] as? TimeInterval {
                    HStack {
                        Label("Last Calibration", systemImage: "calendar")
                        Spacer()
                        Text(formatDate(Date(timeIntervalSince1970: calibration)))
                            .font(.caption)
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    // Data visualization cards
    private func dataVisualizationCards(_ data: DeviceData) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Measurements")
                .font(.headline)
            
            if let readings = data.data["readings"] as? [[String: Any]], !readings.isEmpty {
                // Line chart for value1 (e.g., temperature)
                ChartCard(
                    title: "Temperature",
                    data: readings,
                    valueKey: "value1",
                    unit: "°C",
                    color: .red
                )
                
                // Line chart for value2 (e.g., humidity)
                ChartCard(
                    title: "Humidity",
                    data: readings,
                    valueKey: "value2",
                    unit: "%",
                    color: .blue
                )
                
                // Line chart for value3 (e.g., pressure)
                ChartCard(
                    title: "Pressure",
                    data: readings,
                    valueKey: "value3",
                    unit: "hPa",
                    color: .green
                )
                
                // Raw data table
                rawDataTable(readings)
            } else {
                Text("No readings found in this data set")
                    .foregroundColor(.gray)
                    .padding()
            }
        }
    }
    
    // Raw data table
    private func rawDataTable(_ readings: [[String: Any]]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Raw Data")
                .font(.headline)
            
            ScrollView(.horizontal) {
                VStack(alignment: .leading, spacing: 4) {
                    // Header row
                    HStack {
                        Text("Time")
                            .fontWeight(.bold)
                            .frame(width: 150, alignment: .leading)
                        Text("Value 1")
                            .fontWeight(.bold)
                            .frame(width: 80, alignment: .trailing)
                        Text("Value 2")
                            .fontWeight(.bold)
                            .frame(width: 80, alignment: .trailing)
                        Text("Value 3")
                            .fontWeight(.bold)
                            .frame(width: 80, alignment: .trailing)
                    }
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.2))
                    
                    // Data rows
                    ForEach(readings.indices, id: \.self) { index in
                        HStack {
                            if let timestamp = readings[index]["timestamp"] as? TimeInterval {
                                Text(formatTime(Date(timeIntervalSince1970: timestamp)))
                                    .frame(width: 150, alignment: .leading)
                            } else {
                                Text("Unknown")
                                    .frame(width: 150, alignment: .leading)
                            }
                            
                            if let value1 = readings[index]["value1"] as? Double {
                                Text(String(format: "%.1f", value1))
                                    .frame(width: 80, alignment: .trailing)
                            } else {
                                Text("--")
                                    .frame(width: 80, alignment: .trailing)
                            }
                            
                            if let value2 = readings[index]["value2"] as? Double {
                                Text(String(format: "%.1f", value2))
                                    .frame(width: 80, alignment: .trailing)
                            } else {
                                Text("--")
                                    .frame(width: 80, alignment: .trailing)
                            }
                            
                            if let value3 = readings[index]["value3"] as? Int {
                                Text("\(value3)")
                                    .frame(width: 80, alignment: .trailing)
                            } else {
                                Text("--")
                                    .frame(width: 80, alignment: .trailing)
                            }
                        }
                        .padding(.vertical, 4)
                        .background(index % 2 == 0 ? Color.clear : Color.gray.opacity(0.05))
                    }
                }
                .padding()
            }
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    // Delete current data set
    private func deleteCurrentDataSet() {
        if !dataStorageManager.deviceDataSets.isEmpty && selectedDataSetIndex < dataStorageManager.deviceDataSets.count {
            dataStorageManager.removeDeviceData(at: selectedDataSetIndex)
            
            // Adjust selected index if needed
            if selectedDataSetIndex >= dataStorageManager.deviceDataSets.count {
                selectedDataSetIndex = max(0, dataStorageManager.deviceDataSets.count - 1)
            }
        }
    }
    
    // Helper function to format date
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // Helper function to format time only
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
    
    // Helper function to determine battery color
    private func batteryColor(level: Int) -> Color {
        if level > 50 {
            return .green
        } else if level > 20 {
            return .orange
        } else {
            return .red
        }
    }
}

// Chart Card View
struct ChartCard: View {
    let title: String
    let data: [[String: Any]]
    let valueKey: String
    let unit: String
    let color: Color
    
    @State private var showFullScreen = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            // Create a data structure for the chart
            let chartData = createChartData()
            
            if !chartData.isEmpty {
                Chart {
                    ForEach(chartData, id: \.timestamp) { dataPoint in
                        LineMark(
                            x: .value("Time", dataPoint.timestamp),
                            y: .value(title, dataPoint.value)
                        )
                        .foregroundStyle(color)
                    }
                    
                    // Overlay symbols at each data point
                    ForEach(chartData, id: \.timestamp) { dataPoint in
                        PointMark(
                            x: .value("Time", dataPoint.timestamp),
                            y: .value(title, dataPoint.value)
                        )
                        .foregroundStyle(color)
                    }
                }
                .frame(height: 200)
                .chartYScale(domain: chartYDomain.0...chartYDomain.1)
                .chartXAxis {
                    AxisMarks(position: .bottom) { value in
                        if let date = value.as(Date.self) {
                            let formatter = DateFormatter()
                            formatter.dateFormat = "HH:mm"
                            AxisValueLabel {
                                Text(formatter.string(from: date))
                                    .font(.caption)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let doubleValue = value.as(Double.self) {
                                Text("\(Int(doubleValue))")
                                    .font(.caption)
                            }
                        }
                    }
                }
                .onTapGesture {
                    showFullScreen = true
                }
                
                // Stat summary
                HStack {
                    Spacer()
                    StatView(title: "Min", value: String(format: "%.1f", chartMin), unit: unit)
                    Spacer()
                    StatView(title: "Avg", value: String(format: "%.1f", chartAvg), unit: unit)
                    Spacer()
                    StatView(title: "Max", value: String(format: "%.1f", chartMax), unit: unit)
                    Spacer()
                }
                .padding(.top, 8)
            } else {
                Text("No data available")
                    .foregroundColor(.gray)
                    .padding()
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .sheet(isPresented: $showFullScreen) {
            fullScreenChart()
        }
    }
    
    // A simple data structure for chart data
    struct ChartDataPoint {
        let timestamp: Date
        let value: Double
    }
    
    // Convert the raw data into chart data
    private func createChartData() -> [ChartDataPoint] {
        var result: [ChartDataPoint] = []
        
        for item in data {
            if let timestamp = item["timestamp"] as? TimeInterval,
               let value = item[valueKey] as? Double {
                result.append(
                    ChartDataPoint(
                        timestamp: Date(timeIntervalSince1970: timestamp),
                        value: value
                    )
                )
            } else if let value = item[valueKey] as? Int { // Handle integer values too
                if let timestamp = item["timestamp"] as? TimeInterval {
                    result.append(
                        ChartDataPoint(
                            timestamp: Date(timeIntervalSince1970: timestamp),
                            value: Double(value)
                        )
                    )
                }
            }
        }
        
        // Sort by timestamp ascending
        return result.sorted(by: { $0.timestamp < $1.timestamp })
    }
    
    // Compute min value
    private var chartMin: Double {
        let chartData = createChartData()
        return chartData.min(by: { $0.value < $1.value })?.value ?? 0
    }
    
    // Compute max value
    private var chartMax: Double {
        let chartData = createChartData()
        return chartData.max(by: { $0.value < $1.value })?.value ?? 0
    }
    
    // Compute average value
    private var chartAvg: Double {
        let chartData = createChartData()
        let sum = chartData.reduce(0) { $0 + $1.value }
        return chartData.isEmpty ? 0 : sum / Double(chartData.count)
    }
    
    // Compute Y axis domain with some padding
    private var chartYDomain: (Double, Double) {
        let min = chartMin
        let max = chartMax
        
        // Add some padding to the domain
        let padding = (max - min) * 0.1
        return (min - padding, max + padding)
    }
    
    // Full screen chart view
    private func fullScreenChart() -> some View {
        VStack {
            HStack {
                Text(title)
                    .font(.title)
                Spacer()
                Button("Close") {
                    showFullScreen = false
                }
            }
            .padding()
            
            let chartData = createChartData()
            
            if !chartData.isEmpty {
                Chart {
                    ForEach(chartData, id: \.timestamp) { dataPoint in
                        LineMark(
                            x: .value("Time", dataPoint.timestamp),
                            y: .value(title, dataPoint.value)
                        )
                        .foregroundStyle(color)
                        .interpolationMethod(.catmullRom)
                    }
                    
                    ForEach(chartData, id: \.timestamp) { dataPoint in
                        PointMark(
                            x: .value("Time", dataPoint.timestamp),
                            y: .value(title, dataPoint.value)
                        )
                        .foregroundStyle(color)
                    }
                }
                .frame(height: 400)
                .padding()
                
                // Data table
                List {
                    ForEach(chartData.indices, id: \.self) { index in
                        let point = chartData[index]
                        HStack {
                            Text(formatTime(point.timestamp))
                            Spacer()
                            Text("\(String(format: "%.2f", point.value)) \(unit)")
                        }
                    }
                }
            }
        }
    }
    
    // Helper to format time
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
}

// Stat view for min/avg/max
struct StatView: View {
    let title: String
    let value: String
    let unit: String
    
    var body: some View {
        VStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            
            Text("\(value) \(unit)")
                .font(.headline)
        }
    }
}

struct DataVisualizationView_Previews: PreviewProvider {
    static var previews: some View {
        DataVisualizationView()
            .environmentObject(DataStorageManager())
    }
}
