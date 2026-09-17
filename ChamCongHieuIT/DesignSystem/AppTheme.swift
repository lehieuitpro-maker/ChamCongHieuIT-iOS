import SwiftUI

enum AppTheme {
    static let indigo = Color(red: 0.27, green: 0.31, blue: 0.85)
    static let blue = Color(red: 0.12, green: 0.48, blue: 0.96)
    static let teal = Color(red: 0.05, green: 0.77, blue: 0.66)

    static let pageBackground = Color(uiColor: .systemGroupedBackground)
    static let cardBackground = Color(uiColor: .secondarySystemGroupedBackground)
    static let elevatedBackground = Color(uiColor: .systemBackground)
    static let border = Color.primary.opacity(0.07)

    static let brandGradient = LinearGradient(
        colors: [indigo, blue, teal],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let softBrandGradient = LinearGradient(
        colors: [indigo.opacity(0.14), teal.opacity(0.08)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

extension View {
    func appCard(padding: CGFloat = 16) -> some View {
        self
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(AppTheme.elevatedBackground)
                    .shadow(color: .black.opacity(0.05), radius: 12, y: 5)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(AppTheme.border, lineWidth: 1)
            }
    }
}

struct AppSectionHeader: View {
    let title: String
    let systemImage: String

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
            .textCase(nil)
    }
}

struct MetricItem: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.82))

            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Text(title)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.78))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

struct IconTile: View {
    let systemImage: String
    let tint: Color

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(tint)
            .frame(width: 36, height: 36)
            .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
    }
}

struct PrimaryActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(AppTheme.brandGradient, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .opacity(configuration.isPressed ? 0.82 : 1)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct TintedActionButtonStyle: ButtonStyle {
    let tint: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .background(tint.opacity(0.11), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

extension WorkStatus {
    var tintColor: Color {
        switch self {
        case .work:
            AppTheme.teal
        case .paidLeave:
            AppTheme.blue
        case .unpaidLeave:
            .orange
        case .holiday:
            .pink
        }
    }
}

