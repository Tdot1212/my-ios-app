import SwiftUI

struct TrendsView: View {
    @StateObject private var vm = TrendsViewModel()
    @State private var geo = "US"

    var body: some View {
        VStack {
            Picker("Region", selection: $geo) {
                Text("US").tag("US")
                Text("CN").tag("CN")
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            List(vm.items) { item in
                VStack(alignment: .leading, spacing: 6) {
                    Text(item.title).font(.headline)
                    Text(item.source).foregroundStyle(.secondary)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if let url = URL(string: item.url) { UIApplication.shared.open(url) }
                }
            }
            .overlay { if vm.isLoading { ProgressView() } }
            .refreshable { vm.reload(geo: geo) }
        }
        .navigationTitle("Trends")
        .task { vm.reload(geo: geo) }
    }
}

#Preview {
    TrendsView()
}


