import Foundation
import SwiftData

@MainActor
struct RecipeInventoryManager {
    private let amountEpsilon = 0.0001

    func applyRecipe(
        _ recipe: RescueRecipe,
        to availableItems: [FoodItem],
        in modelContext: ModelContext
    ) -> RecipeInventoryApplicationResult {
        let trackedLookup = Dictionary(uniqueKeysWithValues: availableItems.map { ($0.id, $0) })
        var usagePlan: [(item: FoodItem, amountToSubtract: Double)] = []

        for usage in recipe.matchedIngredients {
            guard let item = trackedLookup[usage.foodItemID], item.status == .tracking else {
                return RecipeInventoryApplicationResult(
                    didApply: false,
                    message: "Inventory changed. Open the recipe list again before marking this as made."
                )
            }

            guard let amountToSubtract = FoodUnitConverter.convert(
                usage.amount,
                from: usage.unit,
                to: item.unit
            ) else {
                return RecipeInventoryApplicationResult(
                    didApply: false,
                    message: "Couldn't convert \(usage.itemName) from \(usage.unit) to \(item.unit)."
                )
            }

            if item.amount + amountEpsilon < amountToSubtract {
                return RecipeInventoryApplicationResult(
                    didApply: false,
                    message: "Not enough \(usage.itemName) remains in the watchlist for this recipe."
                )
            }

            usagePlan.append((item, amountToSubtract))
        }

        let originals = usagePlan.map { plan in
            (
                item: plan.item,
                amount: plan.item.amount,
                status: plan.item.status,
                wasteRecordedAt: plan.item.wasteRecordedAt
            )
        }

        for plan in usagePlan {
            let remainingAmount = max(0, plan.item.amount - plan.amountToSubtract)
            plan.item.amount = remainingAmount

            if remainingAmount <= amountEpsilon {
                plan.item.amount = 0
                plan.item.status = .eaten
                plan.item.wasteRecordedAt = nil
            }
        }

        do {
            try modelContext.save()
            return RecipeInventoryApplicationResult(
                didApply: true,
                message: "Inventory updated from this recipe."
            )
        } catch {
            for original in originals {
                original.item.amount = original.amount
                original.item.status = original.status
                original.item.wasteRecordedAt = original.wasteRecordedAt
            }

            modelContext.rollback()
            return RecipeInventoryApplicationResult(
                didApply: false,
                message: "Failed to save the inventory update."
            )
        }
    }
}
