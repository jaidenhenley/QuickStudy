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
}

extension View {
    @ViewBuilder
    func appGlassCard(cornerRadius: CGFloat = 16, tint: Color? = nil) -> some View {
        if let tint {
            self.glassEffect(.regular.tint(tint), in: .rect(cornerRadius: cornerRadius))
        } else {
            self.glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
        }
    }

    @ViewBuilder
    func appProminentButtonStyle(tint: Color) -> some View {
        self.buttonStyle(.glassProminent)
            .tint(tint)
            .foregroundStyle(.white)
    }
}
