import SwiftUI

struct TopBrandBar: View {
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.94, green: 0.87, blue: 0.80), Color(red: 0.98, green: 0.96, blue: 0.94)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Image(systemName: "leaf.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.brandGreen)
            }
            .frame(width: 46, height: 46)

            Text("SiaDai")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.black)

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 18)
        .background(Color.white)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.black.opacity(0.04))
                .frame(height: 1)
        }
    }
}

#Preview {
    TopBrandBar()
}
