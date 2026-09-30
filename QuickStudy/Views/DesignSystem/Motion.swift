import SwiftUI

enum Motion {
    static let standard: Animation = .smooth(duration: 0.35)
    static let snappy: Animation = .snappy(duration: 0.25)
    static let emphasized: Animation = .spring(duration: 0.5, bounce: 0.2)
    static let crossfade: Animation = .easeInOut(duration: 0.2)
    static let countUp: Animation = .easeOut(duration: 0.6)
    static let shimmer: Animation = .easeInOut(duration: 0.9)
    static let progressTick: Animation = .linear(duration: 0.25)
    static let staggerStep: Double = 0.04

    static func staggered(_ index: Int) -> Animation {
        standard.delay(Double(min(index, 8)) * staggerStep)
    }
}

private struct AppAnimationModifier<Value: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let animation: Animation
    let value: Value

    func body(content: Content) -> some View {
        content.animation(reduceMotion ? Motion.crossfade : animation, value: value)
    }
}

private struct AppTransitionModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let transition: AnyTransition

    // Reduce Motion substitutes a crossfade; dropping the transition entirely reintroduces a hard cut.
    func body(content: Content) -> some View {
        content.transition(reduceMotion ? .opacity : transition)
    }
}

private struct StagedRevealModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let index: Int
    let shown: Bool

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown || reduceMotion ? 0 : 12)
            .animation(reduceMotion ? Motion.crossfade : Motion.staggered(index), value: shown)
    }
}

extension View {
    func appStagedReveal(_ index: Int, shown: Bool) -> some View {
        modifier(StagedRevealModifier(index: index, shown: shown))
    }

    func appAnimation<Value: Equatable>(_ animation: Animation = Motion.standard, value: Value) -> some View {
        modifier(AppAnimationModifier(animation: animation, value: value))
    }

    func appTransition(_ transition: AnyTransition) -> some View {
        modifier(AppTransitionModifier(transition: transition))
    }
}
