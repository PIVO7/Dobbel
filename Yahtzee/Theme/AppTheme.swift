import SwiftUI

enum AppTheme {
    static let felt = Color(red: 0.08, green: 0.42, blue: 0.30)
    static let feltDeep = Color(red: 0.04, green: 0.28, blue: 0.20)
    static let feltLight = Color(red: 0.14, green: 0.52, blue: 0.38)
    static let cream = Color(red: 0.99, green: 0.97, blue: 0.92)
    static let ink = Color(red: 0.12, green: 0.14, blue: 0.16)
    static let coral = Color(red: 0.93, green: 0.38, blue: 0.28)
    static let gold = Color(red: 0.96, green: 0.76, blue: 0.16)
    static let sky = Color(red: 0.28, green: 0.66, blue: 0.82)
    static let held = Color(red: 0.98, green: 0.88, blue: 0.32)
    static let lime = Color(red: 0.55, green: 0.82, blue: 0.28)

    static let titleFont = Font.system(size: 40, weight: .heavy, design: .rounded)
    static let brandFont = Font.system(size: 64, weight: .heavy, design: .rounded)
    static let headlineFont = Font.system(.title2, design: .rounded).weight(.bold)
    static let bodyFont = Font.system(.body, design: .rounded).weight(.semibold)
    static let captionFont = Font.system(.caption, design: .rounded).weight(.bold)

    static let springSnappy = Animation.spring(response: 0.38, dampingFraction: 0.68)
    static let springBouncy = Animation.spring(response: 0.48, dampingFraction: 0.58)
    static let springSoft = Animation.spring(response: 0.55, dampingFraction: 0.78)

    static let menuAccents: [Color] = [coral, sky, gold]
}

struct FeltBackground: View {
    var showPattern: Bool = true

    var body: some View {
        LinearGradient(
            colors: [AppTheme.feltLight, AppTheme.felt, AppTheme.feltDeep],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        .overlay {
            if showPattern {
                DicePattern()
                    .opacity(0.10)
                    .ignoresSafeArea()
            }
        }
        .overlay {
            RadialGradient(
                colors: [AppTheme.gold.opacity(0.12), .clear],
                center: .top,
                startRadius: 20,
                endRadius: 320
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)
        }
    }
}

struct DicePattern: View {
    var body: some View {
        Canvas { context, size in
            let step: CGFloat = 64
            for x in stride(from: 0, through: size.width, by: step) {
                for y in stride(from: 0, through: size.height, by: step) {
                    let rect = CGRect(x: x + 8, y: y + 10, width: 16, height: 16)
                    var path = Path(roundedRect: rect, cornerRadius: 4)
                    context.fill(path, with: .color(.white))
                }
            }
        }
    }
}

struct PopButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(AppTheme.springSnappy, value: configuration.isPressed)
    }
}
