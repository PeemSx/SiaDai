import SwiftUI
import SwiftData

struct WasteJarView: View {
    @Query private var allFoodItems: [FoodItem]
    @State private var viewModel = WasteJarViewModel()

    private var trashedItems: [FoodItem] {
        viewModel.trashedItems(from: allFoodItems)
    }

    private var totalLostThisMonth: Double {
        viewModel.totalLostThisMonth(from: allFoodItems)
    }

    private var chartData: [WasteData] {
        viewModel.chartData(from: allFoodItems)
    }

    private var selectedMonthTitle: String {
        viewModel.selectedMonthTitle
    }

    private var canGoForwardMonth: Bool {
        viewModel.canGoForwardMonth()
    }

    private var trendMessage: String {
        viewModel.trendMessage(from: allFoodItems)
    }

    private var trendColor: Color {
        viewModel.trendColor(from: allFoodItems)
    }

    private var summaryTitle: String {
        viewModel.summaryTitle
    }

    // MARK: - Main UI Layout
    var body: some View {
        ZStack {
            // แปะสีกราวด์พื้นหลังแอปเต็มจอ
            Color.screenBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Color.white
                    .frame(height: 0)
                    .ignoresSafeArea(edges: .top)

                // แถบบาร์โลโก้แบรนด์ด้านบนสุด
                TopBrandBar()

                // ส่วนสถิติภาพรวมเลื่อนขึ้นลงได้
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        summaryHeader       // ส่วนพาดหัวสรุปยอดเงินบิลรวมที่เสียไป
                        
                        WasteChartView(     // ส่วนบล็อกกล่องแสดงกราฟแท่งรายสัปดาห์
                            data: chartData,
                            monthTitle: selectedMonthTitle,
                            canGoForward: canGoForwardMonth,
                            onPreviousMonth: { viewModel.showPreviousMonth() },
                            onNextMonth: { viewModel.showNextMonth() }
                        )

                        earthImpactCard     // การ์ดเปรียบเทียบสิ่งของแทงใจกระตุ้นความเสียดาย

                        trashedItemsSection // เซกชันลิสต์รายการของกินที่กลายเป็นขยะแล้ว
                    }
                    // เว้นระยะขอบ Padding (ด้านล่างเว้นระยะหนาหน่อยเอาไว้หลบแถบ Tab Bar)
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 160)
                }
            }
        }
    }

    // MARK: - Summary Header UI (ส่วนหัวพาดข่าวยอดบิลรวมประจำเดือน)
    private var summaryHeader: some View {
        VStack(spacing: 8) {
            Text(summaryTitle)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.secondary.opacity(0.6))
                .tracking(1.2)

            // ยอดเงินบาทขนาดใหญ่พาดกลางจอชัดๆ
            Text(String(format: "฿%.2f", totalLostThisMonth))
                .font(.system(size: 72, weight: .bold))
                .foregroundStyle(.black)

            // แท็กแคปซูลเม็ดเล็กด้านล่าง บอกสถิติแนวโน้มว่าทิ้งขยะดีขึ้นหรือแย่ลงกว่าเดิม
            HStack(spacing: 6) {
                Circle()
                    .fill(trendColor)
                    .frame(width: 8, height: 8)
                
                Text(trendMessage)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(trendColor)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(trendColor.opacity(0.12), in: Capsule())
        }
    }

    // MARK: - Trashed Items UI (ส่วนตารางรายชื่อวัตถุดิบที่โยนทิ้งลงถัง)
    private var trashedItemsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Trashed Items")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.black)
            }

            VStack(spacing: 16) {
                if trashedItems.isEmpty {
                    // เคสถังขยะว่างเปล่า: แสดงข้อความบอกสภาวะโล่งสีเทาๆ
                    Text("No waste items logged yet.")
                        .foregroundStyle(.secondary)
                        .padding()
                } else {
                    // เคสมีข้อมูลอาหารขยะ: วนลูปสาดวาดแถวลิสต์รายการออกมาทีละแถว
                    ForEach(trashedItems, id: \.id) { item in
                        trashedRow(for: item)
                    }
                }
            }
        }
    }

    // รูปแบบดีไซน์แถวเดี่ยวของรายการอาหารขยะย่อยๆ
    private func trashedRow(for item: FoodItem) -> some View {
        return HStack(spacing: 16) {
            // ทำกล่องสี่เหลี่ยมมนมน แปะไอคอนใบไม้สีเทาจางๆ ไว้ด้านหน้าสุด
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.black.opacity(0.03))
                    .frame(width: 64, height: 64)
                
                Image(systemName: "leaf.fill")
                    .font(.title2)
                    .foregroundStyle(.black.opacity(0.7))
            }

            // แสดงชื่อวัตถุดิบคู่กับรายละเอียดปริมาณและยอดบิลเสียหายข้างใต้
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.black)

                Text("\(viewModel.amountLabel(for: item)) • \(viewModel.currencyString(for: item.purchaseValue))")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // ไอคอนลูกศรชี้ขวา (Chevron) จางๆ ปิดท้ายแถวบ่งบอกว่ากดคลิกเปิดดูได้
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.secondary.opacity(0.5))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .cardShadow, radius: 12, x: 0, y: 8)
    }

    // MARK: - Earth Impact UI (การ์ดแสดงผลเปรียบเทียบมูลค่าความเสียดายแบบแทงใจ)
    private var earthImpactCard: some View {
        let impact = getRelatableImpact(for: totalLostThisMonth)

        return VStack(alignment: .leading, spacing: 16) {
            Text("EARTH IMPACT")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(Color.brandGreen)
                .tracking(1.2)

            // จัด Text บวกประกบสายอักษร (เอาส่วนข้อความหนาพิเศษ มาต่อพ่วงสาดรวมกับข้อความปกติ)
            VStack(alignment: .leading, spacing: 8) {
                Text(impact.boldText.prefix(1).uppercased() + impact.boldText.dropFirst())
                    .foregroundStyle(.black)
                    .fontWeight(.bold) +
                Text(impact.normalTail)
                    .foregroundStyle(.black.opacity(0.6))
            }
            .font(.system(size: 18, design: .rounded))
            .lineSpacing(4)
        }
        .padding(32)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack(alignment: .bottomTrailing) {
                Color.white
                
                // ลายน้ำรูปไอคอนระบบจางๆ หมุนเยื้องอยู่ตรงมุมล่างขวาของการ์ดเพิ่มลูกเล่นความสวยงาม
                Image(systemName: impact.icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120)
                    .foregroundStyle(Color.brandGreen.opacity(0.06))
                    .rotationEffect(.degrees(-15))
                    .offset(x: 20, y: 20)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .shadow(color: .cardShadow, radius: 20, x: 0, y: 12)
    }

    private func getRelatableImpact(for amount: Double) -> (boldText: String, normalTail: String, icon: String) {
        if amount <= 0 {
            return ("haven't wasted anything!", " You're doing amazing! You saved the planet and 100% of your money.", "star.fill")
        } else if amount < 100 {
            return ("a cup of bubble tea or a sweet snack", " that you love to enjoy. Try planning your meals better next week!", "cup.and.saucer.fill")
        } else if amount < 500 {
            let times = Int(amount / 219)
            let timesText = times <= 1 ? "once" : "\(times) times"
            return ("eat Shabu Teenoi \(timesText)!", " instead of tossing food into the trash. What a waste!", "fork.knife")
        } else if amount < 5000 {
            return ("host a Moo Kra Tha party for your entire squad", " easily. This money could have brought so much more joy to your life.", "person.3.sequence.fill")
        } else if amount < 30000 {
            return ("a brand new pair of AirPods Pro", " for free. Maybe check your fridge a bit more thoroughly next time.", "airpodsmax")
        } else {
            return ("buy a brand new iPhone", " right now! The value of your wasted food has accumulated into something huge.", "iphone")
        }
    }
}

#Preview {
    WasteJarView()
        .modelContainer(PreviewHelper.previewContainer)
}
