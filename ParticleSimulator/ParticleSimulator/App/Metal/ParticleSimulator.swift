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
    
    // 시뮬레이션 속성
    private(set) var gravity: Float = 10.0
    private(set) var currentMaterial: MaterialType = .sand
    private var frameCounter: UInt32 = 0
    
    // MARK: - 초기화
    
    init(width: Int, height: Int) {
        self.gridWidth = width
        self.gridHeight = height
        
        // 입자 데이터 초기화
        self.particles = [Particle](repeating: Particle.empty(), count: width * height)
        
        // 색상 버퍼 초기화 (처음에는 모두 투명)
        self.colorBuffer = [Color](repeating: Color(r: 0, g: 0, b: 0, a: 0), count: width * height)
    }
    
    // MARK: - 공개 메서드
    
    /// 시뮬레이션 현재 재료 설정
    func setCurrentMaterial(_ materialType: MaterialType) {
        currentMaterial = materialType
    }
    
    /// 시뮬레이션 한 단계 업데이트
    func update() {
        let deltaTime: Float = 1.0 / 60.0 // 60 FPS 가정
        let frameEven = frameCounter % 2 == 0
        
        // 아래에서 위로 업데이트 (중력 방향을 고려)
        for y in (0..<gridHeight).reversed() {
            // 프레임마다 다른 방향에서 시작하여 방향성 편향을 줄임
            let xRange = frameEven ? Array(0..<gridWidth) : Array((0..<gridWidth).reversed())
            
            for x in xRange {
                let index = y * gridWidth + x
                
                // 빈 공간이거나 이미 업데이트된 입자는 건너뛰기
                if particles[index].isEmpty || particles[index].hasBeenUpdated {
                    continue
                }
                
                // 입자 타입에 따라 다른 업데이트 로직 적용
                switch particles[index].type {
                case .sand:
                    updateSand(x: x, y: y, deltaTime: deltaTime)
                case .water:
                    updateWater(x: x, y: y, deltaTime: deltaTime)
                case .salt:
                    updateSalt(x: x, y: y, deltaTime: deltaTime)
                case .fire:
                    updateFire(x: x, y: y, deltaTime: deltaTime)
                case .smoke:
                    updateSmoke(x: x, y: y, deltaTime: deltaTime)
                case .ember:
                    updateEmber(x: x, y: y, deltaTime: deltaTime)
                case .steam:
                    updateSteam(x: x, y: y, deltaTime: deltaTime)
                case .gunpowder:
                    updateGunpowder(x: x, y: y, deltaTime: deltaTime)
                case .oil:
                    updateOil(x: x, y: y, deltaTime: deltaTime)
                case .lava:
                    updateLava(x: x, y: y, deltaTime: deltaTime)
                case .acid:
                    updateAcid(x: x, y: y, deltaTime: deltaTime)
                default:
                    // Empty, wood, stone - 움직이지 않는 입자
                    particles[index].hasBeenUpdated = true
                }
            }
        }
        
        // 다음 프레임을 위해 업데이트 플래그 초기화
        for i in 0..<particles.count {
            particles[i].hasBeenUpdated = false
            
            // 시간에 따른 입자 업데이트 (색상 변화, 수명 등)
            updateParticleProperties(at: i, deltaTime: deltaTime)
        }
        
        // 프레임 카운터 증가
        frameCounter += 1
    }
    
    /// 지정된 위치에 입자 생성
    func createParticlesAt(x: Int, y: Int, radius: Int = 3) {
        // 경계 확인
        guard x >= 0 && x < gridWidth && y >= 0 && y < gridHeight else {
            return
        }
        
        // 지정된 반경 내에 입자 생성
        for offsetY in -radius...radius {
            for offsetX in -radius...radius {
                // 원형 패턴으로 생성
                let distance = sqrt(Double(offsetX * offsetX + offsetY * offsetY))
                if distance > Double(radius) {
                    continue
                }
                
                let posX = x + offsetX
                let posY = y + offsetY
                
                // 경계 확인
                if posX >= 0 && posX < gridWidth && posY >= 0 && posY < gridHeight {
                    let index = posY * gridWidth + posX
                    
                    // 빈 셀에만 입자 배치
                    if particles[index].isEmpty {
                        // 현재 선택된 재료로 입자 생성
                        let newParticle = createParticleOfType(currentMaterial)
                        particles[index] = newParticle
                        
                        // 색상 설정
                        colorBuffer[index] = currentMaterial.randomizedColor()
                    }
                }
            }
        }
    }
    
    /// 두 지점 사이를 보간하여 입자 생성 (드래그 효과)
    func createParticlesBetween(startX: Int, startY: Int, endX: Int, endY: Int) {
        let distance = hypot(Double(endX - startX), Double(endY - startY))
        let steps = max(Int(distance * 0.5), 1) // 거리에 비례하여 입자 생성
        
        for step in 0..<steps {
            let progress = Double(step) / Double(steps)
            let interpolatedX = Int(Double(startX) + Double(endX - startX) * progress)
            let interpolatedY = Int(Double(startY) + Double(endY - startY) * progress)
            createParticlesAt(x: interpolatedX, y: interpolatedY, radius: 2)
        }
    }
    
    /// 시뮬레이션 초기화 (모든 입자 제거)
    func reset() {
        particles = [Particle](repeating: Particle.empty(), count: gridWidth * gridHeight)
        colorBuffer = [Color](repeating: Color(r: 0, g: 0, b: 0, a: 0), count: gridWidth * gridHeight)
    }
    
    // MARK: - 내부 유틸리티 메서드
    
    private func inBounds(x: Int, y: Int) -> Bool {
        return x >= 0 && x < gridWidth && y >= 0 && y < gridHeight
    }
    
    private func computeIndex(x: Int, y: Int) -> Int {
        return y * gridWidth + x
    }
    
    private func isEmpty(x: Int, y: Int) -> Bool {
        guard inBounds(x: x, y: y) else { return false }
        return particles[computeIndex(x: x, y: y)].isEmpty
    }
    
    private func getParticleAt(x: Int, y: Int) -> Particle? {
        guard inBounds(x: x, y: y) else { return nil }
        return particles[computeIndex(x: x, y: y)]
    }
    
    private func isLiquid(x: Int, y: Int) -> Bool {
        guard inBounds(x: x, y: y) else { return false }
        let type = particles[computeIndex(x: x, y: y)].type
        return type == .water || type == .oil || type == .acid
    }
    
    private func isFlammable(x: Int, y: Int) -> Bool {
        guard inBounds(x: x, y: y) else { return false }
        let type = particles[computeIndex(x: x, y: y)].type
        return type == .wood || type == .oil || type == .gunpowder
    }
    
    private func moveParticle(fromX: Int, fromY: Int, toX: Int, toY: Int) {
        guard inBounds(x: fromX, y: fromY) && inBounds(x: toX, y: toY) else { return }
        
        let fromIndex = computeIndex(x: fromX, y: fromY)
        let toIndex = computeIndex(x: toX, y: toY)
        
        // 입자 교환
        let temp = particles[toIndex]
        particles[toIndex] = particles[fromIndex]
        particles[toIndex].hasBeenUpdated = true
        particles[fromIndex] = temp
        
        // 색상 교환
        let tempColor = colorBuffer[toIndex]
        colorBuffer[toIndex] = colorBuffer[fromIndex]
        colorBuffer[fromIndex] = tempColor
    }
    
    private func setParticle(at index: Int, particle: Particle) {
        particles[index] = particle
        colorBuffer[index] = particle.type.randomizedColor()
    }
    
    private func setParticle(x: Int, y: Int, particle: Particle) {
        guard inBounds(x: x, y: y) else { return }
        let index = computeIndex(x: x, y: y)
        setParticle(at: index, particle: particle)
    }
    
    private func createParticleOfType(_ type: MaterialType) -> Particle {
        switch type {
        case .empty: return Particle.empty()
        case .sand: return Particle.sand()
        case .water: return Particle.water()
        case .salt: return Particle.salt()
        case .wood: return Particle.wood()
        case .fire: return Particle.fire()
        case .smoke: return Particle.smoke()
        case .ember: return Particle.ember()
        case .steam: return Particle.steam()
        case .gunpowder: return Particle.gunpowder()
        case .oil: return Particle.oil()
        case .lava: return Particle.lava()
        case .stone: return Particle.stone()
        case .acid: return Particle.acid()
        }
    }
    
    // 시간 경과에 따른 입자 속성 업데이트 (수명, 색상 변화 등)
    private func updateParticleProperties(at index: Int, deltaTime: Float) {
        var particle = particles[index]
        
        if particle.isEmpty { return }
        
        // 수명 증가
        particle.lifeTime += deltaTime
        
        // 타입별 특수 속성 업데이트
        switch particle.type {
        case .fire:
            // 불의 수명이 다하면 소멸
            if particle.lifeTime > 2.0 && Float.random(in: 0...1) < 0.1 {
                particles[index] = Particle.empty()
                colorBuffer[index] = MaterialType.empty.defaultColor()
                return
            }
            
            // 불꽃 색상 변화
            if Int.random(in: 0...10) == 0 {
                let colors: [Color] = [
                    Color(r: 255, g: 80, b: 20, a: 255),
                    Color(r: 250, g: 150, b: 10, a: 255),
                    Color(r: 200, g: 150, b: 0, a: 255),
                    Color(r: 100, g: 50, b: 2, a: 255)
                ]
                colorBuffer[index] = colors[Int.random(in: 0..<colors.count)]
            }
            
        case .smoke:
            // 연기 희미해짐
            if particle.lifeTime > 8.0 {
                particles[index] = Particle.empty()
                colorBuffer[index] = MaterialType.empty.defaultColor()
                return
            }
            
            // 연기 색상 변화 (점점 밝아짐)
            let fadeValue = min(particle.lifeTime / 8.0, 1.0)
            let baseGray = UInt8(50.0 * (1.0 - fadeValue))
            colorBuffer[index].r = baseGray
            colorBuffer[index].g = baseGray
            colorBuffer[index].b = baseGray
            colorBuffer[index].a = UInt8(max(255.0 * (1.0 - fadeValue), 50.0))
            
        case .ember:
            // 불씨 수명
            if particle.lifeTime > 0.5 {
                particles[index] = Particle.empty()
                colorBuffer[index] = MaterialType.empty.defaultColor()
                return
            }
            
        case .steam:
            // 증기 희미해짐
            if particle.lifeTime > 10.0 {
                particles[index] = Particle.empty()
                colorBuffer[index] = MaterialType.empty.defaultColor()
                return
            }
            
            // 증기 색상 변화 (점점 투명해짐)
            let fadeValue = min(particle.lifeTime / 10.0, 1.0)
            colorBuffer[index].a = UInt8(max(255.0 * (1.0 - fadeValue), 30.0))
            
        default:
            break
        }
        
        particles[index] = particle
    }
}

