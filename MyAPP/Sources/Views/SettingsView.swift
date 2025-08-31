import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("deepseek_api_key") private var apiKey = ""
    @AppStorage("trends_region") private var trendsRegion = "US"
    @AppStorage("enable_us_holidays") private var enableUSHolidays = true
    @AppStorage("enable_cn_holidays") private var enableCNHolidays = true
    
    @State private var showingImportProgress = false
    @State private var importMessage = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var importYear = Calendar.current.component(.year, from: .now)
    @State private var cnICSURLString: String = UserDefaults.standard.string(forKey: "cnICSURL") ?? "https://www.officeholidays.com/ics/china"
    
    var body: some View {
        NavigationView {
            Form {
                Section("AI Settings") {
                    SecureField("DeepSeek API Key", text: $apiKey)
                        .onChange(of: apiKey) { _, newValue in
                            DeepSeekClient.shared.setAPIKey(newValue)
                        }
                    
                    Text("Add your DeepSeek API key to enable translation and summarization features.")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Section("Trends") {
                    Picker("Default Region", selection: $trendsRegion) {
                        Text("United States").tag("US")
                        Text("China").tag("CN")
                    }
                    
                    TextField("Trends Proxy Base", text: Binding(
                        get: { TrendsClient.base },
                        set: { TrendsClient.setBase($0) }
                    ))
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    
                    Text("Set your trends proxy URL (e.g., https://orbit-trends-proxy.vercel.app)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Section("Holidays") {
                    Toggle("US Holidays", isOn: $enableUSHolidays)
                    Toggle("Chinese Holidays", isOn: $enableCNHolidays)
                    
                    Button("Refresh Holidays") {
                        importHolidays()
                    }
                    .disabled(showingImportProgress)
                }
                
                Section("Calendars") {
                    Stepper("Year: \(importYear)", value: $importYear, in: 2020...2035)
                    Button("Import US Federal Holidays") {
                        Task {
                            await MainActor.run {
                                USFederalHolidays.importYear(importYear, into: context)
                                try? context.save()
                            }
                        }
                    }
                }
                
                Section("China Holidays") {
                    TextField("ICS URL", text: $cnICSURLString)
                        .textFieldStyle(.roundedBorder)
                    
                    Button("Import China Holidays") {
                        Task {
                            UserDefaults.standard.set(cnICSURLString, forKey: "cnICSURL")
                            let url = URL(string: cnICSURLString)
                            // Import a sensible range (you can widen anytime)
                            let thisYear = Calendar.current.component(.year, from: Date())
                            await ChinaHolidayImporter.importYears(thisYear...thisYear+3, context: context, icsURL: url)
                        }
                    }
                }
                

                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.gray)
                    }
                    
                    Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
                    Link("Terms of Service", destination: URL(string: "https://example.com/terms")!)
                }
            }
            .navigationTitle("Settings")
            .alert("Import Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .overlay {
                if showingImportProgress {
                    VStack {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text(importMessage)
                            .padding(.top)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 10)
                }
            }
        }
        .onAppear {
            DeepSeekClient.shared.setAPIKey(apiKey)
        }
    }
    
    private func importHolidays() {
        showingImportProgress = true
        importMessage = "Importing holidays..."
        
        Task {
            do {
                try await HolidayImporter.shared.importHolidays(context: context)
                
                await MainActor.run {
                    importMessage = "Holidays imported successfully!"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        showingImportProgress = false
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to import holidays: \(error.localizedDescription)"
                    showingError = true
                    showingImportProgress = false
                }
            }
        }
    }
}
