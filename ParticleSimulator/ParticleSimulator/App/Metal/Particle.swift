//
//  Particle.swift
//  ParticleSimulator
//
//  Created by 이종선 on 3/31/25.
//

import MetalKit

// 단순한 입자 구조체
struct Particle {
    var isEmpty: Bool      // 이 셀이 비어있는지 여부
    var hasBeenUpdated: Bool    // 이 프레임에서 이미 업데이트 되었는지
}

// RGBA 색상 구조체
struct Color {
    var r: UInt8
    var g: UInt8
    var b: UInt8
    var a: UInt8
}
