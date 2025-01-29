//
//  UIApplication+Extensions.swift
//  Taste Test
//
//  Created by Jeff Winkle on 1/27/25.
//

import UIKit

extension UIApplication {
    static var safeAreaTopInset: CGFloat {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else {
            return 0 // Default fallback if no scene or window is available
        }
        return window.safeAreaInsets.top
    }
}
