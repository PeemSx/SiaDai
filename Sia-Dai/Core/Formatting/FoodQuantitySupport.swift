import Foundation

enum FoodQuantityFormatter {
    static func string(amount: Double, unit: String) -> String {
        let formattedAmount: String

        if amount.rounded() == amount {
            formattedAmount = "\(Int(amount))"
        } else {
            formattedAmount = String(format: "%.1f", amount)
        }

        let compactUnits = ["g", "kg", "ml", "L"]
        if compactUnits.contains(unit) {
            return "\(formattedAmount)\(unit)"
        }

        return "\(formattedAmount) \(unit)"
    }
}

enum FoodUnitConverter {
    static func convert(_ amount: Double, from sourceUnit: String, to targetUnit: String) -> Double? {
        let normalizedSource = normalized(unit: sourceUnit)
        let normalizedTarget = normalized(unit: targetUnit)

        guard
            let sourceScale = scale(for: normalizedSource),
            let targetScale = scale(for: normalizedTarget),
            sourceScale.category == targetScale.category
        else {
            return nil
        }

        let baseAmount = amount * sourceScale.multiplier
        return baseAmount / targetScale.multiplier
    }

    private static func normalized(unit: String) -> String {
        unit.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func scale(for unit: String) -> (category: String, multiplier: Double)? {
        switch unit {
        case "g":
            return ("mass", 1)
        case "kg":
            return ("mass", 1_000)
        case "ml":
            return ("volume", 1)
        case "L":
            return ("volume", 1_000)
        case "pcs":
            return ("count", 1)
        case "pack":
            return ("pack", 1)
        default:
            return nil
        }
    }
}
