import SwiftUI
import SwiftData

struct WatchlistView: View {
    @Query(sort: \FoodItem.expiryDate) private var foodItems: [FoodItem]

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
                                    FoodCardView(item: item)
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

#Preview {
    WatchlistView()
        .modelContainer(PreviewHelper.previewContainer)
}
