//
//  ViewController.swift
//  ParticleSimulator
//
//  Created by 이종선 on 3/20/25.
//

import UIKit
import MetalKit

class MetalViewController: UIViewController, MTKViewDelegate {
    
    // Metal 관련 객체
    private var device: MTLDevice!
    private var commandQueue: MTLCommandQueue!
    private var metalView: MTKView!
    private var pipelineState: MTLRenderPipelineState!
    private var vertexBuffer: MTLBuffer!
    private var texture: MTLTexture!
    
    // 시뮬레이션 매개변수
    private let gridWidth = 100
    private let gridHeight = 100
    private var frameCount = 0
    
    // 버퍼
    private var particles = [Particle]()
    private var colorBuffer = [Color]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMetal()
        setupBuffers()
    }
    
    private func setupMetal() {
        // Metal 디바이스 초기화
        device = MTLCreateSystemDefaultDevice()
        
        // Metal 뷰 설정
        metalView = MTKView(frame: view.bounds, device: device)
        metalView.delegate = self
        metalView.framebufferOnly = false
        metalView.clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        metalView.colorPixelFormat = .bgra8Unorm
        view.addSubview(metalView)
        
        // 커맨드 큐 생성
        commandQueue = device.makeCommandQueue()
        
        // 전체 화면 쿼드용 정점 데이터
        let vertexData: [Float] = [
            -1.0, -1.0, 0.0, 0.0, 1.0,  // 왼쪽 하단
             1.0, -1.0, 0.0, 1.0, 1.0,  // 오른쪽 하단
            -1.0,  1.0, 0.0, 0.0, 0.0,  // 왼쪽 상단
             1.0,  1.0, 0.0, 1.0, 0.0   // 오른쪽 상단
        ]
        
        // 정점 버퍼 생성
        vertexBuffer = device.makeBuffer(bytes: vertexData, length: vertexData.count * MemoryLayout<Float>.size, options: [])
        
        // 텍스처 생성
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba8Unorm,
            width: gridWidth,
            height: gridHeight,
            mipmapped: false
        )
        textureDescriptor.usage = [.shaderRead, .shaderWrite]
        texture = device.makeTexture(descriptor: textureDescriptor)!
        
        // 렌더 파이프라인 설정
        setupRenderPipeline()
    }
    
    private func setupRenderPipeline() {
        // 셰이더 라이브러리 생성
        let library = device.makeDefaultLibrary()
        
        // 셰이더 함수 가져오기
        let vertexFunction = library?.makeFunction(name: "vertexShader")
        let fragmentFunction = library?.makeFunction(name: "fragmentShader")
        
        // 렌더 파이프라인 디스크립터 설정
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = metalView.colorPixelFormat
        
        // 렌더 파이프라인 상태 생성
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            print("Failed to create pipeline state: \(error)")
        }
    }
    
    private func setupBuffers() {
        // 입자 데이터 초기화
        particles = [Particle](repeating: Particle(
            isEmpty: true,
            hasBeenUpdated: false
        ), count: gridWidth * gridHeight)
        
        // 색상 버퍼 초기화 (처음에는 모두 투명)
        colorBuffer = [Color](repeating: Color(r: 0, g: 0, b: 0, a: 0), count: gridWidth * gridHeight)
    }
    
    // 정중앙에 입자 생성
    private func createParticlesAtCenter() {
        let centerX = gridWidth / 2
        let centerY = gridHeight / 4  // 화면 상단 부분에 생성
        
        // 중앙에 하나의 입자만 생성
        let index = centerY * gridWidth + centerX
        
        // 이미 입자가 있는지 확인
        if particles[index].isEmpty {
            // 입자 생성
            particles[index] = Particle(isEmpty: false, hasBeenUpdated: false)
            
            // 모래 색상 설정
            colorBuffer[index] = Color(r: 220, g: 180, b: 80, a: 255)
        }
    }
    
    // 모래 입자 업데이트 (물리 시뮬레이션)
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
    
    // 입자 이동 헬퍼 함수
    private func moveParticle(fromIndex: Int, toIndex: Int) {
        // 1. 물리 데이터 이동
        particles[toIndex] = particles[fromIndex]
        particles[toIndex].hasBeenUpdated = true
        particles[fromIndex] = Particle(isEmpty: true, hasBeenUpdated: false)
        
        // 2. 색상 데이터 이동
        colorBuffer[toIndex] = colorBuffer[fromIndex]
        colorBuffer[fromIndex] = Color(r: 0, g: 0, b: 0, a: 0)
    }
    
    // 텍스처 업데이트
    private func updateTextureFromColorBuffer() {
        texture.replace(
            region: MTLRegionMake2D(0, 0, gridWidth, gridHeight),
            mipmapLevel: 0,
            withBytes: colorBuffer,
            bytesPerRow: gridWidth * MemoryLayout<Color>.stride
        )
    }
    
    // MARK: - MTKViewDelegate
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // 필요한 경우 뷰 크기 조정 처리
    }
    
    func draw(in view: MTKView) {
        // 프레임 카운터 증가
        frameCount += 1
        
        // 20프레임마다 새 입자 생성
        if frameCount % 20 == 0 {
            createParticlesAtCenter()
        }
        
        // 시뮬레이션 업데이트
        updateSandSimulation()
        
        // 텍스처 업데이트
        updateTextureFromColorBuffer()
        
        // 렌더링 시작
        guard let drawable = view.currentDrawable,
              let renderPassDescriptor = view.currentRenderPassDescriptor,
              let commandBuffer = commandQueue.makeCommandBuffer() else {
            return
        }
        
        // 렌더 인코더 생성
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return
        }
        
        // 렌더 파이프라인 상태 및 리소스 설정
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.setFragmentTexture(texture, index: 0)
        
        // 쿼드 그리기 (4개 정점)
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        
        // 인코딩 종료 및 표시
        renderEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
