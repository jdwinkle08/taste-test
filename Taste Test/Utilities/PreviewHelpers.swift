//
//  PreviewHelpers.swift
//  Taste Test
//
//  Created by Jeff Winkle on 1/26/25.
//

import SwiftUI

/// A helper to create state bindings for SwiftUI previews.
struct StatefulPreviewWrapper<Value, Content: View>: View {
    @State private var value: Value
    private let content: (Binding<Value>) -> Content

    init(_ initialValue: Value, @ViewBuilder content: @escaping (Binding<Value>) -> Content) {
        self._value = State(initialValue: initialValue)
        self.content = content
    }

    var body: some View {
        content($value)
    }
}
