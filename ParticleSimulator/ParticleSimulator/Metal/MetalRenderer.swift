//
//  MetalRenderer.swift
//  ParticleSimulator
//
//  Created by 이종선 on 3/20/25.
//

import MetalKit
import simd

class MetalRenderer: NSObject {
    // Metal 객체
    private var device: MTLDevice!
    private var commandQueue: MTLCommandQueue!
    
    // 렌더링 파이프라인
    private var renderPipelineState: MTLRenderPipelineState!
    private var computePipelineState: MTLComputePipelineState!
    
    // 버퍼 및 텍스처
    private var vertexBuffer: MTLBuffer!
    private var indexBuffer: MTLBuffer!
    private var particleBuffer: MTLBuffer!
    private var simulationParamsBuffer: MTLBuffer!
    private var particleTexture: MTLTexture!
    
    // 시뮬레이션 상수
    private let gridWidth: UInt32 = 256
    private let gridHeight: UInt32 = 256
    private var gravity: Float = 9.8
    
    // 시뮬레이션 파라미터 구조체
    struct SimulationParams {
        var deltaTime: Float = 0.0
        var gravity: Float = 9.8
        var gridWidth: UInt32 = 0
        var gridHeight: UInt32 = 0
    }
    
    // 입자 구조체
    struct Particle {
        var position: SIMD2<Float> = SIMD2<Float>(0, 0)
        var velocity: SIMD2<Float> = SIMD2<Float>(0, 0)
        var color: SIMD4<Float> = SIMD4<Float>(0, 0, 0, 0)
        var materialType: UInt32 = 0
        var lifetime: Float = 0.0
        var padding: UInt32 = 0
    }
    
    // 정점 구조체
    struct Vertex {
        var position: SIMD2<Float>
        var texCoord: SIMD2<Float>
    }
    
    // 초기화
    init(metalView: MTKView) {
        super.init()
        
        setupMetal(metalView: metalView)
        createBuffers()
        createPipelines(metalView: metalView)
    }
    
    // Metal 설정
    private func setupMetal(metalView: MTKView) {
        // Metal 디바이스 생성
        device = MTLCreateSystemDefaultDevice()
        metalView.device = device
        
        // 명령 큐 생성
        commandQueue = device.makeCommandQueue()
        
        // 텍스처 포맷 설정
        metalView.colorPixelFormat = .rgba8Unorm
        metalView.framebufferOnly = false
        
        // 델리게이트 설정
        metalView.delegate = self
    }
    
    // 버퍼 생성
    private func createBuffers() {
        // 쿼드 정점 데이터 (전체 화면)
        let vertices: [Vertex] = [
            Vertex(position: SIMD2<Float>(-1, -1), texCoord: SIMD2<Float>(0, 1)),
            Vertex(position: SIMD2<Float>( 1, -1), texCoord: SIMD2<Float>(1, 1)),
            Vertex(position: SIMD2<Float>(-1,  1), texCoord: SIMD2<Float>(0, 0)),
            Vertex(position: SIMD2<Float>( 1,  1), texCoord: SIMD2<Float>(1, 0))
        ]
        
        // 인덱스 데이터
        let indices: [UInt16] = [
            0, 1, 2,
            2, 1, 3
        ]
        
        // 버퍼 생성
        vertexBuffer = device.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout<Vertex>.stride, options: [])
        indexBuffer = device.makeBuffer(bytes: indices, length: indices.count * MemoryLayout<UInt16>.stride, options: [])
        
        // 입자 버퍼 초기화
        let particleCount = Int(gridWidth * gridHeight)
        var particles = [Particle](repeating: Particle(), count: particleCount)
        particleBuffer = device.makeBuffer(bytes: particles, length: particleCount * MemoryLayout<Particle>.stride, options: [])
        
        // 시뮬레이션 파라미터 버퍼 초기화
        var params = SimulationParams(deltaTime: 0.016, gravity: gravity, gridWidth: gridWidth, gridHeight: gridHeight)
        simulationParamsBuffer = device.makeBuffer(bytes: &params, length: MemoryLayout<SimulationParams>.stride, options: [])
        
