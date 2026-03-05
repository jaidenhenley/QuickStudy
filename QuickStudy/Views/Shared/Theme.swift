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
        self.glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
    }

    @ViewBuilder
    func appProminentButtonStyle(tint: Color) -> some View {
        self.buttonStyle(.glassProminent)
            .tint(tint)
            .foregroundStyle(.white)
    }
}
