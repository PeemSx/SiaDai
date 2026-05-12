import SwiftUI

struct RescueRecipesSectionView: View {
    let recipes: [RescueRecipe]
    let sourceItems: [FoodItem]
    let isLoading: Bool
    let statusState: RescueRecipesStatusState
    let statusTitle: String
    let statusMessage: String
    let recommendation: String?
    let showsHeaderAction: Bool
    let headerActionTitle: String
    let showsStatusAction: Bool
    let statusActionTitle: String
    let onGenerateRecipes: () -> Void
    let onMarkRecipeAsMade: (RescueRecipe) -> RecipeInventoryApplicationResult

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Rescue Recipes")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.black)

                    Text("Cook from your watchlist before ingredients turn into waste.")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 12)

                if showsHeaderAction {
                    Button(action: onGenerateRecipes) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 12, weight: .bold))

                            Text(headerActionTitle)
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(isLoading ? Color.secondary : Color.brandGreen)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.white, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(isLoading)
                }
            }

            if isLoading {
                loadingCard
            } else if recipes.isEmpty {
                statusCard
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 18) {
                        ForEach(recipes) { recipe in
                            NavigationLink {
                                RescueRecipeDetailView(
                                    recipe: recipe,
                                    sourceItems: sourceItems,
                                    onMarkRecipeAsMade: onMarkRecipeAsMade
                                )
                            } label: {
                                RecipeCardView(
                                    recipe: recipe,
                                    sourceItems: sourceItems
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 2)
                }
                .contentMargins(.horizontal, 0, for: .scrollContent)
            }
        }
    }

    private var loadingCard: some View {
        RoundedRectangle(cornerRadius: 30, style: .continuous)
            .fill(Color.white)
            .frame(maxWidth: .infinity)
            .frame(height: 196)
            .overlay {
                VStack(spacing: 14) {
                    ProgressView()
                        .tint(Color.brandGreen)

                    Text("Generating recipes from your tracked ingredients...")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
            .shadow(color: .cardShadow, radius: 14, x: 0, y: 10)
    }

    private var statusCard: some View {
        RoundedRectangle(cornerRadius: 30, style: .continuous)
            .fill(Color.white)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 236)
            .overlay {
                VStack(spacing: 12) {
                    Image(systemName: statusIconName)
                        .font(.system(size: 32, weight: .medium))
                        .foregroundStyle(statusIconColor)

                    Text(statusTitle)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.black)

                    Text(statusMessage)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    if let recommendation {
                        Text(recommendation)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(.black.opacity(0.70))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }

                    if showsStatusAction {
                        Button(action: onGenerateRecipes) {
                            Text(statusActionTitle)
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 22)
                                .padding(.vertical, 12)
                                .background(Color.brandGreen, in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 28)
            }
            .shadow(color: .cardShadow, radius: 14, x: 0, y: 10)
    }

    private var statusIconName: String {
        switch statusState {
        case .needsIngredients:
            return "basket.fill"
        case .idle:
            return "fork.knife.circle.fill"
        case .failure:
            return "exclamationmark.triangle.fill"
        }
    }

    private var statusIconColor: Color {
        switch statusState {
        case .needsIngredients, .idle:
            return Color.brandGreen
        case .failure:
            return Color.statusAmber
        }
    }
}

private struct RecipeCardView: View {
    let recipe: RescueRecipe
    let sourceItems: [FoodItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ZStack(alignment: .topLeading) {
                RecipeArtworkView(recipe: recipe, sourceItems: sourceItems)

                Text(recipe.timeBadgeTitle)
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .tracking(0.9)
                    .foregroundStyle(.black.opacity(0.76))
                    .padding(.horizontal, 13)
                    .padding(.vertical, 8)
                    .background(.white.opacity(0.92), in: Capsule())
                    .padding(14)
            }
            .frame(width: 272, height: 306)
            .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                Text(recipe.title)
                    .font(.system(size: 21, weight: .bold, design: .rounded))
                    .foregroundStyle(.black)
                    .lineLimit(2)

                Text(recipe.ingredientSummary)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Text("Inventory Match")
                .font(.system(size: 10, weight: .black, design: .rounded))
                .tracking(0.8)
                .foregroundStyle(Color.brandGreen)
                .padding(.horizontal, 11)
                .padding(.vertical, 7)
                .background(Color.brandGreen.opacity(0.10), in: Capsule())
        }
        .frame(width: 272, alignment: .leading)
        .padding(18)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 34, style: .continuous))
        .shadow(color: .cardShadow, radius: 16, x: 0, y: 12)
    }
}
