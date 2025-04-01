//
//  ViewController.swift
//  ParticleSimulator
//
//  Created by 이종선 on 3/20/25.
//

import UIKit
import MetalKit

class MetalViewController: UIViewController {
    
    // Metal 관련 객체
    private var device: MTLDevice!
    private var commandQueue: MTLCommandQueue!
    private var renderPipelineState: MTLRenderPipelineState!
    private var vertexBuffer: MTLBuffer!
    private var texture: MTLTexture!
    
    // 시뮬레이션 매개변수
    private let gridWidth = 100
    private let gridHeight = 100
    
    // 시뮬레이션 객체
    private var simulator: ParticleSimulator!
    
    // 터치 입력 관련 변수
    private var lastTouchPosition: CGPoint?
    private var touchActive: Bool = false
    
    // 분리된 메인 뷰
    private var simulatorView: ParticleSimulatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        setupMetal()
        setupSimulator()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // 터치 입력을 위한 제스처 인식기 추가
        simulatorView.setupGestureRecognizers()
    }
    
// MARK: - 시뮬레이터 초기 설정 메서드
    // 메인 시뮬레이터 뷰 생성 및 설정
    private func setupView() {
        simulatorView = ParticleSimulatorView(frame: view.bounds)
        simulatorView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        simulatorView.delegate = self
        view.addSubview(simulatorView)
    }
    
    // Metal device 설정
    private func setupMetal() {
        // Metal 디바이스 초기화
        device = MTLCreateSystemDefaultDevice()
        
        // 커맨드 큐 생성
        commandQueue = device.makeCommandQueue()
        
        // MTKView 참조 가져오기
        let metalView = simulatorView.metalView
        metalView?.delegate = self
        
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
        
        setupRenderPipeline()
    }
    
    // 렌더 파이프라인 설정
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
        pipelineDescriptor.colorAttachments[0].pixelFormat = simulatorView.metalView.colorPixelFormat
        
        // 렌더 파이프라인 상태 생성
        do {
            renderPipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            print("파이프라인 상태 생성 실패: \(error)")
        }
    }
    
    // 시뮬레이터(물리 동작 계산) 설정
    private func setupSimulator() {
        // GPU 기반 입자 시뮬레이터 초기화
        simulator = ParticleSimulator(width: gridWidth, height: gridHeight, device: device)
    }
    
// MARK: - 입자 생성 관련 메서드 ( View -> Controller -> Simulator )
    // 터치 위치에 입자 생성
    private func createParticlesAtPosition(position: CGPoint) {
        // 뷰 좌표를 그리드 좌표로 변환
        let gridX = Int((position.x / simulatorView.metalView.bounds.width) * CGFloat(gridWidth))
        let gridY = Int((position.y / simulatorView.metalView.bounds.height) * CGFloat(gridHeight))
        
        // 경계 내에 있는지 확인
        guard gridX >= 0 && gridX < gridWidth && gridY >= 0 && gridY < gridHeight else {
            return
        }
        
        // 시뮬레이터에 입자 생성 요청
        simulator.createParticlesAt(x: gridX, y: gridY)
    }
    
    // 빠르게 드래그할 때 연속적인 입자 스트림을 만들기 위한 도우미 메소드
    private func interpolateParticles(from startPoint: CGPoint, to endPoint: CGPoint) {
        // 뷰 좌표를 그리드 좌표로 변환
        let startGridX = Int((startPoint.x / simulatorView.metalView.bounds.width) * CGFloat(gridWidth))
        let startGridY = Int((startPoint.y / simulatorView.metalView.bounds.height) * CGFloat(gridHeight))
        let endGridX = Int((endPoint.x / simulatorView.metalView.bounds.width) * CGFloat(gridWidth))
        let endGridY = Int((endPoint.y / simulatorView.metalView.bounds.height) * CGFloat(gridHeight))
        
        // 시뮬레이터에서 두 지점 사이에 입자 생성
        simulator.createParticlesBetween(startX: startGridX, startY: startGridY, endX: endGridX, endY: endGridY)
    }
    
    // 텍스처 업데이트
    private func updateTextureFromColorBuffer() {
        // 색상 버퍼의 포인터 가져오기
        let colorBufferPtr = simulator.getColorBufferPointer()
        
        // 텍스처 리전 업데이트
        texture.replace(
            region: MTLRegionMake2D(0, 0, gridWidth, gridHeight),
            mipmapLevel: 0,
            withBytes: colorBufferPtr,
            bytesPerRow: gridWidth * MemoryLayout<Color>.stride
        )
    }
}

// MARK: - MTKViewDelegate
extension MetalViewController: MTKViewDelegate {
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // 필요한 경우 뷰 크기 조정 처리
    }
    
    func draw(in view: MTKView) {
        // GPU에서 시뮬레이션 업데이트
        simulator.update()
        
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
        renderEncoder.setRenderPipelineState(renderPipelineState)
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

// MARK: - ParticleSimulatorViewDelegate
extension MetalViewController: ParticleSimulatorViewDelegate {
    func didTapResetButton() {
        // 시뮬레이션 초기화
        simulator.reset()
    }
    
    func handlePanGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
        switch gestureRecognizer.state {
        case .began:
            touchActive = true
            lastTouchPosition = gestureRecognizer.location(in: simulatorView.metalView)
            createParticlesAtPosition(position: lastTouchPosition!)
            
        case .changed:
            let currentPosition = gestureRecognizer.location(in: simulatorView.metalView)
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
    
    func handleTapGesture(_ gestureRecognizer: UITapGestureRecognizer) {
        let tapPosition = gestureRecognizer.location(in: simulatorView.metalView)
        createParticlesAtPosition(position: tapPosition)
    }
}
