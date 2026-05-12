import Foundation
import Observation

#if canImport(FoundationModels)
import FoundationModels
#endif

enum RescueRecipesStatusState {
    case needsIngredients
    case idle
    case failure
}

@MainActor
@Observable
final class RescueRecipesViewModel {
    var recipes: [RescueRecipe] = []
    var isLoading = false

    private enum Persistence {
        static let recipesKey = "saved_rescue_recipes"
    }

    private let generator = RescueRecipeGenerator()
    private var currentInventorySignature = ""
    private var statusState: RescueRecipesStatusState = .needsIngredients
    private var lastErrorMessage: String?
    private var recommendationMessage: String?

    init() {
        restorePersistedRecipes()
    }

    var headerActionTitle: String {
        "Regenerate"
    }

    var showsHeaderAction: Bool {
        currentInventorySignature.isEmpty == false && recipes.isEmpty == false
    }

    var statusActionTitle: String {
        if statusState == .failure {
            return "Try Again"
        }

        return "Generate Recipes"
    }

    var showsStatusAction: Bool {
        currentInventorySignature.isEmpty == false && recipes.isEmpty && isLoading == false
    }

    var statusTitle: String {
        switch statusState {
        case .needsIngredients:
            return "No ingredients ready"
        case .idle:
            return "Generate recipes when you're ready"
        case .failure:
            return "Couldn't generate recipes"
        }
    }

    var statusMessage: String {
        switch statusState {
        case .needsIngredients:
            return "Add ingredients to your watchlist to generate rescue recipes."
        case .idle:
            return "Use the ingredients already in your watchlist to get quick recipe ideas."
        case .failure:
            return lastErrorMessage ?? "Recipe generation is unavailable right now."
        }
    }

    var recommendation: String? {
        switch statusState {
        case .needsIngredients:
            return nil
        case .idle:
            return "We will suggest simple ways to use your most urgent ingredients."
        case .failure:
            return recommendationMessage
        }
    }

    var currentStatusState: RescueRecipesStatusState {
        statusState
    }

    func syncInventory(_ items: [FoodItem]) {
        let trackedItems = trackedItems(from: items)
        let signature = inventorySignature(for: trackedItems)

        guard signature != currentInventorySignature else {
            return
        }

        currentInventorySignature = signature

        guard trackedItems.isEmpty == false else {
            statusState = recipes.isEmpty ? .needsIngredients : .idle
            return
        }

        if recipes.isEmpty == false {
            statusState = .idle
            return
        }

        if statusState != .failure {
            statusState = .idle
        }
    }

    func generateRecipes(from items: [FoodItem]) async {
        guard isLoading == false else {
            return
        }

        let trackedItems = trackedItems(from: items)
        let signature = inventorySignature(for: trackedItems)
        currentInventorySignature = signature

        guard trackedItems.isEmpty == false else {
            clearRecipes()
            return
        }

        if recipes.isEmpty == false {
            recipes = []
            persistRecipes()
        }

        isLoading = true
        lastErrorMessage = nil
        recommendationMessage = nil

        do {
            recipes = try await generator.generateRecipes(from: trackedItems)

            if recipes.isEmpty == false {
                persistRecipes()
                statusState = .idle
            } else {
                persistRecipes()
                statusState = .failure
                lastErrorMessage = "The model did not return any recipes for this inventory."
                recommendationMessage = "Try keeping 2 to 5 clear ingredients with amounts in your watchlist, then regenerate."
            }
        } catch let error as RecipeGenerationError {
            recipes = []
            persistRecipes()
            statusState = .failure
            lastErrorMessage = error.errorDescription
            recommendationMessage = recommendation(for: error)
        } catch {
            recipes = []
            persistRecipes()
            statusState = .failure
            lastErrorMessage = "Recipe generation is unavailable right now."
            recommendationMessage = "Try again in a moment."
        }

        isLoading = false
    }

    func clearRecipesAfterMarkAsMade() {
        recipes = []
        lastErrorMessage = nil
        recommendationMessage = nil
        persistRecipes()
        statusState = currentInventorySignature.isEmpty ? .needsIngredients : .idle
    }

    private func trackedItems(from items: [FoodItem]) -> [FoodItem] {
        items.filter { $0.status == .tracking && $0.amount > 0 }
    }

    private func recommendation(for error: RecipeGenerationError) -> String {
        switch error {
        case .modelUnavailable:
            return "Check that Apple Intelligence is available on this device, then try again."
        case .noRecipesReturned:
            return "Try tracking a few more ingredients or clearer item names, then regenerate."
        }
    }

    private func inventorySignature(for items: [FoodItem]) -> String {
        items
            .sorted { $0.id.uuidString < $1.id.uuidString }
            .map { item in
                "\(item.id.uuidString)|\(item.status.rawValue)|\(item.amount)|\(item.unit)|\(item.expiryDate.timeIntervalSince1970)"
            }
            .joined(separator: "||")
    }

