import AppKit
import SwiftUI

@MainActor
public final class ColorSamplerManager: ObservableObject {
    @Published public var isSampling: Bool = false

    public init() {}

    public func pickBackgroundColor(into model: ColorModel) {
        pickColor { color in
            model.setBackgroundColor(color)
        }
    }

    public func pickForegroundColor(into model: ColorModel) {
        pickColor { color in
            model.setForegroundColor(color)
        }
    }

    private func pickColor(completion: @escaping (NSColor) -> Void) {
        guard !isSampling else { return }
        isSampling = true

        let sampler = NSColorSampler()
        sampler.show { [weak self] selectedColor in
            DispatchQueue.main.async {
                self?.isSampling = false
                guard let color = selectedColor else { return }
                completion(color)
            }
        }
    }
}