extension ParticleSimulator {
    
    func updateSand(x: Int, y: Int, deltaTime: Float) {
        var particle = particles[computeIndex(x: x, y: y)]
        
        // 중력 적용
        particle.velocity.y = min(particle.velocity.y + (gravity * deltaTime), 10.0)
        particles[computeIndex(x: x, y: y)] = particle
        
        // 아래가 경계 밖이면 업데이트 표시
        if y + 1 >= gridHeight {
            particles[computeIndex(x: x, y: y)].hasBeenUpdated = true
            return
        }
        
        // 밑으로 떨어지기
        if isEmpty(x: x, y: y + 1) {
            moveParticle(fromX: x, fromY: y, toX: x, toY: y + 1)
        }
        // 밑이 액체(물, 기름)이면 교환
        else if isLiquid(x: x, y: y + 1) {
            moveParticle(fromX: x, fromY: y, toX: x, toY: y + 1)
        }
        // 왼쪽 아래로 떨어지기
        else if x > 0 && isEmpty(x: x - 1, y: y + 1) {
            moveParticle(fromX: x, fromY: y, toX: x - 1, toY: y + 1)
        }
        // 오른쪽 아래로 떨어지기
        else if x < gridWidth - 1 && isEmpty(x: x + 1, y: y + 1) {
            moveParticle(fromX: x, fromY: y, toX: x + 1, toY: y + 1)
        }
        // 움직일 수 없으면 정지
        else {
            particles[computeIndex(x: x, y: y)].hasBeenUpdated = true
        }
    }
    
