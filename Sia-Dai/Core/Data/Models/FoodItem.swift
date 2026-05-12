import Foundation
import SwiftData

enum FoodItemStatus: String, Codable, CaseIterable, Identifiable {
    case tracking = "Tracking"
    case eaten = "Eaten"
    case trashed = "Trashed"

    var id: String { rawValue }
}

@Model
final class FoodItem {
    var id: UUID
    var name: String
    @Attribute(.externalStorage) var imageData: Data?
    var purchaseValue: Double
    var amount: Double
    var unit: String
    var dateAdded: Date
    var expiryDate: Date
    var wasteRecordedAt: Date?
    var status: FoodItemStatus

    init(
        id: UUID = UUID(),
        name: String,
        imageData: Data? = nil,
        purchaseValue: Double,
        amount: Double,
        unit: String,
        dateAdded: Date = .now,
        expiryDate: Date,
        wasteRecordedAt: Date? = nil,
        status: FoodItemStatus = .tracking
    ) {
        self.id = id
        self.name = name
        self.imageData = imageData
        self.purchaseValue = purchaseValue
        self.amount = amount
        self.unit = unit
        self.dateAdded = dateAdded
        self.expiryDate = expiryDate
        self.wasteRecordedAt = wasteRecordedAt
        self.status = status
    }

    convenience init(
        id: UUID = UUID(),
        name: String,
        imageData: Data? = nil,
        purchaseValue: Double,
        amount: Double,
        unit: String,
        dateAdded: Date = .now,
        expiryDate: Date,
        status: FoodItemStatus = .tracking
    ) {
        self.init(
            id: id,
            name: name,
            imageData: imageData,
            purchaseValue: purchaseValue,
            amount: amount,
            unit: unit,
            dateAdded: dateAdded,
            expiryDate: expiryDate,
            wasteRecordedAt: nil,
            status: status
        )
    }
}
