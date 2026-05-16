import SwiftUI
import UIKit

struct FoodCardView: View {
    let item: FoodItem

    private var daysRemaining: Int {
        Date().daysUntil(item.expiryDate)
    }

    private var borderColor: Color {
        switch daysRemaining {
        case ...0:
            return .statusCrimson
        case 1...3:
            return .statusAmber
        default:
            return .statusEmerald
        }
    }

    private var fallbackPalette: [Color] {
        let lowercasedName = item.name.lowercased()

        if lowercasedName.contains("salmon") {
            return [Color(red: 0.10, green: 0.13, blue: 0.15), Color(red: 0.28, green: 0.17, blue: 0.14)]
        }
        if lowercasedName.contains("milk") {
            return [Color(red: 0.31, green: 0.24, blue: 0.16), Color(red: 0.08, green: 0.09, blue: 0.12)]
        }
        if lowercasedName.contains("spinach") {
            return [Color(red: 0.12, green: 0.18, blue: 0.16), Color(red: 0.24, green: 0.32, blue: 0.28)]
        }
        if lowercasedName.contains("apple") {
            return [Color(red: 0.25, green: 0.25, blue: 0.28), Color(red: 0.17, green: 0.18, blue: 0.20)]
        }
        return [Color(red: 0.14, green: 0.22, blue: 0.20), Color(red: 0.10, green: 0.16, blue: 0.15)]
    }

    private var fallbackSymbolName: String {
        let lowercasedName = item.name.lowercased()

        if lowercasedName.contains("salmon") || lowercasedName.contains("fish") {
            return "fish.fill"
        }
        if lowercasedName.contains("milk") {
            return "drop.fill"
        }
        if lowercasedName.contains("spinach") || lowercasedName.contains("leaf") {
            return "leaf.fill"
        }
        if lowercasedName.contains("apple") {
            return "basket.fill"
        }
        return "carrot.fill"
    }

    // MARK: - Main UI Layout
    var body: some View {
        VStack(spacing: 0) {
            // โซนรูปภาพด้านบน ล็อกความสูงไว้เท่ากันทุกใบ
            imageSection
                .frame(maxWidth: .infinity)
                .frame(height: 178)

            // โซนกล่องข้อความรายละเอียดด้านล่าง
            VStack(alignment: .leading, spacing: 10) {
                // ตัวหนังสือหัวข้อแจ้งเตือนวันหมดอายุ (สลับสีตามดีกรีความด่วน)
                Text(item.expiryDate.watchlistStatusHeadline())
                    .font(.caption.weight(.bold))
                    .tracking(0.9)
                    .foregroundStyle(borderColor)

                // ชื่อวัตถุดิบ (ล็อกไว้สูงสุด 2 บรรทัดป้องกันฟอนต์ดันกันจนเลย์เอาต์เบี้ยว)
                Text(item.name)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.black)
                    .lineLimit(2)

                // แสดงปริมาณอาหาร
                Text(FoodQuantityFormatter.string(amount: item.amount, unit: item.unit))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.black.opacity(0.72))
                    .tracking(0.4)

                // วันที่ระบุวันหมดอายุจริงสีเทาจางๆ
                Text(item.expiryDate.watchlistDateLabel())
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                    .tracking(1.2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(Color.white)
        }
        .frame(maxWidth: .infinity)
        .background(Color.white)
        // ตัดมุมมนรอบตัวการ์ดทั้งหมด พร้อมตบเส้นขอบหนา 4px ไฮไลต์ตามเฉดสีกลุ่มความด่วน
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(borderColor, lineWidth: 4)
        }
        .shadow(color: .cardShadow, radius: 18, x: 0, y: 12)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Thumbnail Image Subview
    @ViewBuilder
    private var imageSection: some View {
        GeometryReader { proxy in
            if let imageData = item.imageData, let image = UIImage(data: imageData) {
                // เคสมีรูปจริง: ดึงรูปมาขยายสเกลวางให้เต็มกรอบพอดี
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
            } else {
                // เคสไม่มีรูป: สาดกราเดียนต์สีพื้นหลังคู่กับไอคอนอาหารแก้ขัดแทน
                ZStack {
                    LinearGradient(
                        colors: fallbackPalette,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    // ทำดวงไฟทรงกลมโกลว์ฟุ้งๆ ซ่อนไว้ข้างหลังไอคอนเพิ่มมิติแสงเงา
                    Circle()
                        .fill(borderColor.opacity(0.24))
                        .frame(width: 140, height: 140)
                        .blur(radius: 12)
                        .offset(x: 44, y: 34)

                    // ไอคอน SF Symbol ตรงกลางตามประเภทคีย์เวิร์ดอาหาร
                    Image(systemName: fallbackSymbolName)
                        .font(.system(size: 66, weight: .regular))
                        .foregroundStyle(.white.opacity(0.92))

                    // เส้นขอบสโตรกสีขาวบางๆ ครอบขอบในเพิ่มความพรีเมียม
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(.white.opacity(0.12), lineWidth: 1.5)
                        .padding(18)
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
            }
        }
        .clipped() // ตัดส่วนหัวรูปภาพที่ล้นเฟรมออกไปทิ้ง
    }
}

#Preview {
    FoodCardView(item: PreviewHelper.sampleFoodItems[0])
        .padding()
        .background(Color.screenBackground)
}