    func updateWater(x: Int, y: Int, deltaTime: Float) {
        var particle = particles[computeIndex(x: x, y: y)]
        
        // 중력 적용
        particle.velocity.y = min(particle.velocity.y + (gravity * deltaTime), 10.0)
        particles[computeIndex(x: x, y: y)] = particle
        
        // 무작위로 색상 변화 (물결 효과)
        if Int.random(in: 0...30) == 0 {
            let baseColor = MaterialType.water.defaultColor()
            let variation = Float.random(in: 0...0.1)
            colorBuffer[computeIndex(x: x, y: y)].r = UInt8(clamp(Int(Float(baseColor.r) * (1.0 + variation)), min: 0, max: 255))
            colorBuffer[computeIndex(x: x, y: y)].g = UInt8(clamp(Int(Float(baseColor.g) * (1.0 + variation)), min: 0, max: 255))
            colorBuffer[computeIndex(x: x, y: y)].b = UInt8(clamp(Int(Float(baseColor.b) * (1.0 + variation)), min: 0, max: 255))
        }
        
        // 아래가 경계 밖이면 업데이트 표시
        if y + 1 >= gridHeight {
            particles[computeIndex(x: x, y: y)].hasBeenUpdated = true
            return
        }
        
        // 기본 중력 효과
        if isEmpty(x: x, y: y + 1) {
            moveParticle(fromX: x, fromY: y, toX: x, toY: y + 1)
        }
        // 아래쪽이 꽉 찬 경우, 왼쪽이나 오른쪽으로 퍼짐
        else if x > 0 && isEmpty(x: x - 1, y: y + 1) {
            moveParticle(fromX: x, fromY: y, toX: x - 1, toY: y + 1)
        }
        else if x < gridWidth - 1 && isEmpty(x: x + 1, y: y + 1) {
            moveParticle(fromX: x, fromY: y, toX: x + 1, toY: y + 1)
        }
        // 수평으로 퍼짐 (물의 특성)
        else if x > 0 && isEmpty(x: x - 1, y: y) {
            moveParticle(fromX: x, fromY: y, toX: x - 1, toY: y)
        }
        else if x < gridWidth - 1 && isEmpty(x: x + 1, y: y) {
            moveParticle(fromX: x, fromY: y, toX: x + 1, toY: y)
        }
        // 더 넓게 퍼짐 시도
        else if x > 1 && isEmpty(x: x - 2, y: y) && isEmpty(x: x - 1, y: y) {
            moveParticle(fromX: x, fromY: y, toX: x - 2, toY: y)
        }
        else if x < gridWidth - 2 && isEmpty(x: x + 2, y: y) && isEmpty(x: x + 1, y: y) {
            moveParticle(fromX: x, fromY: y, toX: x + 2, toY: y)
        }
        else {
            particles[computeIndex(x: x, y: y)].hasBeenUpdated = true
        }
    }
    
    func updateSalt(x: Int, y: Int, deltaTime: Float) {
        var particle = particles[computeIndex(x: x, y: y)]
        
        // 중력 적용
        particle.velocity.y = min(particle.velocity.y + (gravity * deltaTime), 10.0)
        particles[computeIndex(x: x, y: y)] = particle
        
        // 물에 닿으면 용해될 확률
        for dx in -1...1 {
            for dy in -1...1 {
                if dx == 0 && dy == 0 { continue }
                
                let nx = x + dx
                let ny = y + dy
                
                if inBounds(x: nx, y: ny) &&
                   particles[computeIndex(x: nx, y: ny)].type == .water &&
                   Float.random(in: 0...1) < 0.001 {
                    // 소금이 물에 용해됨
                    particles[computeIndex(x: x, y: y)] = Particle.empty()
                    colorBuffer[computeIndex(x: x, y: y)] = MaterialType.empty.defaultColor()
                    return
                }
            }
        }
        
        // 기본 중력 효과 (모래와 유사)
        if y + 1 >= gridHeight {
            particles[computeIndex(x: x, y: y)].hasBeenUpdated = true
            return
        }
        
        // 아래로 떨어짐
        if isEmpty(x: x, y: y + 1) {
            moveParticle(fromX: x, fromY: y, toX: x, toY: y + 1)
        }
        // 아래가 물이면 천천히 가라앉음
        else if inBounds(x: x, y: y + 1) &&
                particles[computeIndex(x: x, y: y + 1)].type == .water &&
                Float.random(in: 0...1) < 0.8 {
            moveParticle(fromX: x, fromY: y, toX: x, toY: y + 1)
        }
        // 왼쪽 아래로 떨어짐
        else if x > 0 && isEmpty(x: x - 1, y: y + 1) {
            moveParticle(fromX: x, fromY: y, toX: x - 1, toY: y + 1)
        }
        // 오른쪽 아래로 떨어짐
        else if x < gridWidth - 1 && isEmpty(x: x + 1, y: y + 1) {
            moveParticle(fromX: x, fromY: y, toX: x + 1, toY: y + 1)
        }
        else {
            particles[computeIndex(x: x, y: y)].hasBeenUpdated = true
        }
    }
    
