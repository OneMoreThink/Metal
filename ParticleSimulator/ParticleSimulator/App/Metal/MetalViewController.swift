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
    
    // 터치 입력 관련 변수
    private var lastTouchPosition: CGPoint?
    private var touchActive: Bool = false
    
    // 버퍼
    private var particles = [Particle]()
    private var colorBuffer = [Color]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMetal()
        setupBuffers()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // 터치 입력을 위한 제스처 인식기 추가
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        metalView.addGestureRecognizer(panGesture)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
        metalView.addGestureRecognizer(tapGesture)
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
    
    // 연속적인 터치 이동 처리
    @objc private func handlePanGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
        switch gestureRecognizer.state {
        case .began:
            touchActive = true
            lastTouchPosition = gestureRecognizer.location(in: metalView)
            createParticlesAtPosition(position: lastTouchPosition!)
        case .changed:
            let currentPosition = gestureRecognizer.location(in: metalView)
            createParticlesAtPosition(position: currentPosition)
            
            // 빠른 움직임 중에도 부드러운 선을 위해 마지막 위치와 현재 위치 사이를 보간
            if let lastPosition = lastTouchPosition {
                interpolateParticles(from: lastPosition, to: currentPosition)
            }
            
            lastTouchPosition = currentPosition
        case .ended, .cancelled:
            touchActive = false
            lastTouchPosition = nil
        default:
            break
        }
    }
    
    // [추가] 단일 탭 처리
    @objc private func handleTapGesture(_ gestureRecognizer: UITapGestureRecognizer) {
        let tapPosition = gestureRecognizer.location(in: metalView)
        createParticlesAtPosition(position: tapPosition)
    }
    
    // [추가] 터치 위치에 입자 생성
    private func createParticlesAtPosition(position: CGPoint) {
        // 뷰 좌표를 그리드 좌표로 변환
        let gridX = Int((position.x / metalView.bounds.width) * CGFloat(gridWidth))
        let gridY = Int((position.y / metalView.bounds.height) * CGFloat(gridHeight))
        
        // 경계 내에 있는지 확인
        guard gridX >= 0 && gridX < gridWidth && gridY >= 0 && gridY < gridHeight else {
            return
        }
        
        // 더 자연스러운 느낌을 위해 터치 포인트 주변의 작은 반경에 입자 생성
        let radius = 2
        for offsetY in -radius...radius {
            for offsetX in -radius...radius {
                let x = gridX + offsetX
                let y = gridY + offsetY
                
                // 경계 확인
                if x >= 0 && x < gridWidth && y >= 0 && y < gridHeight {
                    let index = y * gridWidth + x
                    
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
    
    // [추가] 빠르게 드래그할 때 연속적인 입자 스트림을 만들기 위한 도우미 메소드
    private func interpolateParticles(from startPoint: CGPoint, to endPoint: CGPoint) {
        let distance = hypot(endPoint.x - startPoint.x, endPoint.y - startPoint.y)
        let steps = max(Int(distance / 2.0), 1) // 약 2픽셀마다 하나의 입자
        
        for step in 0..<steps {
            let progress = CGFloat(step) / CGFloat(steps)
            let interpolatedPoint = CGPoint(
                x: startPoint.x + (endPoint.x - startPoint.x) * progress,
                y: startPoint.y + (endPoint.y - startPoint.y) * progress
            )
            createParticlesAtPosition(position: interpolatedPoint)
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
