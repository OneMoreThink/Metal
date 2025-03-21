//
//  ViewController.swift
//  ParticleSimulator
//
//  Created by 이종선 on 3/20/25.
//

import UIKit
import MetalKit

class ViewController: UIViewController {
    private var metalView: MTKView!
    private var renderer: MetalRenderer!
    
    // 현재 선택된 입자 유형
    private var selectedParticleType: UInt32 = 1  // 기본값: 모래
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupMetalView()
        setupUI()
    }
    
    private func setupMetalView() {
        // Metal 뷰 생성
        metalView = MTKView(frame: view.bounds)
        metalView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(metalView)
        
        // 렌더러 초기화
        renderer = MetalRenderer(metalView: metalView)
        
        // 터치 제스처 추가
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        metalView.addGestureRecognizer(panGesture)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
        metalView.addGestureRecognizer(tapGesture)
    }
    
    private func setupUI() {
        // 입자 선택 세그먼트 컨트롤
        let segmentControl = UISegmentedControl(items: ["모래", "물"])
        segmentControl.selectedSegmentIndex = 0
        segmentControl.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)
        
        segmentControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(segmentControl)
        
        NSLayoutConstraint.activate([
            segmentControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            segmentControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segmentControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
        
        // 초기화 버튼
        let clearButton = UIButton(type: .system)
        clearButton.setTitle("초기화", for: .normal)
        clearButton.addTarget(self, action: #selector(clearButtonTapped), for: .touchUpInside)
        
        clearButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(clearButton)
        
        NSLayoutConstraint.activate([
            clearButton.topAnchor.constraint(equalTo: segmentControl.bottomAnchor, constant: 8),
            clearButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }
    
    // 세그먼트 컨트롤 값 변경 처리
    @objc private func segmentChanged(_ sender: UISegmentedControl) {
        selectedParticleType = UInt32(sender.selectedSegmentIndex + 1)
    }
    
    // 초기화 버튼 처리
    @objc private func clearButtonTapped() {
        // 구현 예정
    }
    
    // 탭 제스처 처리
    @objc private func handleTapGesture(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: metalView)
        addParticleAt(location: location)
    }
    
    // 팬 제스처 처리
    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: metalView)
        addParticleAt(location: location)
    }
    
    // 위치에 입자 추가
    private func addParticleAt(location: CGPoint) {
        let normalizedX = Float(location.x / metalView.bounds.width)
        let normalizedY = Float(location.y / metalView.bounds.height)
        
        // 여러 입자 추가 (브러시 효과)
        for _ in 0..<5 {
            // 약간의 랜덤 오프셋 추가
            let offsetX = Float.random(in: -0.01...0.01)
            let offsetY = Float.random(in: -0.01...0.01)
            
            renderer.addParticle(
                at: SIMD2<Float>(normalizedX + offsetX, normalizedY + offsetY),
                type: selectedParticleType
            )
        }
    }
}
