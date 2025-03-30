//
//  ViewController.swift
//  ParticleSimulator
//
//  Created by 이종선 on 3/20/25.
//

import UIKit
import MetalKit

class MetalViewController: UIViewController {
    
    // Metal 관련 객체들
    private var metalDevice: MTLDevice!
    private var metalCommandQueue: MTLCommandQueue!
    private var metalView: MTKView!
    private var pipelineState: MTLRenderPipelineState!
    private var vertexBuffer: MTLBuffer!
    
    // 화면에 그릴 삼각형 정점 데이터
    private let vertices: [Float] = [
        0.0,  0.5, 0.0,    1.0, 0.0, 0.0, 1.0,  // 상단 정점 (빨간색)
       -0.5, -0.5, 0.0,    0.0, 1.0, 0.0, 1.0,  // 좌측 하단 정점 (녹색)
        0.5, -0.5, 0.0,    0.0, 0.0, 1.0, 1.0,  // 우측 하단 정점 (파란색)
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMetal()
    }
    
    private func setupMetal() {
        // 1. Metal 디바이스 생성
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("GPU가 Metal을 지원하지 않습니다")
        }
        metalDevice = device
        
        // 2. Metal 뷰 설정
        metalView = MTKView(frame: view.bounds, device: metalDevice)
        metalView.colorPixelFormat = .bgra8Unorm
        metalView.clearColor = MTLClearColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
        view.addSubview(metalView)
        
        // Metal 뷰가 화면 크기에 맞게 자동으로 조정되도록 설정
        metalView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            metalView.topAnchor.constraint(equalTo: view.topAnchor),
            metalView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            metalView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            metalView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        // 3. 커맨드 큐 생성
        metalCommandQueue = metalDevice.makeCommandQueue()
        
        // 4. 렌더링 파이프라인 설정
        setupRenderPipeline()
        
        // 5. 정점 버퍼 생성
        let dataSize = vertices.count * MemoryLayout<Float>.size
        vertexBuffer = metalDevice.makeBuffer(bytes: vertices, length: dataSize, options: [])
        
        // 6. 델리게이트 설정 및 렌더링 시작
        metalView.delegate = self
    }
    
    private func setupRenderPipeline() {
        // Metal 쉐이더 라이브러리 로드
        guard let library = metalDevice.makeDefaultLibrary() else {
            fatalError("Metal 쉐이더 라이브러리를 로드할 수 없습니다")
        }
        
        // 정점 및 프래그먼트 쉐이더 함수 참조
        let vertexFunction = library.makeFunction(name: "vertexShader")
        let fragmentFunction = library.makeFunction(name: "fragmentShader")
        
        // 렌더 파이프라인 디스크립터 설정
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = metalView.colorPixelFormat
        
        // 파이프라인 상태 객체 생성
        do {
            pipelineState = try metalDevice.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch let error {
            fatalError("파이프라인 상태 생성 실패: \(error.localizedDescription)")
        }
    }
}

// MARK: - MTKViewDelegate 확장
extension MetalViewController: MTKViewDelegate {
    // 뷰 크기 변경 시 호출
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // 여기서 필요한 경우 뷰포트나 프로젝션 매트릭스 업데이트
    }
    
    // 매 프레임마다 호출되는 렌더링 함수
    func draw(in view: MTKView) {
        // 현재 드로어블 및 패스 디스크립터 가져오기
        guard let drawable = view.currentDrawable,
              let renderPassDescriptor = view.currentRenderPassDescriptor else {
            return
        }
        
        // 커맨드 버퍼 생성
        guard let commandBuffer = metalCommandQueue.makeCommandBuffer() else {
            return
        }
        
        // 렌더 커맨드 인코더 생성
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return
        }
        
        // 렌더링 명령 인코딩
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        
        // 인코딩 종료
        renderEncoder.endEncoding()
        
        // 드로어블에 표시하도록 예약
        commandBuffer.present(drawable)
        
        // 커맨드 버퍼 커밋
        commandBuffer.commit()
    }
}
