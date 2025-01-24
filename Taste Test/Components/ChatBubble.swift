//
//  ChatBubble.swift
//  Taste Test
//
//  Created by Jeff Winkle on 1/23/25.
//


import SwiftUI

struct ChatBubble: Shape {
    var isUser: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()

        if isUser {
            // User bubble with a tail on the right
            path.move(to: CGPoint(x: rect.minX, y: rect.minY + 16))
            path.addArc(center: CGPoint(x: rect.minX + 16, y: rect.minY + 16), radius: 16, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
            path.addLine(to: CGPoint(x: rect.maxX - 16, y: rect.minY))
            path.addArc(center: CGPoint(x: rect.maxX - 16, y: rect.minY + 16), radius: 16, startAngle: .degrees(270), endAngle: .degrees(0), clockwise: false)
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - 16))
            path.addArc(center: CGPoint(x: rect.maxX - 16, y: rect.maxY - 16), radius: 16, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
            path.addLine(to: CGPoint(x: rect.minX + 26, y: rect.maxY))
            path.addCurve(to: CGPoint(x: rect.minX, y: rect.maxY - 16), control1: CGPoint(x: rect.minX + 8, y: rect.maxY), control2: CGPoint(x: rect.minX, y: rect.maxY - 8))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + 16))
        } else {
            // Received bubble with a tail on the left
            path.move(to: CGPoint(x: rect.maxX, y: rect.minY + 16))
            path.addArc(center: CGPoint(x: rect.maxX - 16, y: rect.minY + 16), radius: 16, startAngle: .degrees(0), endAngle: .degrees(270), clockwise: true)
            path.addLine(to: CGPoint(x: rect.minX + 16, y: rect.minY))
            path.addArc(center: CGPoint(x: rect.minX + 16, y: rect.minY + 16), radius: 16, startAngle: .degrees(270), endAngle: .degrees(180), clockwise: true)
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - 16))
            path.addArc(center: CGPoint(x: rect.minX + 16, y: rect.maxY - 16), radius: 16, startAngle: .degrees(180), endAngle: .degrees(90), clockwise: true)
            path.addLine(to: CGPoint(x: rect.maxX - 26, y: rect.maxY))
            path.addCurve(to: CGPoint(x: rect.maxX, y: rect.maxY - 16), control1: CGPoint(x: rect.maxX - 8, y: rect.maxY), control2: CGPoint(x: rect.maxX, y: rect.maxY - 8))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + 16))
        }

        return path
    }
}
