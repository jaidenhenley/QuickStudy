//
//  DemoData.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 1/21/26.
//

import Foundation

enum DemoData {
    static let swiftuiLines: [String] = [
        "SwiftUI is declarative: you describe the UI, the system renders it.",
        "Views are value types composed with stacks, lists, and modifiers.",
        "@State stores local view data that drives updates.",
        "@Binding passes writable state to child views.",
        "NavigationStack manages push-style navigation.",
        "Use .task and async/await for simple async work.",
        "@StateObject keeps reference types alive across renders.",
        "@ObservedObject is used when the view does not own the model.",
        "Use List for large, scrollable content with automatic cell reuse.",
        "LazyVStack and LazyVGrid load rows on demand.",
        "Use .sheet for modal presentation and .fullScreenCover for immersive flows.",
        "Animations are opt-in with withAnimation or .animation modifiers.",
        "Environment values like colorScheme and sizeCategory adapt UI automatically.",
        "Use .toolbar for navigation bar and bottom bar actions.",
        "Accessibility labels help VoiceOver describe controls.",
        "@EnvironmentObject shares state across many views.",
        "Use PreviewProvider for lightweight UI previews.",
        "Forms are great for grouped settings and inputs.",
        "Use .navigationDestination for type-safe navigation in NavigationStack.",
        "Modifiers are applied from top to bottom and can be combined.",
        "Use GeometryReader sparingly for layout measurements."
    ]

    static let spriteKitLines: [String] = [
        "SKScene is the root container for nodes and physics.",
        "SKNode forms a tree; position and zPosition control layout.",
        "SKSpriteNode draws textures; use atlases for performance.",
        "SKAction animates nodes over time without timers.",
        "Physics bodies enable collisions and contact events.",
        "Use SKCameraNode to move the view around the scene.",
        "SKLabelNode draws text labels in the scene.",
        "SKEmitterNode creates particle effects like sparks or smoke.",
        "Use update(_:) for per-frame logic.",
        "Use didMove(to:) for scene setup.",
        "The scene’s anchorPoint can shift the coordinate origin.",
        "Use texture filtering modes to control pixel art sharpness.",
        "SKAudioNode plays background audio in a scene.",
        "Use physics categories to filter collisions and contacts.",
        "SKConstraint can lock a node’s position or rotation.",
        "Use scaleMode to control how scenes fit the view.",
        "Actions can be sequenced and repeated for complex behavior.",
        "Use child nodes to build composite objects.",
        "Physics joints connect two bodies for ropes or hinges.",
        "Use SKTransition for animated scene changes.",
        "Use view?.showsPhysics to debug collisions."
    ]

    static let higLines: [String] = [
        "Clarity: text, icons, and controls should be easy to understand.",
        "Deference: UI should support content, not compete with it.",
        "Depth: use layers, motion, and sound to provide hierarchy.",
        "Make tap targets at least 44pt for accessibility.",
        "Use system colors and typography for consistency.",
        "Prefer plain language in buttons and alerts.",
        "Keep navigation predictable and easy to back out of.",
        "Use SF Symbols where possible for familiar iconography.",
        "Group related content with spacing and section headers.",
        "Avoid excessive custom controls unless necessary.",
        "Use loading states and progress indicators for long tasks.",
        "Provide helpful empty states with a clear next action.",
        "Respect user settings like Dynamic Type and Reduce Motion.",
        "Use haptics sparingly to confirm key actions.",
        "Prefer platform-standard gestures like swipe to delete.",
        "Provide clear error messages with recovery steps.",
        "Keep terminology consistent across the app.",
        "Design for one-handed reachability on iPhone.",
        "Use color as a supplement, not the only signal.",
        "Avoid too much text on small screens; use progressive disclosure.",
        "Balance visual density to avoid clutter."
    ]
}
