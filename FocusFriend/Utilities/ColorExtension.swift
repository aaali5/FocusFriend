import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var rgb: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&rgb)
        self.init(
            red: Double((rgb >> 16) & 0xFF) / 255.0,
            green: Double((rgb >> 8) & 0xFF) / 255.0,
            blue: Double(rgb & 0xFF) / 255.0
        )
    }

    // App color palette
    static let navyBg = Color(red: 0.04, green: 0.055, blue: 0.1)
    static let foxOrange = Color(hex: "#f97316")
    static let mysticPurple = Color(hex: "#7c3aed")
    static let spiritBlue = Color(hex: "#38bdf8")
    static let xpGold = Color(hex: "#fbbf24")
    static let bossRed = Color(hex: "#ef4444")
}

extension View {
    func glassCard() -> some View {
        self
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
    }
}
