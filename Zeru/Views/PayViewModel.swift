//
//  PayViewModel.swift
//  Zeru
//
//  Created by Yann Renard on 14/03/2026.
//

import SwiftUI
import Combine
import CoreImage.CIFilterBuiltins

@MainActor
class PayViewModel: ObservableObject {

    @Published var qrImage: UIImage?
    @Published var timeLeft: Int = 30
    @Published var counter: Int = 0
    @Published var isExpired = false

    private var timer: Timer?
    private var seed: String = ""

    func setup(identification: IzlyIdentification, seed: String) {
        self.seed    = seed
        self.counter = 0
        generateQR()
        startTimer()
    }

    func generateQR() {
        guard !seed.isEmpty else { return }
        guard let otpCode = OTPService.generate(seed: seed, counter: counter) else { return }
        qrImage   = createQRImage(from: otpCode)
        timeLeft  = 30
        isExpired = false
        counter  += 1
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                if self.timeLeft > 0 {
                    self.timeLeft -= 1
                } else {
                    self.isExpired = true
                    try? await Task.sleep(for: .milliseconds(400))
                    self.generateQR()
                }
            }
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func createQRImage(from string: String) -> UIImage? {
        let context = CIContext()
        let filter  = CIFilter.qrCodeGenerator()
        filter.message         = Data(string.utf8)
        filter.correctionLevel = "M"
        guard let ciImage = filter.outputImage else { return nil }
        let scaled = ciImage.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}
