//
//  ParticleSimulator.swift
//  ParticleSimulator
//
//  Created by 이종선 on 4/1/25.
//

import Foundation
import MetalKit

class ParticleSimulator {
    // 시뮬레이션 매개변수
    private let gridWidth: Int
    private let gridHeight: Int
    
    // 버퍼
    private(set) var particles: [Particle]
    private(set) var colorBuffer: [Color]
    
    // 더 나중에 확장을 위한 프로퍼티들
    private(set) var gravity: Float = 1.0
    private(set) var currentMaterial: MaterialType = .sand
    
    enum MaterialType {
        case sand
        case water
        // 나중에 추가될 재료
    }
    
    // MARK: - 초기화
    
    init(width: Int, height: Int) {
        self.gridWidth = width
        self.gridHeight = height
        
        // 입자 데이터 초기화
        self.particles = [Particle](repeating: Particle(
            isEmpty: true,
            hasBeenUpdated: false
        ), count: width * height)
        
        // 색상 버퍼 초기화 (처음에는 모두 투명)
        self.colorBuffer = [Color](repeating: Color(r: 0, g: 0, b: 0, a: 0), count: width * height)
    }
    
    // MARK: - 공개 메서드
    
    /// 시뮬레이션 한 단계 업데이트
    func update() {
        updateSandSimulation()
    }
    
    /// 지정된 위치에 입자 생성
    func createParticlesAt(x: Int, y: Int, radius: Int = 2) {
        // 경계 확인
        guard x >= 0 && x < gridWidth && y >= 0 && y < gridHeight else {
            return
        }
        
        // 지정된 반경 내에 입자 생성
        for offsetY in -radius...radius {
            for offsetX in -radius...radius {
                let posX = x + offsetX
                let posY = y + offsetY
                
                // 경계 확인
                if posX >= 0 && posX < gridWidth && posY >= 0 && posY < gridHeight {
                    let index = posY * gridWidth + posX
                    
                    // 빈 셀에만 모래 배치
                    if particles[index].isEmpty {
                        // 입자 생성
                        particles[index] = Particle(isEmpty: false, hasBeenUpdated: false)
                        
                        // 모래 색상 설정 (자연스러운 모습을 위한 약간의 변화)
                        let variation = UInt8.random(in: 0...30)
                        colorBuffer[index] = Color(
                            r: UInt8(min(220 + Int(variation) - 15, 255)),
                            g: UInt8(min(180 + Int(variation) - 15, 255)),
                            b: UInt8(min(80 + Int(variation) - 15, 255)),
                            a: 255
                        )
                    }
                }
            }
        }
    }
    
    /// 두 지점 사이를 보간하여 입자 생성 (드래그 효과)
    func createParticlesBetween(startX: Int, startY: Int, endX: Int, endY: Int) {
        let distance = hypot(Double(endX - startX), Double(endY - startY))
        let steps = max(Int(distance / 2.0), 1) // 약 2픽셀마다 하나의 입자
        
        for step in 0..<steps {
            let progress = Double(step) / Double(steps)
            let interpolatedX = Int(Double(startX) + Double(endX - startX) * progress)
            let interpolatedY = Int(Double(startY) + Double(endY - startY) * progress)
            createParticlesAt(x: interpolatedX, y: interpolatedY)
        }
    }
    
    /// 시뮬레이션 초기화 (모든 입자 제거)
    func reset() {
        particles = [Particle](repeating: Particle(
            isEmpty: true,
            hasBeenUpdated: false
        ), count: gridWidth * gridHeight)
        
        colorBuffer = [Color](repeating: Color(r: 0, g: 0, b: 0, a: 0), count: gridWidth * gridHeight)
    }
    
    // MARK: - 내부 메서드
    
    /// 모래 입자 물리 시뮬레이션 업데이트
    private func updateSandSimulation() {
        // 아래에서 위로 순회 (중력 방향을 고려)
        for y in (0..<gridHeight).reversed() {
            for x in 0..<gridWidth {
                let index = y * gridWidth + x
                
                // 빈 공간이거나 이미 업데이트된 입자는 건너뛰기
                if particles[index].isEmpty || particles[index].hasBeenUpdated {
                    continue
                }
                
                // 모래 입자 업데이트 로직
                let belowY = y + 1
                
                // 화면 바닥에 도달했는지 확인
                if belowY >= gridHeight {
                    particles[index].hasBeenUpdated = true
                    continue
                }
                
                // 1. 바로 아래가 비어있으면 아래로 떨어짐
                if particles[belowY * gridWidth + x].isEmpty {
                    moveParticle(fromIndex: index, toIndex: belowY * gridWidth + x)
                }
                // 2. 왼쪽 아래가 비어있으면 왼쪽 아래로 이동
                else if x > 0 && particles[belowY * gridWidth + (x-1)].isEmpty {
                    moveParticle(fromIndex: index, toIndex: belowY * gridWidth + (x-1))
                }
                // 3. 오른쪽 아래가 비어있으면 오른쪽 아래로 이동
                else if x < gridWidth-1 && particles[belowY * gridWidth + (x+1)].isEmpty {
                    moveParticle(fromIndex: index, toIndex: belowY * gridWidth + (x+1))
                }
                // 4. 이동할 수 없으면 해당 위치에 정지
                else {
                    particles[index].hasBeenUpdated = true
                }
            }
        }
        
        // 다음 프레임을 위해 업데이트 플래그 초기화
        for i in 0..<particles.count {
            particles[i].hasBeenUpdated = false
        }
    }
    
    /// 입자 이동 헬퍼 함수
    private func moveParticle(fromIndex: Int, toIndex: Int) {
        // 1. 물리 데이터 이동
        particles[toIndex] = particles[fromIndex]
        particles[toIndex].hasBeenUpdated = true
        particles[fromIndex] = Particle(isEmpty: true, hasBeenUpdated: false)
        
        // 2. 색상 데이터 이동
        colorBuffer[toIndex] = colorBuffer[fromIndex]
        colorBuffer[fromIndex] = Color(r: 0, g: 0, b: 0, a: 0)
    }
}
