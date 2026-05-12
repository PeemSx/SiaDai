import SwiftData
import SwiftUI

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FoodItem.expiryDate) private var foodItems: [FoodItem]

    @State private var recipesViewModel = RescueRecipesViewModel()

    private let viewModel = QuickActionsViewModel()
    private let recipeInventoryManager = RecipeInventoryManager()

    private var priorityItem: FoodItem? {
        viewModel.priorityItem(from: foodItems)
    }

    private var trackingItems: [FoodItem] {
        foodItems
            .filter { $0.status == .tracking && $0.amount > 0 }
            .sorted { lhs, rhs in
                let lhsDays = Date().daysUntil(lhs.expiryDate)
                let rhsDays = Date().daysUntil(rhs.expiryDate)

                if lhsDays != rhsDays {
                    return lhsDays < rhsDays
                }

                return lhs.dateAdded < rhs.dateAdded
            }
    }

    private var preventableLoss: Double {
        viewModel.preventableLoss(from: foodItems)
    }

    var body: some View {
        ZStack {
            Color.screenBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                TopBrandBar()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 28) {
                        headerSection

                        if let priorityItem {
                            QuickActionView(
                                item: priorityItem,
                                viewModel: viewModel,
                                onMarkEaten: {
                                    performQuickAction(.eaten, for: priorityItem)
                                },
                                onMarkTrashed: {
                                    performQuickAction(.trashed, for: priorityItem)
                                }
                            )

                            RescueRecipesSectionView(
                                recipes: recipesViewModel.recipes,
                                sourceItems: trackingItems,
                                isLoading: recipesViewModel.isLoading,
                                statusState: recipesViewModel.currentStatusState,
                                statusTitle: recipesViewModel.statusTitle,
                                statusMessage: recipesViewModel.statusMessage,
                                recommendation: recipesViewModel.recommendation,
                                showsHeaderAction: recipesViewModel.showsHeaderAction,
                                headerActionTitle: recipesViewModel.headerActionTitle,
                                showsStatusAction: recipesViewModel.showsStatusAction,
                                statusActionTitle: recipesViewModel.statusActionTitle,
                                onGenerateRecipes: requestRecipes,
                                onMarkRecipeAsMade: { recipe in
                                    let result = recipeInventoryManager.applyRecipe(
                                        recipe,
                                        to: foodItems,
                                        in: modelContext
                                    )

                                    if result.didApply {
                                        recipesViewModel.clearRecipesAfterMarkAsMade()
                                    }

                                    return result
                                }
                            )
                        } else {
                            emptyState
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 180)
                }
            }
        }
        .task(id: recipeTaskID) {
            recipesViewModel.syncInventory(trackingItems)
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PRIORITIES")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .tracking(1.8)
                .foregroundStyle(Color.brandGreen)

            Text("Quick Actions")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(.black)

            Text("Prevent \(viewModel.currencyString(for: preventableLoss)) from being wasted.")
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your quick actions are clear.")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.black)

            Text("Add more ingredients to the watchlist to surface items that need attention first.")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 12) {
                Image(systemName: "leaf.circle.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(Color.brandGreen)

                Text("The Home tab will highlight the most urgent tracked item once inventory is available.")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.black.opacity(0.72))
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        }
        .padding(28)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white,
                            Color(red: 0.94, green: 0.97, blue: 0.94)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .shadow(color: .cardShadow, radius: 16, x: 0, y: 10)
    }

    private func performQuickAction(_ status: FoodItemStatus, for item: FoodItem) {
        let didSave = viewModel.updateStatus(status, for: item, in: modelContext)

        if didSave == false {
            assertionFailure("Failed to update quick action item status.")
        }
    }

    private func requestRecipes() {
        Task {
            await recipesViewModel.generateRecipes(from: trackingItems)
        }
    }

    private var recipeTaskID: String {
        trackingItems
            .map { item in
                "\(item.id.uuidString)-\(item.amount)-\(item.status.rawValue)-\(item.unit)"
            }
            .joined(separator: "|")
    }
}

#Preview {
    HomeView()
        .modelContainer(PreviewHelper.previewContainer)
}
