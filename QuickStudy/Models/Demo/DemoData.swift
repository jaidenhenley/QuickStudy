//
//  DemoData.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 1/21/26.
//

import Foundation

enum DemoData {
    /// `dueInDays` is relative to the seeding date, so samples never go stale.
    /// A nil value means the card has never been scheduled.
    struct CardSpec {
        let question: String
        let answer: String
        var box: Int = 0
        var dueInDays: Int? = 0
        var missCount: Int = 0
    }

    struct SetSpec {
        let title: String
        let lines: [String]
        let cards: [CardSpec]
    }

    static let sets: [SetSpec] = [higSet, swiftUISet, spriteKitSet, coreDataSet]

    // MARK: - Human Interface Guidelines — cards due today, and the weakest card

    private static let higSet = SetSpec(
        title: "Human Interface Guidelines",
        lines: higLines,
        cards: [
            CardSpec(question: "What is Deference?",
                     answer: "UI should support content, not compete with it.",
                     box: 1, dueInDays: 0, missCount: 3),
            CardSpec(question: "What is Clarity?",
                     answer: "Text, icons, and controls should be easy to understand.",
                     box: 3, dueInDays: 0),
            CardSpec(question: "What is Depth?",
                     answer: "Layers, motion, and sound provide hierarchy.",
                     box: 2, dueInDays: 0),
            CardSpec(question: "What is the minimum tap target size?",
                     answer: "44pt, for accessibility.",
                     box: 2, dueInDays: 0),
            CardSpec(question: "How should color be used?",
                     answer: "As a supplement, never as the only signal.",
                     box: 1, dueInDays: 0, missCount: 1),
            CardSpec(question: "What belongs in an empty state?",
                     answer: "A clear next action, not an apology.",
                     box: 3, dueInDays: 4),
            CardSpec(question: "Which user settings must a design respect?",
                     answer: "Dynamic Type and Reduce Motion.",
                     box: 2, dueInDays: 2),
            CardSpec(question: "When should you use SF Symbols?",
                     answer: "Wherever possible, for familiar iconography.",
                     box: 2, dueInDays: 6)
        ]
    )

    // MARK: - SwiftUI Essentials — fully mastered, drives the green tile

    private static let swiftUISet = SetSpec(
        title: "SwiftUI Essentials",
        lines: swiftuiLines,
        cards: [
            CardSpec(question: "What does declarative UI mean?",
                     answer: "You describe the UI and the system renders it.",
                     box: 5, dueInDays: 30),
            CardSpec(question: "What does @State store?",
                     answer: "Local view data that drives updates.",
                     box: 5, dueInDays: 30),
            CardSpec(question: "What does @Binding do?",
                     answer: "Passes writable state down to a child view.",
                     box: 5, dueInDays: 30),
            CardSpec(question: "What manages push navigation?",
                     answer: "NavigationStack.",
                     box: 5, dueInDays: 30),
            CardSpec(question: "When do LazyVStack and LazyVGrid load rows?",
                     answer: "On demand, as they scroll into view.",
                     box: 5, dueInDays: 30),
            CardSpec(question: "What is .task used for?",
                     answer: "Async work tied to a view's lifetime.",
                     box: 5, dueInDays: 30)
        ]
    )

    // MARK: - SpriteKit — the "Tomorrow" row in UP NEXT

    private static let spriteKitSet = SetSpec(
        title: "SpriteKit",
        lines: spriteKitLines,
        cards: [
            CardSpec(question: "What is SKScene?",
                     answer: "The root container for nodes and physics.",
                     box: 3, dueInDays: 1),
            CardSpec(question: "What does SKAction do?",
                     answer: "Animates nodes over time without timers.",
                     box: 3, dueInDays: 1),
            CardSpec(question: "What is SKEmitterNode for?",
                     answer: "Particle effects like sparks or smoke.",
                     box: 3, dueInDays: 1),
            CardSpec(question: "When does update(_:) run?",
                     answer: "Once per frame.",
                     box: 3, dueInDays: 1),
            CardSpec(question: "What is didMove(to:) for?",
                     answer: "Scene setup when the scene is presented.",
                     box: 3, dueInDays: 0),
            CardSpec(question: "What do physics categories do?",
                     answer: "Filter which bodies collide and generate contacts.",
                     box: 3, dueInDays: 0, missCount: 2)
        ]
    )

    // MARK: - Core Data — the "Thursday" row, plus unapproved drafts

    private static let coreDataSet = SetSpec(
        title: "Core Data",
        lines: coreDataLines,
        cards: [
            CardSpec(question: "What is a managed object context?",
                     answer: "A scratchpad for creating, fetching, and saving objects.",
                     box: 1, dueInDays: 3),
            CardSpec(question: "What does NSPersistentContainer set up?",
                     answer: "The model, the context, and the store coordinator.",
                     box: 1, dueInDays: 3),
            CardSpec(question: "What is a fetch request?",
                     answer: "A query describing which objects to load.",
                     dueInDays: nil),
            CardSpec(question: "What does a lightweight migration handle?",
                     answer: "Simple schema changes without custom code.",
                     dueInDays: nil)
        ]
    )

    // MARK: - Source text, used for quiz distractor generation

    static let coreDataLines: [String] = [
        "A managed object context is a scratchpad for creating, fetching, and saving objects.",
        "NSPersistentContainer sets up the model, context, and store coordinator.",
        "A fetch request describes which objects to load and how to sort them.",
        "Lightweight migration handles simple schema changes without custom code.",
        "Faulting delays loading an object's data until it is needed.",
        "Saving a context writes its pending changes to the persistent store."
    ]

    static let swiftuiLines: [String] = [
        "SwiftUI is declarative: you describe the UI, the system renders it.",
        "Views are value types composed with stacks, lists, and modifiers.",
        "@State stores local view data that drives updates.",
        "@Binding passes writable state to child views.",
        "NavigationStack manages push-style navigation.",
        "Use .task and async/await for simple async work.",
        "Use List for large, scrollable content with automatic cell reuse.",
        "LazyVStack and LazyVGrid load rows on demand.",
        "Use .sheet for modal presentation and .fullScreenCover for immersive flows.",
        "Animations are opt-in with withAnimation or .animation modifiers.",
        "Environment values like colorScheme and sizeCategory adapt UI automatically.",
        "Use .toolbar for navigation bar and bottom bar actions.",
        "Accessibility labels help VoiceOver describe controls.",
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
        "The scene's anchorPoint can shift the coordinate origin.",
        "Use texture filtering modes to control pixel art sharpness.",
        "SKAudioNode plays background audio in a scene.",
        "Use physics categories to filter collisions and contacts.",
        "SKConstraint can lock a node's position or rotation.",
        "Use scaleMode to control how scenes fit the view.",
        "Actions can be sequenced and repeated for complex behavior.",
        "Use child nodes to build composite objects.",
        "Physics joints connect two bodies for ropes or hinges.",
        "Use SKTransition for animated scene changes."
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