    func updateFire(x: Int, y: Int, deltaTime: Float) {
        var particle = particles[computeIndex(x: x, y: y)]
        
        // 불은 위로 움직임
        particle.velocity.y = max(particle.velocity.y - (gravity * deltaTime * 0.2), -5.0)
        particle.velocity.x += Float.random(in: -0.5...0.5)
        particles[computeIndex(x: x, y: y)] = particle
        
        // 주변 타오를 수 있는 것 점화
        for dx in -1...1 {
            for dy in -1...1 {
                if dx == 0 && dy == 0 { continue }
                
                let nx = x + dx
                let ny = y + dy
                
                if !inBounds(x: nx, y: ny) { continue }
                
                let neighborType = particles[computeIndex(x: nx, y: ny)].type
                
                // 주변 재료가 타오를 수 있는지 확인
                if neighborType == .wood && Float.random(in: 0...1) < 0.01 {
                    // 나무에 불이 붙음
                    setParticle(x: nx, y: ny, particle: Particle.fire())
                }
                else if neighborType == .oil && Float.random(in: 0...1) < 0.2 {
                    // 기름에 불이 쉽게 붙음
                    setParticle(x: nx, y: ny, particle: Particle.fire())
                }
                else if neighborType == .gunpowder && Float.random(in: 0...1) < 0.5 {
                    // 화약은 즉시 불붙음
                    setParticle(x: nx, y: ny, particle: Particle.fire())
                }
            }
        }
        
        // 연기 및 불씨 생성
        if Float.random(in: 0...1) < 0.1 && inBounds(x: x, y: y - 1) && isEmpty(x: x, y: y - 1) {
            if Float.random(in: 0...1) < 0.7 {
                // 연기 생성
                setParticle(x: x, y: y - 1, particle: Particle.smoke())
            } else {
                // 불씨 생성
                setParticle(x: x, y: y - 1, particle: Particle.ember())
            }
        }
        
        // 물에 닿으면 소멸 및 증기 생성
        for dx in -1...1 {
            for dy in -1...1 {
                if dx == 0 && dy == 0 { continue }
                
                let nx = x + dx
                let ny = y + dy
                
                if inBounds(x: nx, y: ny) && particles[computeIndex(x: nx, y: ny)].type == .water {
                    // 불이 물에 닿아 증기 생성
                    setParticle(x: x, y: y, particle: Particle.steam())
                    // 일정 확률로 물도 증기로 변환
                    if Float.random(in: 0...1) < 0.5 {
                        setParticle(x: nx, y: ny, particle: Particle.steam())
                    }
                    return
                }
            }
        }
        
        // 기본 이동 로직
        let vx = Int(particle.velocity.x)
        let vy = Int(particle.velocity.y)
        
        if inBounds(x: x + vx, y: y + vy) && isEmpty(x: x + vx, y: y + vy) {
            moveParticle(fromX: x, fromY: y, toX: x + vx, toY: y + vy)
        }
        else if y > 0 && isEmpty(x: x, y: y - 1) {
            moveParticle(fromX: x, fromY: y, toX: x, toY: y - 1)
        }
        else if x > 0 && y > 0 && isEmpty(x: x - 1, y: y - 1) {
            moveParticle(fromX: x, fromY: y, toX: x - 1, toY: y - 1)
        }
        else if x < gridWidth - 1 && y > 0 && isEmpty(x: x + 1, y: y - 1) {
            moveParticle(fromX: x, fromY: y, toX: x + 1, toY: y - 1)
        }
        else {
            particles[computeIndex(x: x, y: y)].hasBeenUpdated = true
        }
    }
    
    func updateSmoke(x: Int, y: Int, deltaTime: Float) {
        var particle = particles[computeIndex(x: x, y: y)]
        
        // 연기는 위로 떠오름
        particle.velocity.y = max(particle.velocity.y - (gravity * deltaTime), -2.0)
        particle.velocity.x += Float.random(in: -0.3...0.3)
        particles[computeIndex(x: x, y: y)] = particle
        
        // 기본 이동 로직
        let vx = Int(particle.velocity.x)
        let vy = Int(particle.velocity.y)
        
        if inBounds(x: x + vx, y: y + vy) && isEmpty(x: x + vx, y: y + vy) {
            moveParticle(fromX: x, fromY: y, toX: x + vx, toY: y + vy)
        }
        else if y > 0 && isEmpty(x: x, y: y - 1) {
            moveParticle(fromX: x, fromY: y, toX: x, toY: y - 1)
        }
        else if x > 0 && y > 0 && isEmpty(x: x - 1, y: y - 1) {
            moveParticle(fromX: x, fromY: y, toX: x - 1, toY: y - 1)
        }
        else if x < gridWidth - 1 && y > 0 && isEmpty(x: x + 1, y: y - 1) {
            moveParticle(fromX: x, fromY: y, toX: x + 1, toY: y - 1)
        }
        else {
            particles[computeIndex(x: x, y: y)].hasBeenUpdated = true
        }
    }
    
