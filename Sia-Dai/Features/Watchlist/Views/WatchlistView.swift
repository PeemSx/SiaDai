import SwiftUI
import SwiftData

struct WatchlistView: View {
    @Query(sort: \FoodItem.expiryDate) private var foodItems: [FoodItem]
    @State private var activeSheet: WatchlistSheet?

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    private var activeItems: [FoodItem] {
        foodItems.filter { $0.status == .tracking }
    }
    
    var body: some View {
        ZStack {
            Color.screenBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                TopBrandBar()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 26) {
                        inventoryHeader
                        
                        if activeItems.isEmpty {
                            emptyState
                        } else {
                            LazyVGrid(columns: columns, spacing: 28) {
                                ForEach(activeItems, id: \.id) { item in
                                    Button {
                                        activeSheet = .edit(item)
                                    } label: {
                                        FoodCardView(item: item)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.top, 6)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 26)
                    .padding(.bottom, 180)
                }
            }
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .add:
                AddItemView()
                    .presentationDragIndicator(.visible)
            case let .edit(item):
                EditItemView(item: item)
                    .presentationDragIndicator(.visible)
            }
        }
    }
    
    private var inventoryHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("YOUR INVENTORY")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .tracking(1.6)
                .foregroundStyle(Color.brandGreen)

            HStack(alignment: .center, spacing: 12) {
                Text("Watchlist")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(.black)
                    .minimumScaleFactor(0.82)

                Spacer(minLength: 10)

                Button {
                    activeSheet = .add
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.black)
                        .frame(width: 52, height: 52)
                        .background(Color.white, in: Circle())
                        .shadow(color: .cardShadow, radius: 12, x: 0, y: 8)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add Item")
            }
        }
    }

    private var emptyState: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(Color.white)
            .frame(maxWidth: .infinity)
            .frame(height: 240)
            .overlay {
                VStack(spacing: 10) {
                    Image(systemName: "basket")
                        .font(.system(size: 30, weight: .medium))
                        .foregroundStyle(Color.brandGreen)

                    Text("No active food items")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.black)

                    Text("Add something to start tracking what needs to be used first.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                }
            }
    }
}

private enum WatchlistSheet: Identifiable {
    case add
    case edit(FoodItem)

    var id: String {
        switch self {
        case .add:
            return "add"
        case let .edit(item):
            return "edit-\(item.id.uuidString)"
        }
    }
}

#Preview {
    WatchlistView()
        .modelContainer(PreviewHelper.previewContainer)
}
