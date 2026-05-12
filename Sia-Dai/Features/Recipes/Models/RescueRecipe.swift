import Foundation

struct RecipeIngredientUsage: Identifiable, Hashable, Codable {
    let id: UUID
    let foodItemID: UUID
    let itemName: String
    let amount: Double
    let unit: String

    init(
        id: UUID = UUID(),
        foodItemID: UUID,
        itemName: String,
        amount: Double,
        unit: String
    ) {
        self.id = id
        self.foodItemID = foodItemID
        self.itemName = itemName
        self.amount = amount
        self.unit = unit
    }
}

struct RescueRecipe: Identifiable, Hashable, Codable {
    let id: UUID
    let title: String
    let summary: String
    let benefitTag: String
    let prepMinutes: Int
    let cookMinutes: Int
    let difficulty: String
    let servings: Int
    let storageTip: String
    let matchedIngredients: [RecipeIngredientUsage]
    let otherIngredients: [String]
    let steps: [String]

    init(
        id: UUID = UUID(),
        title: String,
        summary: String,
        benefitTag: String,
        prepMinutes: Int,
        cookMinutes: Int,
        difficulty: String,
        servings: Int,
        storageTip: String,
        matchedIngredients: [RecipeIngredientUsage],
        otherIngredients: [String],
        steps: [String]
    ) {
        self.id = id
        self.title = title
        self.summary = summary
        self.benefitTag = benefitTag
        self.prepMinutes = prepMinutes
        self.cookMinutes = cookMinutes
        self.difficulty = difficulty
        self.servings = servings
        self.storageTip = storageTip
        self.matchedIngredients = matchedIngredients
        self.otherIngredients = otherIngredients
        self.steps = steps
    }

    var primaryTrackedIngredientID: UUID? {
        matchedIngredients.first?.foodItemID
    }

    var totalMinutes: Int {
        prepMinutes + cookMinutes
    }

    var ingredientSummary: String {
        "\(matchedIngredients.count + otherIngredients.count) Ingredients • \(benefitTag)"
    }

    var timeBadgeTitle: String {
        "\(max(totalMinutes, 1)) mins"
    }
}

struct RecipeInventoryApplicationResult {
    let didApply: Bool
    let message: String
}
