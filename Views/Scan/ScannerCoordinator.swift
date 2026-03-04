//
//  DocumentScannerCoordinator.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 1/26/26.
//

import UIKit
@preconcurrency import VisionKit

class ScannerCoordinator: NSObject, VNDocumentCameraViewControllerDelegate, @unchecked Sendable {
    private let parent: DocumentScannerView

    init(parent: DocumentScannerView) {
        self.parent = parent
    }

    func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        DispatchQueue.main.async {
            self.parent.onCancel()
        }
    }

    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.parent.onCancel()
        }
    }

    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
        var images: [UIImage] = []
        for index in 0..<scan.pageCount {
            images.append(scan.imageOfPage(at: index))
        }
        DispatchQueue.main.async {
            self.parent.onComplete(images)
        }
    }
}