    private func clearRecipes() {
        recipes = []
        lastErrorMessage = nil
        recommendationMessage = nil
        persistRecipes()
        statusState = .needsIngredients
    }

    private func persistRecipes() {
        let defaults = UserDefaults.standard

        guard recipes.isEmpty == false else {
            defaults.removeObject(forKey: Persistence.recipesKey)
            return
        }

        guard let data = try? JSONEncoder().encode(recipes) else {
            return
        }

        defaults.set(data, forKey: Persistence.recipesKey)
    }

    private func restorePersistedRecipes() {
        guard
            let data = UserDefaults.standard.data(forKey: Persistence.recipesKey),
            let decodedRecipes = try? JSONDecoder().decode([RescueRecipe].self, from: data)
        else {
            return
        }

        recipes = decodedRecipes
        statusState = decodedRecipes.isEmpty ? .needsIngredients : .idle
    }
}

private enum RecipeGenerationError: LocalizedError {
    case modelUnavailable(String)
    case noRecipesReturned

    var errorDescription: String? {
        switch self {
        case let .modelUnavailable(message):
            return message
        case .noRecipesReturned:
            return "The model did not return any usable recipes for the current inventory."
        }
    }
}

@MainActor
private struct RescueRecipeGenerator {
    func generateRecipes(from items: [FoodItem]) async throws -> [RescueRecipe] {
        let sortedItems = sortedTrackedItems(from: items)

        guard sortedItems.isEmpty == false else {
            return []
        }

        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            switch SystemLanguageModel.default.availability {
            case .available:
                let generatedRecipes = try await generateWithFoundationModel(from: Array(sortedItems.prefix(5)))
                guard generatedRecipes.isEmpty == false else {
                    throw RecipeGenerationError.noRecipesReturned
                }
                return Array(generatedRecipes.prefix(3))
            case let .unavailable(reason):
                throw RecipeGenerationError.modelUnavailable(modelUnavailableMessage(for: reason))
            }
        }
        #endif

        #if targetEnvironment(simulator)
        throw RecipeGenerationError.modelUnavailable(
            "Foundation Models is not available in the iOS Simulator. Run the app on a supported device."
        )
        #else
        throw RecipeGenerationError.modelUnavailable(
            "Foundation Models is not available in this app environment."
        )
        #endif
    }

    private func sortedTrackedItems(from items: [FoodItem]) -> [FoodItem] {
        items
            .filter { $0.status == .tracking && $0.amount > 0 }
            .sorted { lhs, rhs in
                let lhsDays = Date().daysUntil(lhs.expiryDate)
                let rhsDays = Date().daysUntil(rhs.expiryDate)

                if lhsDays != rhsDays {
                    return lhsDays < rhsDays
                }

                if lhs.purchaseValue != rhs.purchaseValue {
                    return lhs.purchaseValue > rhs.purchaseValue
                }

                return lhs.dateAdded < rhs.dateAdded
            }
    }

}

#if canImport(FoundationModels)
@available(iOS 26.0, *)
extension RescueRecipeGenerator {
    private struct AIGenerationEnvelope: Decodable {
        let recipes: [AIGeneratedRecipe]
    }

    private struct AIGeneratedRecipe: Decodable {
        let title: String
        let summary: String
        let benefitTag: String
        let prepMinutes: Int
        let cookMinutes: Int
        let difficulty: String
        let servings: Int
        let storageTip: String
        let trackedIngredients: [AITrackedIngredient]
        let otherIngredients: [String]
        let steps: [String]
    }

    private struct AITrackedIngredient: Decodable {
        let inventoryKey: String?
        let itemName: String?
        let amount: Double
        let unit: String
    }

    func generateWithFoundationModel(from items: [FoodItem]) async throws -> [RescueRecipe] {
        let instructions = """
        You create short anti-food-waste recipes for a mobile app.
        Return valid JSON only.
        Keep recipes practical, concise, and suitable for a home cook.
        """

        let prompt = """
        Create up to 3 rescue recipes using this inventory.

        Inventory:
        \(inventoryPrompt(from: items))

        JSON schema:
        {
          "recipes": [
            {
              "title": "Recipe name",
              "summary": "1 sentence",
              "benefitTag": "1-3 words",
              "prepMinutes": 5,
              "cookMinutes": 10,
              "difficulty": "Easy",
              "servings": 1,
              "storageTip": "1 sentence",
              "trackedIngredients": [
                {
                  "inventoryKey": "item-1",
                  "itemName": "Copy the inventory name",
                  "amount": 120,
                  "unit": "Use a compatible unit"
                }
              ],
              "otherIngredients": ["short pantry item strings"],
              "steps": ["3 to 6 short steps"]
            }
          ]
        }

        Rules:
        - Every tracked ingredient must use one of the inventoryKey values from the inventory list.
        - Use exact itemName strings from the inventory whenever you reference tracked ingredients.
        - Keep tracked ingredient amounts within what is available.
        - Prefer simple weekday recipes.
        - Do not include markdown fences.
        """

        let session = LanguageModelSession(
            model: .default,
            instructions: instructions
        )
        let response = try await session.respond(
            to: prompt,
            options: GenerationOptions(
                temperature: 0.3,
                maximumResponseTokens: 1_200
            )
        )
        let cleanedJSON = cleanedJSONPayload(from: response.content)
        let envelope = try JSONDecoder().decode(
            AIGenerationEnvelope.self,
            from: Data(cleanedJSON.utf8)
        )

        return resolveAIGeneratedRecipes(envelope.recipes, against: items)
    }

