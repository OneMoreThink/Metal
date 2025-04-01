//
//  Particle.swift
//  ParticleSimulator
//
//  Created by 이종선 on 3/31/25.
//

import MetalKit

// RGBA 색상 구조체
struct Color {
    var r: UInt8
    var g: UInt8
    var b: UInt8
    var a: UInt8
}

// GPU와 공유할 입자 구조체
struct Particle {
    var isEmpty: UInt32    // GPU에서 bool 대신 UInt32 사용 (메모리 정렬)
    var type: UInt32       // 입자 타입
}

// GPU에 전달할 시뮬레이션 파라미터
struct SimulationParams {
    var width: UInt32
    var height: UInt32
    var frameCount: UInt32
}
