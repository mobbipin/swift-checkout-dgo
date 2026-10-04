import SwiftUI

extension Color {
    /// ARGB, matching the Android `0xAARRGGBB` literals.
    init(argb: UInt32) {
        self.init(
            .sRGB,
            red: Double((argb >> 16) & 0xFF) / 255,
            green: Double((argb >> 8) & 0xFF) / 255,
            blue: Double(argb & 0xFF) / 255,
            opacity: Double((argb >> 24) & 0xFF) / 255
        )
    }

    static let ink = Color(argb: 0xFF08050F)
    static let surface = Color(argb: 0xFF09060F)
    static let brandPurple = Color(argb: 0xFF8A3FFC)
    static let brandPink = Color(argb: 0xFFFF00BD)
    static let brandOrange = Color(argb: 0xFFFF4D00)
    static let stripePurple = Color(argb: 0xFF635BFF)
    static let devLime = Color(argb: 0xFFA3E635)
    static let emerald = Color(argb: 0xFF6EE7B7)
    static let danger = Color(argb: 0xFFFCA5A5)
    static let amber = Color(argb: 0xFFFCD34D)
    static let mint = Color(argb: 0xFFA7F3D0)
    static let rose = Color(argb: 0xFFFECACA)
}

enum Brand {
    static let gradient = LinearGradient(
        colors: [.brandPurple, .brandPink, .brandOrange],
        startPoint: .leading,
        endPoint: .trailing
    )
    static let ringGradient = AngularGradient(
        colors: [.brandPurple, .brandPink, .brandOrange, .brandPurple],
        center: .center
    )
}

extension View {
    func white(_ opacity: Double) -> some View { foregroundStyle(Color.white.opacity(opacity)) }

    /// Rounded fill + hairline border, the most common surface in the Compose UI.
    func card(_ radius: CGFloat, fill: some ShapeStyle, stroke: Color) -> some View {
        background(fill, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).strokeBorder(stroke, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }

    func capsuleCard(fill: some ShapeStyle, stroke: Color) -> some View {
        background(fill, in: Capsule())
            .overlay(Capsule().strokeBorder(stroke, lineWidth: 1))
    }
}

extension Font {
    static func dgo(_ size: CGFloat, _ weight: Font.Weight = .regular, mono: Bool = false) -> Font {
        .system(size: size, weight: weight, design: mono ? .monospaced : .default)
    }
}