    func updateEmber(x: Int, y: Int, deltaTime: Float) {
        var particle = particles[computeIndex(x: x, y: y)]
        
        // 불씨는 떠오르고 흔들림
        particle.velocity.y = max(particle.velocity.y - (gravity * deltaTime), -2.0)
        particle.velocity.x += Float.random(in: -0.5...0.5)
        particles[computeIndex(x: x, y: y)] = particle
        
        // 주변 나무에 불을 붙임
        for dx in -1...1 {
            for dy in -1...1 {
                if dx == 0 && dy == 0 { continue }
                
                let nx = x + dx
                let ny = y + dy
                
                if inBounds(x: nx, y: ny) &&
                   particles[computeIndex(x: nx, y: ny)].type == .wood &&
                   Float.random(in: 0...1) < 0.05 {
                    setParticle(x: nx, y: ny, particle: Particle.fire())
                }
            }
        }
        
        // 기본 이동 로직
        let vx = Int(particle.velocity.x)
        let vy = Int(particle.velocity.y)
        
        if inBounds(x: x + vx, y: y + vy) && isEmpty(x: x + vx, y: y + vy) {
            moveParticle(fromX: x, fromY: y, toX: x + vx, toY: y + vy)
        }
        else if y > 0 && isEmpty(x: x, y: y - 1) {
            moveParticle(fromX: x, fromY: y, toX: x, toY: y - 1)
        }
        else if x > 0 && y > 0 && isEmpty(x: x - 1, y: y - 1) {
            moveParticle(fromX: x, fromY: y, toX: x - 1, toY: y - 1)
        }
        else if x < gridWidth - 1 && y > 0 && isEmpty(x: x + 1, y: y - 1) {
            moveParticle(fromX: x, fromY: y, toX: x + 1, toY: y - 1)
        }
        else {
            particles[computeIndex(x: x, y: y)].hasBeenUpdated = true
        }
    }
    
    func updateSteam(x: Int, y: Int, deltaTime: Float) {
        var particle = particles[computeIndex(x: x, y: y)]
        
        // 증기는 위로 떠오름
        particle.velocity.y = max(particle.velocity.y - (gravity * deltaTime), -1.5)
        particle.velocity.x += Float.random(in: -0.2...0.2)
        particles[computeIndex(x: x, y: y)] = particle
        
        // 냉각되어 물로 변할 확률
        if Float.random(in: 0...1) < 0.001 {
            setParticle(x: x, y: y, particle: Particle.water())
            return
        }
        
        // 기본 이동 로직
        let vx = Int(particle.velocity.x)
        let vy = Int(particle.velocity.y)
        
        if inBounds(x: x + vx, y: y + vy) && isEmpty(x: x + vx, y: y + vy) {
            moveParticle(fromX: x, fromY: y, toX: x + vx, toY: y + vy)
        }
        else if y > 0 && isEmpty(x: x, y: y - 1) {
            moveParticle(fromX: x, fromY: y, toX: x, toY: y - 1)
        }
        else if x > 0 && y > 0 && isEmpty(x: x - 1, y: y - 1) {
            moveParticle(fromX: x, fromY: y, toX: x - 1, toY: y - 1)
        }
        else if x < gridWidth - 1 && y > 0 && isEmpty(x: x + 1, y: y - 1) {
            moveParticle(fromX: x, fromY: y, toX: x + 1, toY: y - 1)
        }
        else {
            particles[computeIndex(x: x, y: y)].hasBeenUpdated = true
        }
    }
    
    func updateGunpowder(x: Int, y: Int, deltaTime: Float) {
        // 화약은 기본적으로 모래처럼 움직임
        var particle = particles[computeIndex(x: x, y: y)]
        
        // 중력 적용
        particle.velocity.y = min(particle.velocity.y + (gravity * deltaTime), 10.0)
        particles[computeIndex(x: x, y: y)] = particle
        
        // 가까운 화재가 있는지 확인 (폭발)
        for dx in -2...2 {
            for dy in -2...2 {
                let nx = x + dx
                let ny = y + dy
                
                if !inBounds(x: nx, y: ny) { continue }
                
                let neighborType = particles[computeIndex(x: nx, y: ny)].type
                
                if neighborType == .fire || neighborType == .lava {
                    // 폭발! 주변에 불과 연기 생성
                    for ex in -3...3 {
                        for ey in -3...3 {
                            let explosionX = x + ex
                            let explosionY = y + ey
                            
                            if !inBounds(x: explosionX, y: explosionY) { continue }
                            
                            let distance = sqrt(Float(ex * ex + ey * ey))
                            
                            if distance < 3 {
                                if Float.random(in: 0...1) < 0.6 {
                                    setParticle(x: explosionX, y: explosionY, particle: Particle.fire())
                                } else if Float.random(in: 0...1) < 0.3 {
                                    setParticle(x: explosionX, y: explosionY, particle: Particle.smoke())
                                } else {
                                    setParticle(x: explosionX, y: explosionY, particle: Particle.ember())
                                }
                            }
                        }
                    }
                    return
                }
            }
        }
        
        // 기본 이동 (모래와 유사)
        if y + 1 >= gridHeight {
            particles[computeIndex(x: x, y: y)].hasBeenUpdated = true
            return
        }
        
        if isEmpty(x: x, y: y + 1) {
            moveParticle(fromX: x, fromY: y, toX: x, toY: y + 1)
        }
        else if x > 0 && isEmpty(x: x - 1, y: y + 1) {
            moveParticle(fromX: x, fromY: y, toX: x - 1, toY: y + 1)
        }
        else if x < gridWidth - 1 && isEmpty(x: x + 1, y: y + 1) {
            moveParticle(fromX: x, fromY: y, toX: x + 1, toY: y + 1)
        }
        else {
            particles[computeIndex(x: x, y: y)].hasBeenUpdated = true
        }
    }
    
