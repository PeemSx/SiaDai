import SwiftUI
import UIKit

// MARK: - Recipe Artwork View (หน้าจอแสดงภาพปกเมนูอาหาร)
struct RecipeArtworkView: View {
    let recipe: RescueRecipe
    let sourceItems: [FoodItem]

    var body: some View {
        // ใช้ GeometryReader ดึงไซส์ของกรอบมาคำนวณขนาดภาพให้ยืดหยุ่นตามหน้าจอ
        GeometryReader { proxy in
            if let image = recipeImage {
                // เคสที่ 1: มีรูปวัตถุดิบจริง -> สั่งวาดรูปขยายให้เต็มกรอบพอดี
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
            } else {
                // เคสที่ 2: ไม่มีรูป -> ส่งไปวาดกราฟิกเวกเตอร์สวยๆ แทน (Fallback)
                fallbackArtwork(size: proxy.size)
            }
        }
        .clipped() // ดักตัดขอบรูปส่วนเกินไม่ให้ทะลุเฟรมออกไปข้างนอก
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

    // MARK: - Fallback Graphic UI (พาร์ทวาดกราฟิกพื้นหลังกรณีไม่มีรูป)
    @ViewBuilder
    private func fallbackArtwork(size: CGSize) -> some View {
        let style = RecipeArtworkStyle(styleSeed: styleSeed)

        ZStack {
            // เลเยอร์ที่ 1: พื้นหลังไล่เฉดสีกราเดียนต์ตามชนิดอาหาร
            LinearGradient(
                colors: style.colors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // เลเยอร์ที่ 2: ทำดวงไฟโกลว์ฟุ้งๆ วงที่หนึ่ง (เยื้องล่างขวา) เพิ่มมิติ
            Circle()
                .fill(style.glow.opacity(0.36))
                .frame(width: size.width * 0.78, height: size.width * 0.78)
                .blur(radius: 24)
                .offset(x: size.width * 0.18, y: size.height * 0.10)

            // เลเยอร์ที่ 3: แสงแฟลร์สีขาวจางๆ วงที่สอง (เยื้องบนซ้าย) ดันให้ภาพดูมีมิติไฮไลต์ขึ้น
            Circle()
                .fill(.white.opacity(0.08))
                .frame(width: size.width * 0.62, height: size.width * 0.62)
                .blur(radius: 18)
                .offset(x: -size.width * 0.12, y: -size.height * 0.14)

            // เลเยอร์ที่ 4: วาดไอคอนระบบ SF Symbol ตรงกลางจอ (คำนวณย่อขยายขนาดตามสัดส่วนกรอบอัตโนมัติ)
            Image(systemName: style.symbolName)
                .font(.system(size: min(size.width, size.height) * 0.32, weight: .regular))
                .foregroundStyle(.white.opacity(0.88))

            // เลเยอร์ที่ 5: เส้นกรอบสโตรกสีขาวบางๆ ครอบด้านในเพิ่มความพรีเมียมให้การ์ดเมนู
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

// MARK: - Style Mapping (พาร์ทจับคู่โทนสีและไอคอนตามคีย์เวิร์ดชื่ออาหาร)
private struct RecipeArtworkStyle {
    let colors: [Color]
    let glow: Color
    let symbolName: String

    init(styleSeed: String) {
        let lowercasedSeed = styleSeed.lowercased()

        // กลุ่มผักใบเขียว / ผักโขม -> สาดธีมเขียวธรรมชาติ + ไอคอนใบไม้
        if lowercasedSeed.contains("spinach") || lowercasedSeed.contains("leaf") {
            colors = [
                Color(red: 0.11, green: 0.16, blue: 0.20),
                Color(red: 0.26, green: 0.41, blue: 0.33)
            ]
            glow = Color(red: 0.34, green: 0.77, blue: 0.51)
            symbolName = "leaf.fill"
            return
        }

        // กลุ่มเนื้อปลา / แซลมอน -> สาดธีมส้มคอรัล+เทาเข้มปลาทะเล + ไอคอนปลา
        if lowercasedSeed.contains("salmon") || lowercasedSeed.contains("fish") {
            colors = [
                Color(red: 0.12, green: 0.16, blue: 0.19),
                Color(red: 0.28, green: 0.24, blue: 0.21)
            ]
            glow = Color(red: 0.92, green: 0.63, blue: 0.45)
            symbolName = "fish.fill"
            return
        }

        // กลุ่มนม / โยเกิร์ต -> สาดธีมฟ้านมสดซอฟต์ๆ + ไอคอนหยดน้ำ
        if lowercasedSeed.contains("milk") || lowercasedSeed.contains("yogurt") {
            colors = [
                Color(red: 0.09, green: 0.13, blue: 0.17),
                Color(red: 0.26, green: 0.28, blue: 0.32)
            ]
            glow = Color(red: 0.71, green: 0.81, blue: 0.93)
            symbolName = "drop.fill"
            return
        }

        // กลุ่มผลไม้ / แอปเปิ้ล -> สาดธีมน้ำตาลวอร์มโทนอุ่น + ไอคอนตะกร้าใส่ผลไม้
        if lowercasedSeed.contains("apple") {
            colors = [
                Color(red: 0.18, green: 0.16, blue: 0.12),
                Color(red: 0.34, green: 0.24, blue: 0.14)
            ]
            glow = Color(red: 0.98, green: 0.72, blue: 0.42)
            symbolName = "basket.fill"
            return
        }

        // กลุ่มอาหารทั่วไปอื่นๆ (Default) -> สาดธีมเขียวแบรนด์เนล+ช้อนส้อมคลาสสิก
        colors = [
            Color(red: 0.13, green: 0.18, blue: 0.18),
            Color(red: 0.19, green: 0.32, blue: 0.29)
        ]
        glow = Color(red: 0.44, green: 0.79, blue: 0.62)
        symbolName = "fork.knife"
    }
}
