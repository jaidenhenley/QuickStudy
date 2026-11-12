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
/// for the user's own notes. It is localized, so changing the iPhone's language
/// replaces it with the sample in the new language on the next launch.
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
        title: String(localized: "Photosynthesis", table: "SampleSet"),
        pages: [
            [
                String(localized: "Photosynthesis is the process plants, algae, and some bacteria use to turn light energy into chemical energy stored in glucose.", table: "SampleSet"),
                String(localized: "It takes place in chloroplasts, organelles found mostly in the cells of a leaf's mesophyll layer.", table: "SampleSet"),
                String(localized: "Chlorophyll is the green pigment inside chloroplasts. It absorbs red and blue light and reflects green light, which is why leaves look green.", table: "SampleSet"),
                String(localized: "The overall equation is 6CO2 + 6H2O + light energy → C6H12O6 + 6O2.", table: "SampleSet"),
                String(localized: "Carbon dioxide enters the leaf through small pores called stomata, and water is carried up from the roots through the xylem.", table: "SampleSet")
            ],
            [
                String(localized: "Photosynthesis happens in two stages: the light-dependent reactions and the Calvin cycle.", table: "SampleSet"),
                String(localized: "The light-dependent reactions take place in the thylakoid membranes. They split water, release oxygen, and produce ATP and NADPH.", table: "SampleSet"),
                String(localized: "The oxygen released by photosynthesis comes from the water molecules that are split, not from carbon dioxide.", table: "SampleSet"),
                String(localized: "The Calvin cycle takes place in the stroma. It uses ATP and NADPH to fix carbon dioxide into sugar.", table: "SampleSet"),
                String(localized: "The rate of photosynthesis depends on light intensity, carbon dioxide concentration, and temperature.", table: "SampleSet")
            ]
        ],
        cards: [
            // MARK: Due today: fills TODAY'S SESSION
            CardSpec(
                question: String(localized: "Where in the cell does photosynthesis take place?", table: "SampleSet"),
                answer: String(localized: "In the chloroplasts.", table: "SampleSet"),
                explanation: String(localized: "Chloroplasts hold the chlorophyll and membranes that capture light, so the whole process runs inside them.", table: "SampleSet"),
                distractors: [String(localized: "In the mitochondria.", table: "SampleSet"), String(localized: "In the nucleus.", table: "SampleSet"), String(localized: "In the ribosomes.", table: "SampleSet")],
                page: 1, paragraph: 2
            ),
            // The weakest card: the most misses drives WEAKEST CARD on Today.
            CardSpec(
                question: String(localized: "What is chlorophyll?", table: "SampleSet"),
                answer: String(localized: "The green pigment that absorbs red and blue light to power photosynthesis.", table: "SampleSet"),
                explanation: String(localized: "Chlorophyll captures light energy. The green light it reflects is why leaves look green.", table: "SampleSet"),
                distractors: [
                    String(localized: "The sugar a plant stores for energy.", table: "SampleSet"),
                    String(localized: "A pigment that absorbs green light and reflects red light.", table: "SampleSet"),
                    String(localized: "The tissue that carries water up from the roots.", table: "SampleSet")
                ],
                page: 1, paragraph: 3, box: 1, missCount: 2
            ),
            CardSpec(
                question: String(localized: "What are the products of photosynthesis?", table: "SampleSet"),
                answer: String(localized: "Glucose and oxygen.", table: "SampleSet"),
                explanation: String(localized: "The equation ends in C6H12O6 and 6O2: sugar the plant keeps and oxygen it releases.", table: "SampleSet"),
                distractors: [String(localized: "Carbon dioxide only.", table: "SampleSet"), String(localized: "Glucose and water.", table: "SampleSet"), String(localized: "Water and oxygen.", table: "SampleSet")],
                page: 1, paragraph: 4, missCount: 1
            ),
            CardSpec(
                question: String(localized: "How does carbon dioxide get into a leaf?", table: "SampleSet"),
                answer: String(localized: "Through small pores called stomata.", table: "SampleSet"),
                explanation: String(localized: "Stomata open on the leaf surface so gases can move in and out.", table: "SampleSet"),
                distractors: [String(localized: "Through the roots, with water.", table: "SampleSet"), String(localized: "Through the bark of the stem.", table: "SampleSet"), String(localized: "Through the chloroplast membrane.", table: "SampleSet")],
                page: 1, paragraph: 5, box: 2
            ),
            CardSpec(
                question: String(localized: "What are the two stages of photosynthesis?", table: "SampleSet"),
                answer: String(localized: "The light-dependent reactions and the Calvin cycle.", table: "SampleSet"),
                explanation: String(localized: "The light reactions capture energy, and the Calvin cycle spends it building sugar.", table: "SampleSet"),
                distractors: [
                    String(localized: "Glycolysis and the Krebs cycle.", table: "SampleSet"),
                    String(localized: "Interphase and the stages of mitosis.", table: "SampleSet"),
                    String(localized: "Transcription and then translation of DNA.", table: "SampleSet")
                ],
                page: 2, paragraph: 1
            ),

            // MARK: Upcoming: fills UP NEXT
            CardSpec(
                question: String(localized: "Where do the light-dependent reactions happen?", table: "SampleSet"),
                answer: String(localized: "In the thylakoids.", table: "SampleSet"),
                explanation: String(localized: "The thylakoids hold the chlorophyll that captures light, so the light reactions run there.", table: "SampleSet"),
                distractors: [String(localized: "In the stroma.", table: "SampleSet"), String(localized: "In the cytoplasm.", table: "SampleSet"), String(localized: "In the stomata.", table: "SampleSet")],
                page: 2, paragraph: 2, box: 2, dueInDays: 1
            ),
            CardSpec(
                question: String(localized: "Where does the oxygen released by photosynthesis come from?", table: "SampleSet"),
                answer: String(localized: "From water molecules that are split.", table: "SampleSet"),
                explanation: String(localized: "Splitting water in the light reactions frees the oxygen. The carbon from carbon dioxide ends up in sugar instead.", table: "SampleSet"),
                distractors: [
                    String(localized: "From carbon dioxide taken in by the leaf.", table: "SampleSet"),
                    String(localized: "From glucose broken down in the cell.", table: "SampleSet"),
                    String(localized: "From the air inside the stomata.", table: "SampleSet")
                ],
                page: 2, paragraph: 3, box: 3, dueInDays: 1
            ),
            CardSpec(
                question: String(localized: "What does the Calvin cycle produce?", table: "SampleSet"),
                answer: String(localized: "Sugar, built from carbon dioxide.", table: "SampleSet"),
                explanation: String(localized: "It uses the ATP and NADPH made by the light reactions to fix carbon dioxide into sugar.", table: "SampleSet"),
                distractors: [
                    String(localized: "Oxygen, released from water.", table: "SampleSet"),
                    String(localized: "ATP and NADPH for the light reactions.", table: "SampleSet"),
                    String(localized: "Chlorophyll for capturing more light.", table: "SampleSet")
                ],
                page: 2, paragraph: 4, box: 3, dueInDays: 3
            ),
            CardSpec(
                question: String(localized: "Which three factors affect the rate of photosynthesis?", table: "SampleSet"),
                answer: String(localized: "Light intensity, carbon dioxide concentration, and temperature.", table: "SampleSet"),
                explanation: String(localized: "Each is an input or condition the reactions depend on, so a shortage of any one slows the whole process.", table: "SampleSet"),
                distractors: [
                    String(localized: "Soil type, leaf color, and plant height.", table: "SampleSet"),
                    String(localized: "Oxygen level, glucose level, and leaf size.", table: "SampleSet"),
                    String(localized: "Day length, root depth, and humidity.", table: "SampleSet")
                ],
                page: 2, paragraph: 5, box: 3, dueInDays: 5
            ),

            // MARK: Mastered: drives the mastered count in Stats
            CardSpec(
                question: String(localized: "What is photosynthesis?", table: "SampleSet"),
                answer: String(localized: "Turning light energy into chemical energy stored in glucose.", table: "SampleSet"),
                explanation: String(localized: "Plants capture sunlight and store its energy in the bonds of a sugar they can use later.", table: "SampleSet"),
                distractors: [
                    String(localized: "Breaking down glucose to release energy.", table: "SampleSet"),
                    String(localized: "Absorbing water through the roots.", table: "SampleSet"),
                    String(localized: "Releasing carbon dioxide into the air.", table: "SampleSet")
                ],
                page: 1, paragraph: 1, box: 5, dueInDays: 30
            )
        ]
    )
}
