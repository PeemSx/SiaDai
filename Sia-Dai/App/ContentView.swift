import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab: AppTab = .home

    var body: some View {
        NavigationStack {
            activeTabView
                .toolbar(.hidden, for: .navigationBar)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            NavBar(selectedTab: $selectedTab)
        }
        .animation(.snappy(duration: 0.28, extraBounce: 0), value: selectedTab)
    }

    @ViewBuilder
    private var activeTabView: some View {
        switch selectedTab {
        case .home:
            HomeView()
        case .watchlist:
            WatchlistView()
        case .addItem:
            AddItemView()
        case .wasteJar:
            WasteJarView()

        }
    }

}

#Preview {
    ContentView()
        .modelContainer(PreviewHelper.previewContainer)
}