        // 입자 텍스처 생성
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba8Unorm,
            width: Int(gridWidth),
            height: Int(gridHeight),
            mipmapped: false)
        textureDescriptor.usage = [.shaderRead, .shaderWrite]
        particleTexture = device.makeTexture(descriptor: textureDescriptor)!
    }
    
    // 렌더링 및 컴퓨트 파이프라인 생성
    private func createPipelines(metalView: MTKView) {
        // 라이브러리 로드
        guard let library = device.makeDefaultLibrary() else {
            fatalError("Unable to create default Metal library")
        }
        
        // 렌더 파이프라인 생성
        let vertexFunction = library.makeFunction(name: "vertexShader")
        let fragmentFunction = library.makeFunction(name: "fragmentShader")
        
        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.vertexFunction = vertexFunction
        renderPipelineDescriptor.fragmentFunction = fragmentFunction
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = metalView.colorPixelFormat
        // 정점 디스크립터 생성 및 설정
        let vertexDescriptor = MTLVertexDescriptor()
        // position 속성 (SIMD2<Float>)
        vertexDescriptor.attributes[0].format = .float2
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        
        // texCoord 속성 (SIMD2<Float>)
        vertexDescriptor.attributes[1].format = .float2
        vertexDescriptor.attributes[1].offset = MemoryLayout<SIMD2<Float>>.stride
        vertexDescriptor.attributes[1].bufferIndex = 0
        
        // 버퍼 레이아웃 설정
        vertexDescriptor.layouts[0].stride = MemoryLayout<Vertex>.stride
        vertexDescriptor.layouts[0].stepFunction = .perVertex
        
        // 파이프라인에 정점 디스크립터 설정
        renderPipelineDescriptor.vertexDescriptor = vertexDescriptor
        
        do {
            renderPipelineState = try device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
        } catch {
            fatalError("Failed to create render pipeline state: \(error)")
        }
        
        do {
            renderPipelineState = try device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
        } catch {
            fatalError("Failed to create render pipeline state: \(error)")
        }
        
        // 컴퓨트 파이프라인 생성
        guard let computeFunction = library.makeFunction(name: "updateParticles") else {
            fatalError("Unable to create compute function")
        }
        
        do {
            computePipelineState = try device.makeComputePipelineState(function: computeFunction)
        } catch {
            fatalError("Failed to create compute pipeline state: \(error)")
        }
    }
    
    // 입자 데이터 업데이트
    func updateParticles(deltaTime: Float) {
        // 시뮬레이션 파라미터 업데이트
        var params = SimulationParams(deltaTime: deltaTime, gravity: gravity, gridWidth: gridWidth, gridHeight: gridHeight)
        memcpy(simulationParamsBuffer.contents(), &params, MemoryLayout<SimulationParams>.stride)
    }
    
    // 특정 위치에 입자 추가
    func addParticle(at position: SIMD2<Float>, type: UInt32) {
         let contents = particleBuffer.contents().bindMemory(to: Particle.self, capacity: Int(gridWidth * gridHeight))
        
        // 격자 좌표로 변환
        let x = Int(position.x * Float(gridWidth))
        let y = Int(position.y * Float(gridHeight))
        
        // 범위 검사
        guard x >= 0 && x < Int(gridWidth) && y >= 0 && y < Int(gridHeight) else {
            return
        }
        
        let index = y * Int(gridWidth) + x
        
        // 모래 입자 생성
        if type == 1 { // 모래 유형
            contents[index].position = SIMD2<Float>(Float(x), Float(y))
            contents[index].velocity = SIMD2<Float>(0, 0)
            contents[index].color = SIMD4<Float>(0.8, 0.7, 0.3, 1.0) // 모래 색상
            contents[index].materialType = type
            contents[index].lifetime = 0
        }
        // 물 입자 생성
        else if type == 2 { // 물 유형
            contents[index].position = SIMD2<Float>(Float(x), Float(y))
            contents[index].velocity = SIMD2<Float>(0, 0)
            contents[index].color = SIMD4<Float>(0.2, 0.4, 0.8, 0.8) // 물 색상
            contents[index].materialType = type
            contents[index].lifetime = 0
        }
    }
}

// MetalKit 뷰 델리게이트 확장
extension MetalRenderer: MTKViewDelegate {
    // 화면 업데이트 (드로우 콜)
    func draw(in view: MTKView) {
        guard let commandBuffer = commandQueue.makeCommandBuffer() else { return }
        
        // 시뮬레이션 업데이트
        updateParticles(deltaTime: 1/60)
        
        // 컴퓨트 패스 (입자 업데이트)
        if let computeEncoder = commandBuffer.makeComputeCommandEncoder() {
            computeEncoder.setComputePipelineState(computePipelineState)
            computeEncoder.setBuffer(particleBuffer, offset: 0, index: 0)
            computeEncoder.setBuffer(simulationParamsBuffer, offset: 0, index: 1)
            computeEncoder.setTexture(particleTexture, index: 0)
            
            // 스레드 그룹 크기 설정
            let threadsPerGroup = MTLSize(width: 16, height: 16, depth: 1)
            let threadGroups = MTLSize(
                width: (Int(gridWidth) + threadsPerGroup.width - 1) / threadsPerGroup.width,
                height: (Int(gridHeight) + threadsPerGroup.height - 1) / threadsPerGroup.height,
                depth: 1)
            
            computeEncoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadsPerGroup)
            computeEncoder.endEncoding()
        }
        
        // 렌더 패스 (화면에 텍스처 표시)
        guard let renderPassDescriptor = view.currentRenderPassDescriptor,
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return
        }
        
        renderEncoder.setRenderPipelineState(renderPipelineState)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.setFragmentTexture(particleTexture, index: 0)
        
        renderEncoder.drawIndexedPrimitives(
            type: .triangle,
            indexCount: 6,
            indexType: .uint16,
            indexBuffer: indexBuffer,
            indexBufferOffset: 0)
        
        renderEncoder.endEncoding()
        
        if let drawable = view.currentDrawable {
            commandBuffer.present(drawable)
        }
        
        commandBuffer.commit()
    }
    
    // 뷰 크기 변경 처리
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // 필요한 경우 여기서 처리
    }
}
