import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    static let primaryContainer = Color(hex: "#00204A")
    static let ibmecPrimary = Color(hex: "#000A1F")
    static let secondaryFixed = Color(hex: "#DAE2F9")
    static let surface = Color(hex: "#FAF9FD")
    static let outline = Color(hex: "#747780")
    static let successGreen = Color(hex: "#22C55E")
    static let error = Color(hex: "#BA1A1A")

    // Brand tokens (Stitch "IBMEC Transporte")
    static let ibmecBlue = Color(hex: "#002555")
    static let ibmecBlueDeep = Color(hex: "#001D44")
    static let ibmecAccent = Color(hex: "#F5AC00")
    static let ibmecField = Color(hex: "#F9FAFB")
    static let ibmecBorder = Color(hex: "#E5E7EB")
    static let ibmecText = Color(hex: "#333333")

    // Superfícies/cinzas centralizados (mesmos valores que estavam soltos nas telas)
    static let ibmecBackground = Color(hex: "#F3F4F6")
    static let ibmecSurfaceAlt = Color(hex: "#F8FAFC")
    static let ibmecCardBorder = Color(hex: "#EEF0F3")
    static let ibmecCardBorderLight = Color(hex: "#F0F0F0")
    static let ibmecHairline = Color(hex: "#E2E8F0")
    static let ibmecSlate = Color(hex: "#1E293B")
    static let ibmecSlateTint = Color(hex: "#F1F5F9")
    static let ibmecBlueGradientEnd = Color(hex: "#003B8A")
    static let ibmecPrimaryFixed = Color(hex: "#D7E2FF")
}
