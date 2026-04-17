import CoreML
import CoreVideo
import Foundation
import ImageIO

nonisolated struct IngredientPrediction: Equatable, Sendable, Identifiable {
    let rawLabel: String
    let displayName: String
    let confidence: Double

    var id: String { rawLabel }
}

nonisolated struct IngredientClassification: Equatable, Sendable {
    let predictions: [IngredientPrediction]
    
    var topPrediction: IngredientPrediction? {
        predictions.first
    }
}

nonisolated private struct CachedModel: @unchecked Sendable {
    let value: MLModel
}

nonisolated enum IngredientImageClassifier {
    private static let modelName = "VegFruMobileNetV3Large"
    private static let cachedModel: CachedModel? = {
        do {
            return try CachedModel(value: loadModel())
        } catch {
            assertionFailure("Ingredient classifier model failed to load: \(error)")
            return nil
        }
    }()

    static func classify(imageData: Data) throws -> IngredientClassification {
        guard let model = cachedModel?.value else {
            throw ClassificationError.modelUnavailable
        }

        let cgImage = try makeCGImage(from: imageData)
        let imageValue = try MLFeatureValue(
            cgImage: cgImage,
            pixelsWide: 224,
            pixelsHigh: 224,
            pixelFormatType: kCVPixelFormatType_32ARGB,
            options: nil
        )
        let input = try MLDictionaryFeatureProvider(dictionary: ["image": imageValue])
        let output = try model.prediction(from: input)
        let normalizedScores = normalizeScores(probabilities(from: output))
        let topLabel = output.featureValue(for: "classLabel")?.stringValue ?? ""

        let predictions = normalizedScores
            .sorted { $0.value > $1.value }
            .prefix(3)
            .map { label, confidence in
                IngredientPrediction(
                    rawLabel: label,
                    displayName: makeDisplayName(from: label),
                    confidence: confidence
                )
            }

        if predictions.isEmpty {
            return IngredientClassification(
                predictions: [
                    IngredientPrediction(
                        rawLabel: topLabel,
                        displayName: makeDisplayName(from: topLabel),
                        confidence: 1
                    )
                ]
            )
        }

        return IngredientClassification(predictions: predictions)
    }

    private static func loadModel() throws -> MLModel {
        guard let modelURL = Bundle.main.url(forResource: modelName, withExtension: "mlmodelc") else {
            throw ClassificationError.modelUnavailable
        }

        return try MLModel(contentsOf: modelURL)
    }

    private static func makeCGImage(from imageData: Data) throws -> CGImage {
        guard
            let source = CGImageSourceCreateWithData(imageData as CFData, nil),
            let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
        else {
            throw ClassificationError.invalidImage
        }

        return image
    }

    private static func makeDisplayName(from identifier: String) -> String {
        identifier
            .replacingOccurrences(of: "_", with: " ")
            .split(separator: " ")
            .map { token in
                token
                    .split(separator: "-", omittingEmptySubsequences: false)
                    .map { hyphenFragment in
                        hyphenFragment
                            .split(separator: "'", omittingEmptySubsequences: false)
                            .map { apostropheFragment in
                                let fragment = String(apostropheFragment)
                                guard let firstCharacter = fragment.first else {
                                    return fragment
                                }

                                return String(firstCharacter).uppercased() + fragment.dropFirst().lowercased()
                            }
                            .joined(separator: "'")
                    }
                    .joined(separator: "-")
            }
            .joined(separator: " ")
    }

    private static func probabilities(from featureProvider: MLFeatureProvider) -> [String: Double] {
        guard let probabilityValue = featureProvider.featureValue(for: "classLabel_probs") else {
            return [:]
        }

        return probabilityValue.dictionaryValue.reduce(into: [:]) { result, entry in
            guard let label = entry.key as? String else {
                return
            }

            result[label] = entry.value.doubleValue
        }
    }

    private static func normalizeScores(_ scores: [String: Double]) -> [String: Double] {
        let finiteScores = scores.filter { $0.value.isFinite }

        guard !finiteScores.isEmpty else {
            return [:]
        }

        let scoreValues = Array(finiteScores.values)
        let looksLikeProbabilityDistribution =
            scoreValues.allSatisfy { (0...1).contains($0) } &&
            abs(scoreValues.reduce(0, +) - 1) < 0.05

        if looksLikeProbabilityDistribution {
            return finiteScores
        }

        guard let maxScore = scoreValues.max() else {
            return [:]
        }

        let exponentiated = finiteScores.mapValues { Foundation.exp($0 - maxScore) }
        let normalizationFactor = exponentiated.values.reduce(0, +)

        guard normalizationFactor.isFinite, normalizationFactor > 0 else {
            return [:]
        }

        return exponentiated.mapValues { $0 / normalizationFactor }
    }
}

nonisolated private enum ClassificationError: LocalizedError {
    case invalidImage
    case modelUnavailable
    case noResults

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "The selected image could not be read."
        case .modelUnavailable:
            return "The ingredient classifier model is unavailable."
        case .noResults:
            return "The model did not return any predictions."
        }
    }
}
