import SwiftUI

struct BackgroundView: View {
    var body: some View {
        ZStack {
            Color("AppBackground")
                .ignoresSafeArea()

            RadialGradient(
                colors: [
                    Color("AppSecondary").opacity(0.18),
                    Color.clear
                ],
                center: .topLeading,
                startRadius: 10,
                endRadius: 520
            )
            .ignoresSafeArea()

            LinearGradient(
                colors: [
                    Color("AppPrimary").opacity(0.10),
                    Color.clear
                ],
                startPoint: .bottomTrailing,
                endPoint: .topLeading
            )
            .ignoresSafeArea()
        }
    }
}
