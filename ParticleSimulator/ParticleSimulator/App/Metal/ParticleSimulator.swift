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
    
    // Metal 관련 객체
    private var device: MTLDevice
    private var computePipelineState: MTLComputePipelineState
    private var commandQueue: MTLCommandQueue
    
    // 버퍼
    private var particlesBuffer: MTLBuffer
    private var colorsBuffer: MTLBuffer
    private var paramsBuffer: MTLBuffer
    
    // 파라미터
    private var params: SimulationParams
    private var frameCount: UInt32 = 0
    
    // 입자 타입
    enum ParticleType: UInt32 {
        case empty = 0
        case sand = 1
        case water = 2
    }
    
    // MARK: - 초기화
    
    init(width: Int, height: Int, device: MTLDevice) {
        self.gridWidth = width
        self.gridHeight = height
        self.device = device
        
        // 초기 입자 및 색상 배열 생성
        var particles = [Particle]()
        var colors = [Color]()
        
        for _ in 0..<(width * height) {
            particles.append(Particle(isEmpty: 1, type: 0))
            colors.append(Color(r: 0, g: 0, b: 0, a: 0))
        }
        
        // Metal 버퍼 생성
        self.particlesBuffer = device.makeBuffer(bytes: particles,
                                              length: MemoryLayout<Particle>.stride * width * height,
                                              options: .storageModeShared)!
        
        self.colorsBuffer = device.makeBuffer(bytes: colors,
                                           length: MemoryLayout<Color>.stride * width * height,
                                           options: .storageModeShared)!
        
        // 시뮬레이션 파라미터 설정
        self.params = SimulationParams(width: UInt32(width), height: UInt32(height), frameCount: 0)
        self.paramsBuffer = device.makeBuffer(bytes: &self.params,
                                           length: MemoryLayout<SimulationParams>.size,
                                           options: .storageModeShared)!
        
        // 컴퓨트 파이프라인 설정
        let library = device.makeDefaultLibrary()!
        let computeFunction = library.makeFunction(name: "updateParticles")!
        
        do {
            self.computePipelineState = try device.makeComputePipelineState(function: computeFunction)
        } catch {
            fatalError("컴퓨트 파이프라인 생성 실패: \(error)")
        }
        
        // 커맨드 큐 생성
        self.commandQueue = device.makeCommandQueue()!
    }
    
    // MARK: - 공개 메서드
    
    /// GPU에서 시뮬레이션 업데이트
    func update() {
        // 프레임 카운트 증가
        frameCount += 1
        
        // 시뮬레이션 파라미터 업데이트
        var updatedParams = params
        updatedParams.frameCount = frameCount
        memcpy(paramsBuffer.contents(), &updatedParams, MemoryLayout<SimulationParams>.size)
        
        // 커맨드 버퍼 생성
        guard let commandBuffer = commandQueue.makeCommandBuffer() else { return }
        
        // 컴퓨트 인코더 생성
        guard let computeEncoder = commandBuffer.makeComputeCommandEncoder() else { return }
        
        // 파이프라인 상태 설정
        computeEncoder.setComputePipelineState(computePipelineState)
        
        // 리소스 연결
        computeEncoder.setBuffer(particlesBuffer, offset: 0, index: 0)
        computeEncoder.setBuffer(colorsBuffer, offset: 0, index: 1)
        computeEncoder.setBuffer(paramsBuffer, offset: 0, index: 2)
        
        // 스레드그룹 크기 계산
        let threadsPerThreadgroup = MTLSize(width: 16, height: 16, depth: 1)
        let threadgroupsPerGrid = MTLSize(
            width: (gridWidth + threadsPerThreadgroup.width - 1) / threadsPerThreadgroup.width,
            height: (gridHeight + threadsPerThreadgroup.height - 1) / threadsPerThreadgroup.height,
            depth: 1
        )
        
        // 디스패치
        computeEncoder.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        
        // 인코딩 종료
        computeEncoder.endEncoding()
        
        // 명령 실행
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
    }
    
    /// 지정된 위치에 입자 생성
    func createParticlesAt(x: Int, y: Int, radius: Int = 2) {
        // 범위 확인
        guard x >= 0 && x < gridWidth && y >= 0 && y < gridHeight else {
            return
        }
        
        // 포인터 얻기
        let particlesPtr = particlesBuffer.contents().bindMemory(to: Particle.self, capacity: gridWidth * gridHeight)
        let colorsPtr = colorsBuffer.contents().bindMemory(to: Color.self, capacity: gridWidth * gridHeight)
        
        // 지정된 반경 내의 입자 생성
        for offsetY in -radius...radius {
            for offsetX in -radius...radius {
                // 원형 모양으로 생성하기 위한 거리 계산
                let distance = sqrt(Float(offsetX * offsetX + offsetY * offsetY))
                if distance > Float(radius) {
                    continue
                }
                
                let posX = x + offsetX
                let posY = y + offsetY
                
                // 범위 확인
                if posX >= 0 && posX < gridWidth && posY >= 0 && posY < gridHeight {
                    let index = posY * gridWidth + posX
                    
                    // 빈 셀에만 모래 생성
                    if particlesPtr[index].isEmpty == 1 {
                        particlesPtr[index].isEmpty = 0
                        particlesPtr[index].type = ParticleType.sand.rawValue
                        
                        // 색상 변화를 위한 랜덤 값
                        let variation = UInt8.random(in: 0...30)
                        colorsPtr[index] = Color(
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
    
    /// 두 지점 사이에 입자 생성 (드래그)
    func createParticlesBetween(startX: Int, startY: Int, endX: Int, endY: Int) {
        let distance = hypot(Double(endX - startX), Double(endY - startY))
        let steps = max(Int(distance * 0.5), 1) // 약 2픽셀마다 하나의 입자
        
        for step in 0..<steps {
            let progress = Double(step) / Double(steps)
            let interpolatedX = Int(Double(startX) + Double(endX - startX) * progress)
            let interpolatedY = Int(Double(startY) + Double(endY - startY) * progress)
            createParticlesAt(x: interpolatedX, y: interpolatedY)
        }
    }
    
    /// 시뮬레이션 초기화
    func reset() {
        // 포인터 얻기
        let particlesPtr = particlesBuffer.contents().bindMemory(to: Particle.self, capacity: gridWidth * gridHeight)
        let colorsPtr = colorsBuffer.contents().bindMemory(to: Color.self, capacity: gridWidth * gridHeight)
        
        // 모든 입자 초기화
        for i in 0..<(gridWidth * gridHeight) {
            particlesPtr[i] = Particle(isEmpty: 1, type: 0)
            colorsPtr[i] = Color(r: 0, g: 0, b: 0, a: 0)
        }
    }
    
    // 색상 버퍼 포인터 얻기
    func getColorBufferPointer() -> UnsafeRawPointer {
        return UnsafeRawPointer(colorsBuffer.contents())
    }
}
