import SwiftUI

struct Theme {
    static let background = Color("AppBackground")
    static let surface = Color("AppSurface")
    static let primary = Color("AppPrimary")
    static let secondary = Color("AppSecondary")
    static let aiAccent = Color("AppAIAccent")
    static let textPrimary = Color("AppTextPrimary")
    static let success = Color("AppSuccess")
    static let danger = Color("AppDanger")
    static let warning = Color("AppWarning")
    static let streak = Color("AppStreak")

    /// Text-safe variants of `aiAccent`/`danger`/`success` for use as foreground color
    /// on `Theme.background`. The base colors read as fills, badges, and icons; their
    /// light-mode values fail 4.5:1 as text, and darkening them in place would drop
    /// white-on-fill contrast below 3:1, so these are separate tokens instead.
    static let aiAccentText = Color("AppAIAccentText")
    static let dangerText = Color("AppDangerText")
    static let successText = Color("AppSuccessText")
}

private struct GlassCardModifier: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    let cornerRadius: CGFloat
    let tint: Color?

    func body(content: Content) -> some View {
        if reduceTransparency {
            content
                .background {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Theme.surface)
                        .overlay {
                            if let tint {
                                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                    .fill(tint.opacity(0.28))
                            }
                        }
                }
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.12), lineWidth: 1)
                }
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        } else if let tint {
            content.glassEffect(.regular.tint(tint), in: .rect(cornerRadius: cornerRadius))
        } else {
            content.glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
        }
    }
}

private struct ProminentButtonModifier: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    let tint: Color

    func body(content: Content) -> some View {
        if reduceTransparency {
            content
                .buttonStyle(.plain)
                .foregroundStyle(.white)
                .padding(.horizontal, Spacing.base)
                .padding(.vertical, Spacing.sm)
                .background {
                    RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                        .fill(tint)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                }
        } else {
            content
                .buttonStyle(.glassProminent)
                .tint(tint)
                .foregroundStyle(.white)
        }
    }
}

extension View {
    func appGlassCard(cornerRadius: CGFloat = 16, tint: Color? = nil) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius, tint: tint))
    }

    func appProminentButtonStyle(tint: Color) -> some View {
        modifier(ProminentButtonModifier(tint: tint))
    }
}