    func updateOil(x: Int, y: Int, deltaTime: Float) {
        var particle = particles[computeIndex(x: x, y: y)]
        
        // 중력 적용 (물보다 약간 느리게)
        particle.velocity.y = min(particle.velocity.y + (gravity * deltaTime * 0.8), 8.0)
        particles[computeIndex(x: x, y: y)] = particle
        
        // 무작위로 색상 변화 (약간의 변화)
        if Int.random(in: 0...30) == 0 {
            let baseColor = MaterialType.oil.defaultColor()
            let variation = Float.random(in: 0...0.05)
            colorBuffer[computeIndex(x: x, y: y)].r = UInt8(clamp(Int(Float(baseColor.r) * (1.0 + variation)), min: 0, max: 255))
            colorBuffer[computeIndex(x: x, y: y)].g = UInt8(clamp(Int(Float(baseColor.g) * (1.0 + variation)), min: 0, max: 255))
            colorBuffer[computeIndex(x: x, y: y)].b = UInt8(clamp(Int(Float(baseColor.b) * (1.0 + variation)), min: 0, max: 255))
        }
        
        // 아래가 경계 밖이면 업데이트 표시
        if y + 1 >= gridHeight {
            particles[computeIndex(x: x, y: y)].hasBeenUpdated = true
            return
        }
        
        // 기본 중력 효과
        if isEmpty(x: x, y: y + 1) {
            moveParticle(fromX: x, fromY: y, toX: x, toY: y + 1)
        }
        // 아래쪽이 꽉 찬 경우, 왼쪽이나 오른쪽으로 퍼짐
        else if x > 0 && isEmpty(x: x - 1, y: y + 1) {
            moveParticle(fromX: x, fromY: y, toX: x - 1, toY: y + 1)
        }
        else if x < gridWidth - 1 && isEmpty(x: x + 1, y: y + 1) {
            moveParticle(fromX: x, fromY: y, toX: x + 1, toY: y + 1)
        }
        // 물 위에 뜸
        else if inBounds(x: x, y: y + 1) && particles[computeIndex(x: x, y: y + 1)].type == .water {
            moveParticle(fromX: x, fromY: y, toX: x, toY: y + 1)
        }
        // 수평으로 퍼짐 (물의 특성)
        else if x > 0 && isEmpty(x: x - 1, y: y) {
            moveParticle(fromX: x, fromY: y, toX: x - 1, toY: y)
        }
        else if x < gridWidth - 1 && isEmpty(x: x + 1, y: y) {
            moveParticle(fromX: x, fromY: y, toX: x + 1, toY: y)
        }
        else {
            particles[computeIndex(x: x, y: y)].hasBeenUpdated = true
        }
    }
    
