import SwiftUI

enum AppTab: String, CaseIterable, Hashable {
    case home = "Home"
    case watchlist = "Watch"
    case addItem = "Add"
    case wasteJar = "Bin"


    var symbolName: String {
        switch self {
        case .home:
            return "house.fill"
        case .watchlist:
            return "eye.fill"
        case .addItem:
            return "plus.circle"
        case .wasteJar:
            return "trash"
        }
    }

    var accessibilityTitle: String {
        switch self {
        case .home:
            return "Home"
        case .watchlist:
            return "Watchlist"
        case .addItem:
            return "Add Item"
        case .wasteJar:
            return "Waste Jar"
        }
    }
}

struct NavBar: View {
    @Binding var selectedTab: AppTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: tab.symbolName)
                            .font(.system(size: 22, weight: .semibold))

                        Text(tab.rawValue)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .tracking(1.1)
                    }
                    .foregroundStyle(selectedTab == tab ? Color.brandGreen : Color.secondary.opacity(0.72))
                    .frame(maxWidth: .infinity)
                    .frame(height: 80)
                    .background {
                        if selectedTab == tab {
                            Circle()
                                .fill(Color.brandGreen.opacity(0.12))
                                .frame(width: 70, height: 70)
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tab.accessibilityTitle)
            }
        }
        .padding(.horizontal, 12)
        .frame(width: 320)
        .background(
            RoundedRectangle(cornerRadius: 36, style: .continuous)
            .fill(Color.white)
            .shadow(color: Color.black.opacity(0.08), radius: 18, x: 0, y: -8)
        )
    }
}
