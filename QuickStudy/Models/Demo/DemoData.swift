//
//  DemoData.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 1/21/26.
//

import Foundation

/// The single sample set. It is built like a real generated set (a two-page source,
/// and cards that each carry a source, an explanation and distractors) so the demo
/// shows the source pills, the Why card and Scan Preview paging exactly as they work
/// for the user's own notes.
enum DemoData {
    /// `dueInDays` is relative to the seeding date, so the sample never goes stale.
    /// `page` and `paragraph` are 1-based; each source line is one paragraph.
    struct CardSpec {
        let question: String
        let answer: String
        let explanation: String
        let distractors: [String]
        let page: Int
        let paragraph: Int
        var box: Int = 1
        var dueInDays: Int? = 0
        var missCount: Int = 0
    }

    struct SetSpec {
        let title: String
        let pages: [[String]]
        let cards: [CardSpec]

        var lines: [String] { pages.flatMap { $0 } }

        var pageBreaks: [Int] {
            pages.indices.map { index in pages[..<index].reduce(0) { $0 + $1.count } }
        }

        func source(for card: CardSpec) -> CardSource {
            let line = pageBreaks[card.page - 1] + card.paragraph - 1
            return CardSource(
                documentTitle: title,
                page: card.page,
                paragraph: card.paragraph,
                lineRange: line...line,
                excerpt: lines[line]
            )
        }
    }

    static let set = SetSpec(
        title: "Photosynthesis",
        pages: [
            [
                "Photosynthesis is the process plants, algae, and some bacteria use to turn light energy into chemical energy stored in glucose.",
                "It takes place in chloroplasts, organelles found mostly in the cells of a leaf's mesophyll layer.",
                "Chlorophyll is the green pigment inside chloroplasts. It absorbs red and blue light and reflects green light, which is why leaves look green.",
                "The overall equation is 6CO2 + 6H2O + light energy → C6H12O6 + 6O2.",
                "Carbon dioxide enters the leaf through small pores called stomata, and water is carried up from the roots through the xylem."
            ],
            [
                "Photosynthesis happens in two stages: the light-dependent reactions and the Calvin cycle.",
                "The light-dependent reactions take place in the thylakoid membranes. They split water, release oxygen, and produce ATP and NADPH.",
                "The oxygen released by photosynthesis comes from the water molecules that are split, not from carbon dioxide.",
                "The Calvin cycle takes place in the stroma. It uses ATP and NADPH to fix carbon dioxide into sugar.",
                "The rate of photosynthesis depends on light intensity, carbon dioxide concentration, and temperature."
            ]
        ],
        cards: [
            // MARK: Due today: fills TODAY'S SESSION
            CardSpec(
                question: "Where in the cell does photosynthesis take place?",
                answer: "In the chloroplasts.",
                explanation: "Chloroplasts hold the chlorophyll and membranes that capture light, so the whole process runs inside them.",
                distractors: ["In the mitochondria.", "In the nucleus.", "In the ribosomes."],
                page: 1, paragraph: 2
            ),
            // The weakest card: the most misses drives WEAKEST CARD on Today.
            CardSpec(
                question: "What is chlorophyll?",
                answer: "The green pigment that absorbs red and blue light to power photosynthesis.",
                explanation: "Chlorophyll captures light energy. The green light it reflects is why leaves look green.",
                distractors: [
                    "The sugar a plant stores for energy.",
                    "A pigment that absorbs green light and reflects red light.",
                    "The tissue that carries water up from the roots."
                ],
                page: 1, paragraph: 3, box: 1, missCount: 2
            ),
            CardSpec(
                question: "What are the products of photosynthesis?",
                answer: "Glucose and oxygen.",
                explanation: "The equation ends in C6H12O6 and 6O2: sugar the plant keeps and oxygen it releases.",
                distractors: ["Carbon dioxide only.", "Glucose and water.", "Water and oxygen."],
                page: 1, paragraph: 4, missCount: 1
            ),
            CardSpec(
                question: "How does carbon dioxide get into a leaf?",
                answer: "Through small pores called stomata.",
                explanation: "Stomata open on the leaf surface so gases can move in and out.",
                distractors: ["Through the roots, with water.", "Through the bark of the stem.", "Through the chloroplast membrane."],
                page: 1, paragraph: 5, box: 2
            ),
            CardSpec(
                question: "What are the two stages of photosynthesis?",
                answer: "The light-dependent reactions and the Calvin cycle.",
                explanation: "The light reactions capture energy, and the Calvin cycle spends it building sugar.",
                distractors: [
                    "Glycolysis and the Krebs cycle.",
                    "Interphase and the stages of mitosis.",
                    "Transcription and then translation of DNA."
                ],
                page: 2, paragraph: 1
            ),

            // MARK: Upcoming: fills UP NEXT
            CardSpec(
                question: "Where do the light-dependent reactions happen?",
                answer: "In the thylakoids.",
                explanation: "The thylakoids hold the chlorophyll that captures light, so the light reactions run there.",
                distractors: ["In the stroma.", "In the cytoplasm.", "In the stomata."],
                page: 2, paragraph: 2, box: 2, dueInDays: 1
            ),
            CardSpec(
                question: "Where does the oxygen released by photosynthesis come from?",
                answer: "From water molecules that are split.",
                explanation: "Splitting water in the light reactions frees the oxygen. The carbon from carbon dioxide ends up in sugar instead.",
                distractors: [
                    "From carbon dioxide taken in by the leaf.",
                    "From glucose broken down in the cell.",
                    "From the air inside the stomata."
                ],
                page: 2, paragraph: 3, box: 3, dueInDays: 1
            ),
            CardSpec(
                question: "What does the Calvin cycle produce?",
                answer: "Sugar, built from carbon dioxide.",
                explanation: "It uses the ATP and NADPH made by the light reactions to fix carbon dioxide into sugar.",
                distractors: [
                    "Oxygen, released from water.",
                    "ATP and NADPH for the light reactions.",
                    "Chlorophyll for capturing more light."
                ],
                page: 2, paragraph: 4, box: 3, dueInDays: 3
            ),
            CardSpec(
                question: "Which three factors affect the rate of photosynthesis?",
                answer: "Light intensity, carbon dioxide concentration, and temperature.",
                explanation: "Each is an input or condition the reactions depend on, so a shortage of any one slows the whole process.",
                distractors: [
                    "Soil type, leaf color, and plant height.",
                    "Oxygen level, glucose level, and leaf size.",
                    "Day length, root depth, and humidity."
                ],
                page: 2, paragraph: 5, box: 3, dueInDays: 5
            ),

            // MARK: Mastered: drives the mastered count in Stats
            CardSpec(
                question: "What is photosynthesis?",
                answer: "Turning light energy into chemical energy stored in glucose.",
                explanation: "Plants capture sunlight and store its energy in the bonds of a sugar they can use later.",
                distractors: [
                    "Breaking down glucose to release energy.",
                    "Absorbing water through the roots.",
                    "Releasing carbon dioxide into the air."
                ],
                page: 1, paragraph: 1, box: 5, dueInDays: 30
            )
        ]
    )
}