    func updateLava(x: Int, y: Int, deltaTime: Float) {
        var particle = particles[computeIndex(x: x, y: y)]
        
        // 중력 적용 (두껍고 느린 액체)
        particle.velocity.y = min(particle.velocity.y + (gravity * deltaTime * 0.5), 5.0)
        particles[computeIndex(x: x, y: y)] = particle
        
        // 무작위로 색상 변화 (용암 흐름 효과)
        if Int.random(in: 0...10) == 0 {
            let colors: [Color] = [
                Color(r: 255, g: 80, b: 20, a: 255),
                Color(r: 255, g: 100, b: 10, a: 255),
                Color(r: 255, g: 50, b: 0, a: 255),
                Color(r: 200, g: 50, b: 2, a: 255)
            ]
            colorBuffer[computeIndex(x: x, y: y)] = colors[Int.random(in: 0..<colors.count)]
        }
        
        // 주변 타오를 수 있는 것 점화 (용암은 불보다 더 확실하게 점화)
        for dx in -1...1 {
            for dy in -1...1 {
                if dx == 0 && dy == 0 { continue }
                
                let nx = x + dx
                let ny = y + dy
                
                if !inBounds(x: nx, y: ny) { continue }
                
                let neighborType = particles[computeIndex(x: nx, y: ny)].type
                
                // 주변 재료가 타오를 수 있는지 확인
                if neighborType == .wood && Float.random(in: 0...1) < 0.02 {
                    // 나무에 불이 붙음
                    setParticle(x: nx, y: ny, particle: Particle.fire())
                }
                else if neighborType == .oil && Float.random(in: 0...1) < 0.4 {
                    // 기름에 불이 쉽게 붙음
                    setParticle(x: nx, y: ny, particle: Particle.fire())
                }
                else if neighborType == .gunpowder && Float.random(in: 0...1) < 0.6 {
                    // 화약은 즉시 불붙음
                    setParticle(x: nx, y: ny, particle: Particle.fire())
                }
            }
        }
        
        // 불씨 및 연기 생성
        if Float.random(in: 0...1) < 0.05 && inBounds(x: x, y: y - 1) && isEmpty(x: x, y: y - 1) {
            if Float.random(in: 0...1) < 0.7 {
                // 연기 생성
                setParticle(x: x, y: y - 1, particle: Particle.smoke())
            } else {
                // 불씨 생성
                setParticle(x: x, y: y - 1, particle: Particle.ember())
            }
        }
        
        // 물에 닿으면 돌로 변환 및 증기 생성
        for dx in -1...1 {
            for dy in -1...1 {
                if dx == 0 && dy == 0 { continue }
                
                let nx = x + dx
                let ny = y + dy
                
                if inBounds(x: nx, y: ny) && particles[computeIndex(x: nx, y: ny)].type == .water {
                    // 용암이 물에 닿아 돌로 변환
                    setParticle(x: x, y: y, particle: Particle.stone())
                    // 물은 증기로 변환
                    setParticle(x: nx, y: ny, particle: Particle.steam())
                    return
                }
            }
        }
        
        // 기본 이동 로직 (느리게 흐름)
        if y + 1 >= gridHeight {
            particles[computeIndex(x: x, y: y)].hasBeenUpdated = true
            return
        }
        
        if isEmpty(x: x, y: y + 1) {
            moveParticle(fromX: x, fromY: y, toX: x, toY: y + 1)
        }
        else if x > 0 && isEmpty(x: x - 1, y: y + 1) {
            moveParticle(fromX: x, fromY: y, toX: x - 1, toY: y + 1)
        }
        else if x < gridWidth - 1 && isEmpty(x: x + 1, y: y + 1) {
            moveParticle(fromX: x, fromY: y, toX: x + 1, toY: y + 1)
        }
        // 용암은 물보다 느리게 퍼짐
        else if Float.random(in: 0...1) < 0.3 {  // 확률적으로만 수평 이동
            if x > 0 && isEmpty(x: x - 1, y: y) {
                moveParticle(fromX: x, fromY: y, toX: x - 1, toY: y)
            }
            else if x < gridWidth - 1 && isEmpty(x: x + 1, y: y) {
                moveParticle(fromX: x, fromY: y, toX: x + 1, toY: y)
            }
            else {
                particles[computeIndex(x: x, y: y)].hasBeenUpdated = true
            }
        }
        else {
            particles[computeIndex(x: x, y: y)].hasBeenUpdated = true
        }
    }
    
    func updateAcid(x: Int, y: Int, deltaTime: Float) {
        var particle = particles[computeIndex(x: x, y: y)]
        
        // 중력 적용
        particle.velocity.y = min(particle.velocity.y + (gravity * deltaTime), 10.0)
        particles[computeIndex(x: x, y: y)] = particle
        
        // 무작위로 색상 변화 (산성 효과)
        if Int.random(in: 0...20) == 0 {
            let baseColor = MaterialType.acid.defaultColor()
            let variation = Float.random(in: -0.1...0.1)
            colorBuffer[computeIndex(x: x, y: y)].r = UInt8(clamp(Int(Float(baseColor.r) * (1.0 + variation)), min: 0, max: 255))
            colorBuffer[computeIndex(x: x, y: y)].g = UInt8(clamp(Int(Float(baseColor.g) * (1.0 + variation)), min: 0, max: 255))
            colorBuffer[computeIndex(x: x, y: y)].b = UInt8(clamp(Int(Float(baseColor.b) * (1.0 + variation)), min: 0, max: 255))
        }
        
        // 주변 물질 용해
        for dx in -1...1 {
            for dy in -1...1 {
                if dx == 0 && dy == 0 { continue }
                
                let nx = x + dx
                let ny = y + dy
                
                if !inBounds(x: nx, y: ny) { continue }
                
                let neighborType = particles[computeIndex(x: nx, y: ny)].type
                
                // 다양한 물질에 대한 용해 확률
                var dissolveChance: Float = 0.0
                
                switch neighborType {
                case .wood: dissolveChance = 0.01
                case .stone: dissolveChance = 0.003
                case .sand: dissolveChance = 0.02
                case .salt: dissolveChance = 0.05
                default: dissolveChance = 0
                }
                
                if Float.random(in: 0...1) < dissolveChance {
                    // 물질 용해
                    setParticle(x: nx, y: ny, particle: Particle.acid())
                    
                    // 산성도 감소 (산이 소비됨)
                    if Float.random(in: 0...1) < 0.2 {
                        setParticle(x: x, y: y, particle: Particle.empty())
                        return
                    }
                }
            }
        }
        
        // 물에 닿으면 희석
        for dx in -1...1 {
            for dy in -1...1 {
                if dx == 0 && dy == 0 { continue }
                
                let nx = x + dx
                let ny = y + dy
                
                if inBounds(x: nx, y: ny) && particles[computeIndex(x: nx, y: ny)].type == .water {
                    if Float.random(in: 0...1) < 0.1 {
                        // 산성이 희석됨
                        setParticle(x: x, y: y, particle: Particle.empty())
                        return
                    }
                }
            }
        }
        
        // 기본 이동 로직 (물과 유사)
        if y + 1 >= gridHeight {
            particles[computeIndex(x: x, y: y)].hasBeenUpdated = true
            return
        }
        
        if isEmpty(x: x, y: y + 1) {
            moveParticle(fromX: x, fromY: y, toX: x, toY: y + 1)
        }
        else if x > 0 && isEmpty(x: x - 1, y: y + 1) {
            moveParticle(fromX: x, fromY: y, toX: x - 1, toY: y + 1)
        }
        else if x < gridWidth - 1 && isEmpty(x: x + 1, y: y + 1) {
            moveParticle(fromX: x, fromY: y, toX: x + 1, toY: y + 1)
        }
        // 수평으로 퍼짐
        else if x > 0 && isEmpty(x: x - 1, y: y) {
            moveParticle(fromX: x, fromY: y, toX: x - 1, toY: y)
        }
        else if x < gridWidth - 1 && isEmpty(x: x + 1, y: y) {
            moveParticle(fromX: x, fromY: y, toX: x + 1, toY: y)
        }
        else {
            particles[computeIndex(x: x, y: y)].hasBeenUpdated = true
        }
    }
    
