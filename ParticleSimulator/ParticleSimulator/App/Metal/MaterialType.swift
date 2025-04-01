//
//  MaterialType.swift
//  ParticleSimulator
//
//  Created by 이종선 on 4/1/25.
//

import Foundation

enum MaterialType {
    case empty
    case sand
    case water
    case salt
    case wood
    case fire
    case smoke
    case ember
    case steam
    case gunpowder
    case oil
    case lava
    case stone
    case acid
    
    // Returns default color for each material type
    func defaultColor() -> Color {
        switch self {
        case .empty:
            return Color(r: 0, g: 0, b: 0, a: 0)
        case .sand:
            return Color(r: 150, g: 100, b: 50, a: 255)
        case .water:
            return Color(r: 20, g: 100, b: 170, a: 200)
        case .salt:
            return Color(r: 200, g: 180, b: 190, a: 255)
        case .wood:
            return Color(r: 60, g: 40, b: 20, a: 255)
        case .fire:
            return Color(r: 150, g: 20, b: 0, a: 255)
        case .smoke:
            return Color(r: 50, g: 50, b: 50, a: 255)
        case .ember:
            return Color(r: 200, g: 120, b: 20, a: 255)
        case .steam:
            return Color(r: 220, g: 220, b: 250, a: 255)
        case .gunpowder:
            return Color(r: 60, g: 60, b: 60, a: 255)
        case .oil:
            return Color(r: 80, g: 70, b: 60, a: 255)
        case .lava:
            return Color(r: 200, g: 50, b: 0, a: 255)
        case .stone:
            return Color(r: 120, g: 110, b: 120, a: 255)
        case .acid:
            return Color(r: 90, g: 200, b: 60, a: 255)
        }
    }
    
    // Returns a randomized color for each material type for more natural look
    func randomizedColor() -> Color {
        var color = defaultColor()
        let variation = Int8.random(in: -15...15)
        
        switch self {
        case .empty:
            return color
        case .sand:
            color.r = UInt8(clamp(Int(color.r) + Int(variation), min: 0, max: 255))
            color.g = UInt8(clamp(Int(color.g) + Int(variation), min: 0, max: 255))
            color.b = UInt8(clamp(Int(color.b) + Int(variation/2), min: 0, max: 255))
        case .water:
            color.r = UInt8(clamp(Int(color.r) + Int(variation/3), min: 0, max: 255))
            color.g = UInt8(clamp(Int(color.g) + Int(variation/2), min: 0, max: 255))
            color.b = UInt8(clamp(Int(color.b) + Int(variation), min: 0, max: 255))
        case .salt:
            let whiteVariation = Int8.random(in: -5...5)
            color.r = UInt8(clamp(Int(color.r) + Int(whiteVariation), min: 0, max: 255))
            color.g = UInt8(clamp(Int(color.g) + Int(whiteVariation), min: 0, max: 255))
            color.b = UInt8(clamp(Int(color.b) + Int(whiteVariation), min: 0, max: 255))
        case .fire:
            // Fire should flicker
            let flickerVariation = Int8.random(in: -30...30)
            color.r = UInt8(clamp(Int(color.r) + Int(flickerVariation/2), min: 0, max: 255))
            color.g = UInt8(clamp(Int(color.g) + Int(flickerVariation/3), min: 0, max: 255))
        case .lava:
            let flickerVariation = Int8.random(in: -20...20)
            color.r = UInt8(clamp(Int(color.r) + Int(flickerVariation/2), min: 0, max: 255))
            color.g = UInt8(clamp(Int(color.g) + Int(flickerVariation/3), min: 0, max: 255))
        default:
            color.r = UInt8(clamp(Int(color.r) + Int(variation), min: 0, max: 255))
            color.g = UInt8(clamp(Int(color.g) + Int(variation), min: 0, max: 255))
            color.b = UInt8(clamp(Int(color.b) + Int(variation), min: 0, max: 255))
        }
        
        return color
    }
}

// Helper function to clamp values
func clamp<T: Comparable>(_ value: T, min minValue: T, max maxValue: T) -> T {
    return min(max(value, minValue), maxValue)
}
