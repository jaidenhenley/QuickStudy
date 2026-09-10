//
//  CardGenerating.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 3/20/26.
//

import Foundation

protocol CardGenerating {
    func generateCards(from text: String) async throws -> [AIFlashcard]
    func generateCards(from text: String, topic: String, count: Int) async throws -> [AIFlashcard]
}
