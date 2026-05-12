import SwiftUI
import UIKit

struct RecipeArtworkView: View {
    let recipe: RescueRecipe
    let sourceItems: [FoodItem]

    var body: some View {
        GeometryReader { proxy in
            if let image = recipeImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
            } else {
                fallbackArtwork(size: proxy.size)
            }
        }
        .clipped()
    }

    private var recipeImage: UIImage? {
        guard
            let item = sourceItems.first(where: { $0.id == recipe.primaryTrackedIngredientID }),
            let data = item.imageData
        else {
            return nil
        }

        return UIImage(data: data)
    }

    @ViewBuilder
    private func fallbackArtwork(size: CGSize) -> some View {
        let style = RecipeArtworkStyle(styleSeed: styleSeed)

        ZStack {
            LinearGradient(
                colors: style.colors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(style.glow.opacity(0.36))
                .frame(width: size.width * 0.78, height: size.width * 0.78)
                .blur(radius: 24)
                .offset(x: size.width * 0.18, y: size.height * 0.10)

            Circle()
                .fill(.white.opacity(0.08))
                .frame(width: size.width * 0.62, height: size.width * 0.62)
                .blur(radius: 18)
                .offset(x: -size.width * 0.12, y: -size.height * 0.14)

            Image(systemName: style.symbolName)
                .font(.system(size: min(size.width, size.height) * 0.32, weight: .regular))
                .foregroundStyle(.white.opacity(0.88))

            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(.white.opacity(0.10), lineWidth: 1.2)
                .padding(18)
        }
        .frame(width: size.width, height: size.height)
    }

    private var styleSeed: String {
        recipe.matchedIngredients.first?.itemName ?? recipe.title
    }
}

private struct RecipeArtworkStyle {
    let colors: [Color]
    let glow: Color
    let symbolName: String

    init(styleSeed: String) {
        let lowercasedSeed = styleSeed.lowercased()

        if lowercasedSeed.contains("spinach") || lowercasedSeed.contains("leaf") {
            colors = [
                Color(red: 0.11, green: 0.16, blue: 0.20),
                Color(red: 0.26, green: 0.41, blue: 0.33)
            ]
            glow = Color(red: 0.34, green: 0.77, blue: 0.51)
            symbolName = "leaf.fill"
            return
        }

        if lowercasedSeed.contains("salmon") || lowercasedSeed.contains("fish") {
            colors = [
                Color(red: 0.12, green: 0.16, blue: 0.19),
                Color(red: 0.28, green: 0.24, blue: 0.21)
            ]
            glow = Color(red: 0.92, green: 0.63, blue: 0.45)
            symbolName = "fish.fill"
            return
        }

        if lowercasedSeed.contains("milk") || lowercasedSeed.contains("yogurt") {
            colors = [
                Color(red: 0.09, green: 0.13, blue: 0.17),
                Color(red: 0.26, green: 0.28, blue: 0.32)
            ]
            glow = Color(red: 0.71, green: 0.81, blue: 0.93)
            symbolName = "drop.fill"
            return
        }

        if lowercasedSeed.contains("apple") {
            colors = [
                Color(red: 0.18, green: 0.16, blue: 0.12),
                Color(red: 0.34, green: 0.24, blue: 0.14)
            ]
            glow = Color(red: 0.98, green: 0.72, blue: 0.42)
            symbolName = "basket.fill"
            return
        }

        colors = [
            Color(red: 0.13, green: 0.18, blue: 0.18),
            Color(red: 0.19, green: 0.32, blue: 0.29)
        ]
        glow = Color(red: 0.44, green: 0.79, blue: 0.62)
        symbolName = "fork.knife"
    }
}
