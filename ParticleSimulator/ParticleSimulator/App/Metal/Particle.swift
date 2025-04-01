//
//  Particle.swift
//  ParticleSimulator
//
//  Created by 이종선 on 3/31/25.
//

import MetalKit

// 단순한 입자 구조체
struct Particle {
    var type: MaterialType
    var hasBeenUpdated: Bool     // 이 프레임에서 이미 업데이트 되었는지
    var lifeTime: Float          // 입자의 수명 (예: 불이나 연기에 필요)
    var velocity: SIMD2<Float>   // x, y 속도 벡터
    
    var isEmpty: Bool {
        return type == .empty
    }
    
    // Empty/default particle
    static func empty() -> Particle {
        return Particle(
            type: .empty,
            hasBeenUpdated: false,
            lifeTime: 0,
            velocity: SIMD2<Float>(0, 0)
        )
    }
    
    // Sand particle constructor
    static func sand() -> Particle {
        return Particle(
            type: .sand,
            hasBeenUpdated: false,
            lifeTime: 0,
            velocity: SIMD2<Float>(Float.random(in: -0.5...0.5), Float.random(in: 0...2))
        )
    }
    
    // Water particle constructor
    static func water() -> Particle {
        return Particle(
            type: .water,
            hasBeenUpdated: false,
            lifeTime: 0,
            velocity: SIMD2<Float>(Float.random(in: -0.5...0.5), Float.random(in: 0...1))
        )
    }
    
    // Salt particle constructor
    static func salt() -> Particle {
        return Particle(
            type: .salt,
            hasBeenUpdated: false,
            lifeTime: 0,
            velocity: SIMD2<Float>(Float.random(in: -0.3...0.3), Float.random(in: 0...1.5))
        )
    }
    
    // Wood particle constructor
    static func wood() -> Particle {
        return Particle(
            type: .wood,
            hasBeenUpdated: false,
            lifeTime: 0,
            velocity: SIMD2<Float>(0, 0) // Wood doesn't move
        )
    }
    
    // Fire particle constructor
    static func fire() -> Particle {
        return Particle(
            type: .fire,
            hasBeenUpdated: false,
            lifeTime: 0,
            velocity: SIMD2<Float>(Float.random(in: -0.5...0.5), Float.random(in: -2...0))
        )
    }
    
    // Smoke particle constructor
    static func smoke() -> Particle {
        return Particle(
            type: .smoke,
            hasBeenUpdated: false,
            lifeTime: 0,
            velocity: SIMD2<Float>(Float.random(in: -0.3...0.3), Float.random(in: -1...0))
        )
    }
    
    // Ember particle constructor
    static func ember() -> Particle {
        return Particle(
            type: .ember,
            hasBeenUpdated: false,
            lifeTime: 0,
            velocity: SIMD2<Float>(Float.random(in: -1...1), Float.random(in: -2...0))
        )
    }
    
    // Steam particle constructor
    static func steam() -> Particle {
        return Particle(
            type: .steam,
            hasBeenUpdated: false,
            lifeTime: 0,
            velocity: SIMD2<Float>(Float.random(in: -0.3...0.3), Float.random(in: -1.5...0))
        )
    }
    
    // Gunpowder particle constructor
    static func gunpowder() -> Particle {
        return Particle(
            type: .gunpowder,
            hasBeenUpdated: false,
            lifeTime: 0,
            velocity: SIMD2<Float>(Float.random(in: -0.3...0.3), Float.random(in: 0...1.5))
        )
    }
    
    // Oil particle constructor
    static func oil() -> Particle {
        return Particle(
            type: .oil,
            hasBeenUpdated: false,
            lifeTime: 0,
            velocity: SIMD2<Float>(Float.random(in: -0.3...0.3), Float.random(in: 0...0.8))
        )
    }
    
    // Lava particle constructor
    static func lava() -> Particle {
        return Particle(
            type: .lava,
            hasBeenUpdated: false,
            lifeTime: 0,
            velocity: SIMD2<Float>(Float.random(in: -0.2...0.2), Float.random(in: 0...0.5))
        )
    }
    
    // Stone particle constructor
    static func stone() -> Particle {
        return Particle(
            type: .stone,
            hasBeenUpdated: false,
            lifeTime: 0,
            velocity: SIMD2<Float>(0, 0) // Stone doesn't move
        )
    }
    
    // Acid particle constructor
    static func acid() -> Particle {
        return Particle(
            type: .acid,
            hasBeenUpdated: false,
            lifeTime: 0,
            velocity: SIMD2<Float>(Float.random(in: -0.3...0.3), Float.random(in: 0...1))
        )
    }
}

// RGBA 색상 구조체
struct Color {
    var r: UInt8
    var g: UInt8
    var b: UInt8
    var a: UInt8
}