    // 추가 유틸리티 메서드
    
    // 주변 특정 타입 입자의 개수를 계산하는 함수
    func countNeighborsOfType(_ type: MaterialType, x: Int, y: Int, radius: Int = 1) -> Int {
        var count = 0
        
        for dy in -radius...radius {
            for dx in -radius...radius {
                if dx == 0 && dy == 0 { continue }
                
                let nx = x + dx
                let ny = y + dy
                
                if inBounds(x: nx, y: ny) && particles[computeIndex(x: nx, y: ny)].type == type {
                    count += 1
                }
            }
        }
        
        return count
    }
    
    // 주변에 특정 타입 입자가 있는지 확인하는 함수
    func hasNeighborOfType(_ type: MaterialType, x: Int, y: Int, radius: Int = 1) -> Bool {
        return countNeighborsOfType(type, x: x, y: y, radius: radius) > 0
    }
    
    // 입자가 완전히 둘러싸여 있는지 확인하는 함수
    func isParticleSurrounded(x: Int, y: Int) -> Bool {
        // 상하좌우 4방향 검사
        if inBounds(x: x, y: y - 1) && !isEmpty(x: x, y: y - 1) &&
           inBounds(x: x, y: y + 1) && !isEmpty(x: x, y: y + 1) &&
           inBounds(x: x - 1, y: y) && !isEmpty(x: x - 1, y: y) &&
           inBounds(x: x + 1, y: y) && !isEmpty(x: x + 1, y: y) {
            return true
        }
        return false
    }
    
    // 입자 이동 방향 결정 (중력 및 장애물 고려)
    func determineMovementDirection(x: Int, y: Int, particleType: MaterialType) -> (Int, Int)? {
        // 기본 방향 (화면 아래 방향)
        if particleType == .water || particleType == .oil || particleType == .acid ||
           particleType == .sand || particleType == .salt || particleType == .gunpowder {
            
            // 아래 확인
            if isEmpty(x: x, y: y + 1) {
                return (x, y + 1)
            }
            
            // 아래쪽이 막혀있으면 왼쪽이나 오른쪽 아래 확인
            let goLeft = Bool.random()
            
            if goLeft {
                if x > 0 && isEmpty(x: x - 1, y: y + 1) {
                    return (x - 1, y + 1)
                } else if x < gridWidth - 1 && isEmpty(x: x + 1, y: y + 1) {
                    return (x + 1, y + 1)
                }
            } else {
                if x < gridWidth - 1 && isEmpty(x: x + 1, y: y + 1) {
                    return (x + 1, y + 1)
                } else if x > 0 && isEmpty(x: x - 1, y: y + 1) {
                    return (x - 1, y + 1)
                }
            }
            
            // 액체는 수평 이동도 시도
            if particleType == .water || particleType == .oil || particleType == .acid {
                if goLeft {
                    if x > 0 && isEmpty(x: x - 1, y: y) {
                        return (x - 1, y)
                    } else if x < gridWidth - 1 && isEmpty(x: x + 1, y: y) {
                        return (x + 1, y)
                    }
                } else {
                    if x < gridWidth - 1 && isEmpty(x: x + 1, y: y) {
                        return (x + 1, y)
                    } else if x > 0 && isEmpty(x: x - 1, y: y) {
                        return (x - 1, y)
                    }
                }
            }
        }
        // 위로 상승하는 입자들 (연기, 증기, 불)
        else if particleType == .smoke || particleType == .steam ||
                particleType == .fire || particleType == .ember {
            
            // 위쪽 확인
            if isEmpty(x: x, y: y - 1) {
                return (x, y - 1)
            }
            
            // 위쪽이 막혀있으면 왼쪽이나 오른쪽 위 확인
            let goLeft = Bool.random()
            
            if goLeft {
                if x > 0 && isEmpty(x: x - 1, y: y - 1) {
                    return (x - 1, y - 1)
                } else if x < gridWidth - 1 && isEmpty(x: x + 1, y: y - 1) {
                    return (x + 1, y - 1)
                }
            } else {
                if x < gridWidth - 1 && isEmpty(x: x + 1, y: y - 1) {
                    return (x + 1, y - 1)
                } else if x > 0 && isEmpty(x: x - 1, y: y - 1) {
                    return (x - 1, y - 1)
                }
            }
            
            // 수평 이동 시도
            if goLeft {
                if x > 0 && isEmpty(x: x - 1, y: y) {
                    return (x - 1, y)
                } else if x < gridWidth - 1 && isEmpty(x: x + 1, y: y) {
                    return (x + 1, y)
                }
            } else {
                if x < gridWidth - 1 && isEmpty(x: x + 1, y: y) {
                    return (x + 1, y)
                } else if x > 0 && isEmpty(x: x - 1, y: y) {
                    return (x - 1, y)
                }
            }
        }
        
        // 이동할 수 없음
        return nil
    }
}
