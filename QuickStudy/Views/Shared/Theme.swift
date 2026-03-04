import SwiftUI

struct Theme {
    static let background = Color("AppBackground")
    static let surface = Color("AppSurface")
    static let primary = Color("AppPrimary")
    static let secondary = Color("AppSecondary")
    static let aiAccent = Color("AppAIAccent")
    static let textPrimary = Color("AppTextPrimary")
}

extension View {
    @ViewBuilder
    func appGlassCard(cornerRadius: CGFloat = 16) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
        } else {
            self
                .padding(0)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
        }
    }

    @ViewBuilder
    func appProminentButtonStyle(tint: Color) -> some View {
        if #available(iOS 26.0, *) {
            self.buttonStyle(.glassProminent)
                .tint(tint)
                .foregroundStyle(.white)
        } else {
            self.buttonStyle(.borderedProminent)
                .tint(tint)
                .foregroundStyle(.white)
        }
    }
}