    private func inventoryPrompt(from items: [FoodItem]) -> String {
        items.enumerated().map { index, item in
            "- item-\(index + 1) | \(item.name) | \(FoodQuantityFormatter.string(amount: item.amount, unit: item.unit)) | expires in \(Date().daysUntil(item.expiryDate)) day(s)"
        }
        .joined(separator: "\n")
    }

    private func cleanedJSONPayload(from text: String) -> String {
        text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func resolveAIGeneratedRecipes(
        _ generatedRecipes: [AIGeneratedRecipe],
        against items: [FoodItem]
    ) -> [RescueRecipe] {
        let keyedItems = Dictionary(uniqueKeysWithValues: items.enumerated().map { index, item in
            ("item-\(index + 1)", item)
        })
        let itemLookup = Dictionary(grouping: items, by: { normalized($0.name) })

        return generatedRecipes.compactMap { generatedRecipe in
            let matchedIngredients: [RecipeIngredientUsage] = generatedRecipe.trackedIngredients.compactMap { ingredient -> RecipeIngredientUsage? in
                let keyedMatch = ingredient.inventoryKey.flatMap { keyedItems[$0] }
                let namedMatch = ingredient.itemName.flatMap { itemLookup[normalized($0)]?.first }

                guard let item = keyedMatch ?? namedMatch ?? fuzzyMatchedItem(for: ingredient.itemName, in: items) else {
                    return nil
                }

                let normalizedAmount: Double

                if let convertedAmount = FoodUnitConverter.convert(
                    ingredient.amount,
                    from: ingredient.unit,
                    to: item.unit
                ) {
                    normalizedAmount = min(convertedAmount, item.amount)
                } else {
                    normalizedAmount = min(item.amount, ingredient.amount)
                }

                guard normalizedAmount > 0 else {
                    return nil
                }

                return RecipeIngredientUsage(
                    foodItemID: item.id,
                    itemName: item.name,
                    amount: normalizedAmount,
                    unit: item.unit
                )
            }

            guard matchedIngredients.isEmpty == false else {
                return nil
            }

            let cleanedSteps = generatedRecipe.steps
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { $0.isEmpty == false }

            guard cleanedSteps.isEmpty == false else {
                return nil
            }

            return RescueRecipe(
                title: generatedRecipe.title.trimmingCharacters(in: .whitespacesAndNewlines),
                summary: generatedRecipe.summary.trimmingCharacters(in: .whitespacesAndNewlines),
                benefitTag: generatedRecipe.benefitTag.trimmingCharacters(in: .whitespacesAndNewlines),
                prepMinutes: max(generatedRecipe.prepMinutes, 1),
                cookMinutes: max(generatedRecipe.cookMinutes, 0),
                difficulty: generatedRecipe.difficulty.trimmingCharacters(in: .whitespacesAndNewlines),
                servings: max(generatedRecipe.servings, 1),
                storageTip: generatedRecipe.storageTip.trimmingCharacters(in: .whitespacesAndNewlines),
                matchedIngredients: matchedIngredients,
                otherIngredients: generatedRecipe.otherIngredients.filter { $0.isEmpty == false },
                steps: cleanedSteps
            )
        }
    }

    private func modelUnavailableMessage(
        for reason: SystemLanguageModel.Availability.UnavailableReason
    ) -> String {
        switch reason {
        case .deviceNotEligible:
            return "This device does not support Apple's on-device Foundation Model."
        case .appleIntelligenceNotEnabled:
            return "Apple Intelligence is turned off, so recipe generation is unavailable."
        case .modelNotReady:
            return "The on-device Foundation Model is not ready yet."
        @unknown default:
            return "The on-device Foundation Model is unavailable right now."
        }
    }

    private func normalized(_ name: String) -> String {
        name
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    private func fuzzyMatchedItem(for itemName: String?, in items: [FoodItem]) -> FoodItem? {
        guard let itemName, itemName.isEmpty == false else {
            return nil
        }

        let candidate = normalized(itemName)
        return items.first { item in
            let normalizedInventoryName = normalized(item.name)
            return normalizedInventoryName.contains(candidate) || candidate.contains(normalizedInventoryName)
        }
    }
}
#endif
