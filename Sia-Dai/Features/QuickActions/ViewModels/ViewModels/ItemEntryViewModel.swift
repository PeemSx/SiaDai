import Foundation
import SwiftData

@MainActor
final class ItemEntryViewModel {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    @discardableResult
    func saveItem(
        name: String,
        valueText: String,
        amountText: String,
        unit: String,
        expiryDate: Date,
        imageData: Data? = nil
    ) -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalName = trimmedName.isEmpty ? "New Item" : trimmedName

        guard
            let value = Self.parseDecimal(from: valueText),
            let amount = Self.parseDecimal(from: amountText)
        else {
            return false
        }

        let item = FoodItem(
            name: finalName,
            imageData: imageData,
            purchaseValue: value,
            amount: amount,
            unit: unit,
            expiryDate: expiryDate,
            status: .tracking
        )

        modelContext.insert(item)

        do {
            try modelContext.save()
            return true
        } catch {
            modelContext.rollback()
            print("Save failed: \(error)")
            return false
        }
    }

    private static func parseDecimal(from text: String) -> Double? {
        let sanitizedText = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")

        guard !sanitizedText.isEmpty else {
            return nil
        }

        return Double(sanitizedText)
    }
}
