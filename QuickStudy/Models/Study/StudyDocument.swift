//
//  StudyDocument.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 1/18/26.
//

import Foundation

struct StudyDocument: Codable, Equatable {
    var title: String
    var lines: [String]

    var paragraphText: String {
        var paragraphs: [String] = []
        var current: [String] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                if !current.isEmpty {
                    paragraphs.append(current.joined(separator: " "))
                    current.removeAll(keepingCapacity: true)
                }
            } else {
                current.append(trimmed)
            }
        }

        if !current.isEmpty {
            paragraphs.append(current.joined(separator: " "))
        }

        return paragraphs.joined(separator: "\n\n")
    }
}
