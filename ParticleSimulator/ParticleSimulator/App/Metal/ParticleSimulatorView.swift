//
//  ParticleSimulatorView.swift
//  ParticleSimulator
//
//  Created by 이종선 on 4/1/25.
//

import UIKit
import MetalKit

// Delegate protocol for handling view interactions
protocol ParticleSimulatorViewDelegate: AnyObject {
    func didTapResetButton()
    func handlePanGesture(_ gestureRecognizer: UIPanGestureRecognizer)
    func handleTapGesture(_ gestureRecognizer: UITapGestureRecognizer)
}

class ParticleSimulatorView: UIView {
    
    // Metal View
    var metalView: MTKView!
    
    // Reset Button
    private var resetButton: UIButton!
    
    // Delegate for reset action
    weak var delegate: ParticleSimulatorViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        backgroundColor = .black
        
        // Setup Metal View
        if let device = MTLCreateSystemDefaultDevice() {
            metalView = MTKView(frame: bounds, device: device)
            metalView.framebufferOnly = false
            metalView.clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
            metalView.colorPixelFormat = .bgra8Unorm
            metalView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            addSubview(metalView)
        }
        
        // Setup Reset Button
        setupResetButton()
    }
    
    private func setupResetButton() {
        // Create reset button
        resetButton = UIButton(type: .system)
        resetButton.translatesAutoresizingMaskIntoConstraints = false
        resetButton.backgroundColor = UIColor(white: 0.2, alpha: 0.7)
        resetButton.layer.cornerRadius = 20
        
        // Set button title
        resetButton.setTitle("Reset", for: .normal)
        resetButton.setTitleColor(.white, for: .normal)
        resetButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        
        // Add button to view hierarchy
        addSubview(resetButton)
        
        // Configure button constraints
        NSLayoutConstraint.activate([
            resetButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 16),
            resetButton.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -16),
            resetButton.widthAnchor.constraint(equalToConstant: 80),
            resetButton.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        // Add button action
        resetButton.addTarget(self, action: #selector(resetButtonTapped), for: .touchUpInside)
    }
    
    @objc private func resetButtonTapped() {
        delegate?.didTapResetButton()
    }
    
    // Add gesture recognizers to the metal view
    func setupGestureRecognizers() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        metalView.addGestureRecognizer(panGesture)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
        metalView.addGestureRecognizer(tapGesture)
    }
    
    // Forward gesture handling to delegate
    @objc private func handlePanGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
        delegate?.handlePanGesture(gestureRecognizer)
    }
    
    @objc private func handleTapGesture(_ gestureRecognizer: UITapGestureRecognizer) {
        delegate?.handleTapGesture(gestureRecognizer)
    }
}
