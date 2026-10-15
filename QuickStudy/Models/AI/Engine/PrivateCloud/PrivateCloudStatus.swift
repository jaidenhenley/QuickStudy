//
//  PrivateCloudStatus.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 10/15/26.
//

import Foundation

enum PrivateCloudStatus: Equatable {
    case ready(approachingLimit: Bool)
    case quotaReached(resetsAt: Date?)
    // Not on iOS 27, the device can't use Apple Intelligence, or the system isn't ready.
    case unavailable
}
