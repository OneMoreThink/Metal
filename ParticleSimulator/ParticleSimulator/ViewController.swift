//
//  ViewController.swift
//  ParticleSimulator
//
//  Created by 이종선 on 3/20/25.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        // Configure your view's appearance
        view.backgroundColor = .white
        
        // Add and configure subviews
        let label = UILabel()
        label.text = "Hello, UIKit!"
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        
        // Set constraints
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

}
