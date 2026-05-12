import Foundation
import SwiftData

@MainActor
final class ItemEntryViewModel {
    static let supportedUnits = ["g", "kg", "ml", "L", "pcs", "pack"]

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
        let finalUnit = Self.normalizedUnit(unit)

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
            unit: finalUnit,
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

    @discardableResult
    func updateItem(
        _ item: FoodItem,
        name: String,
        valueText: String,
        amountText: String,
        unit: String,
        expiryDate: Date,
        imageData: Data?
    ) -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalName = trimmedName.isEmpty ? "New Item" : trimmedName
        let finalUnit = Self.normalizedUnit(unit)

        guard
            let value = Self.parseDecimal(from: valueText),
            let amount = Self.parseDecimal(from: amountText)
        else {
            return false
        }

        let originalName = item.name
        let originalPurchaseValue = item.purchaseValue
        let originalAmount = item.amount
        let originalUnit = item.unit
        let originalExpiryDate = item.expiryDate
        let originalImageData = item.imageData

        item.name = finalName
        item.purchaseValue = value
        item.amount = amount
        item.unit = finalUnit
        item.expiryDate = expiryDate
        item.imageData = imageData

        do {
            try modelContext.save()
            return true
        } catch {
            item.name = originalName
            item.purchaseValue = originalPurchaseValue
            item.amount = originalAmount
            item.unit = originalUnit
            item.expiryDate = originalExpiryDate
            item.imageData = originalImageData
            modelContext.rollback()
            print("Update failed: \(error)")
            return false
        }
    }

    @discardableResult
    func deleteItem(_ item: FoodItem) -> Bool {
        modelContext.delete(item)

        do {
            try modelContext.save()
            return true
        } catch {
            modelContext.rollback()
            print("Delete failed: \(error)")
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

    private static func normalizedUnit(_ unit: String) -> String {
        supportedUnits.contains(unit) ? unit : "pcs"
    }
}
