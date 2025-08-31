import SwiftUI
import SwiftData

struct TrendsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \TrendItem.fetchedAt, order: .reverse) private var trends: [TrendItem]
    @State private var isRefreshing = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var selectedRegion = "US"
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Picker("Region", selection: $selectedRegion) {
                        Text("United States").tag("US")
                        Text("China").tag("CN")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: selectedRegion) { _, _ in
                        refreshTrends()
                    }
                }
                
                if !trends.isEmpty {
                    Section {
                        ForEach(trends) { trend in
                            TrendRowView(trend: trend)
                        }
                    }
                } else {
                    Section {
                        VStack(spacing: 16) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 48))
                                .foregroundColor(.gray)
                            Text("No trends available")
                                .font(.headline)
                                .foregroundColor(.gray)
                            Text("Pull to refresh to get the latest trends")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    }
                }
            }
            .navigationTitle("Trends")
            .refreshable {
                await refreshTrendsAsync()
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                if trends.isEmpty {
                    refreshTrends()
                }
            }
        }
    }
    
    private func refreshTrends() {
        Task {
            await refreshTrendsAsync()
        }
    }
    
    private func refreshTrendsAsync() async {
        isRefreshing = true
        
        do {
            let dtos = try await TrendsClient.fetchAll(geo: selectedRegion == "US" ? "US" : "CN")
            
            await MainActor.run {
                // Clear existing trends
                try? context.delete(model: TrendItem.self)
                
                // Add new trends
                for d in dtos {
                    context.insert(TrendItem(headline: d.title, url: d.url))
                }
                
                try? context.save()
                isRefreshing = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to fetch trends: \(error.localizedDescription)"
                showingError = true
                isRefreshing = false
            }
        }
    }
}

struct TrendRowView: View {
    let trend: TrendItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(trend.headline)
                .font(.headline)
                .lineLimit(3)
            
            if let url = trend.url {
                Link("Read more", destination: URL(string: url)!)
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            
            Text(trend.fetchedAt, style: .relative)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 4)
    }
}


