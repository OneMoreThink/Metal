//
//  MaterialSelectorView.swift
//  ParticleSimulator
//
//  Created by 이종선 on 4/1/25.
//

import UIKit

protocol MaterialSelectorDelegate: AnyObject {
    func didSelectMaterial(_ material: MaterialType)
}

class MaterialSelectorView: UIView {
    
    // 현재 선택된 재료
    private var selectedMaterial: MaterialType = .sand
    
    // 재료 선택 델리게이트
    weak var delegate: MaterialSelectorDelegate?
    
    // 재료 버튼 목록
    private var materialButtons: [UIButton] = []
    
    // 재료들
    private let materials: [(MaterialType, String)] = [
        (.sand, "모래"),
        (.water, "물"),
        (.salt, "소금"),
        (.wood, "나무"),
        (.fire, "불"),
        (.smoke, "연기"),
        (.steam, "증기"),
        (.gunpowder, "화약"),
        (.oil, "기름"),
        (.lava, "용암"),
        (.stone, "돌"),
        (.acid, "산성")
    ]
    
    // 현재 선택된 재료 표시 레이블
    private let currentMaterialLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        backgroundColor = UIColor(white: 0.1, alpha: 0.7)
        layer.cornerRadius = 10
        
        // 스크롤 뷰 설정
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsHorizontalScrollIndicator = false
        addSubview(scrollView)
        
        // 현재 재료 레이블 설정
        currentMaterialLabel.translatesAutoresizingMaskIntoConstraints = false
        currentMaterialLabel.text = "현재 재료: 모래"
        currentMaterialLabel.textColor = .white
        currentMaterialLabel.textAlignment = .center
        currentMaterialLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        addSubview(currentMaterialLabel)
        
        // 스택 뷰 설정
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = 10
        stackView.alignment = .center
        stackView.distribution = .fillEqually
        scrollView.addSubview(stackView)
        
        // 재료 버튼 생성
        for (material, title) in materials {
            let button = createMaterialButton(material: material, title: title)
            stackView.addArrangedSubview(button)
            materialButtons.append(button)
        }
        
        // 제약 조건 설정
        NSLayoutConstraint.activate([
            currentMaterialLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            currentMaterialLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            currentMaterialLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            scrollView.topAnchor.constraint(equalTo: currentMaterialLabel.bottomAnchor, constant: 8),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        ])
        
        // 처음 선택된 재료 표시
        updateSelectedMaterial(.sand)
    }
    
    private func createMaterialButton(material: MaterialType, title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        // 버튼 설정
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        button.setTitleColor(.white, for: .normal)
        
        // 버튼 스타일
        button.backgroundColor = getColorForMaterial(material)
        button.layer.cornerRadius = 20
        button.layer.borderWidth = 2
        button.layer.borderColor = UIColor.clear.cgColor
        
        // 크기 설정
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 60),
            button.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        // 액션 설정
        button.tag = materials.firstIndex(where: { $0.0 == material }) ?? 0
        button.addTarget(self, action: #selector(materialButtonTapped(_:)), for: .touchUpInside)
        
        return button
    }
    
    @objc private func materialButtonTapped(_ sender: UIButton) {
        guard sender.tag < materials.count else { return }
        
        let material = materials[sender.tag].0
        updateSelectedMaterial(material)
        delegate?.didSelectMaterial(material)
    }
    
    private func updateSelectedMaterial(_ material: MaterialType) {
        selectedMaterial = material
        
        // 모든 버튼의 보더 초기화
        for button in materialButtons {
            button.layer.borderColor = UIColor.clear.cgColor
        }
        
        // 선택된 버튼에 보더 표시
        if let index = materials.firstIndex(where: { $0.0 == material }) {
            materialButtons[index].layer.borderColor = UIColor.white.cgColor
        }
        
        // 레이블 업데이트
        if let materialName = materials.first(where: { $0.0 == material })?.1 {
            currentMaterialLabel.text = "현재 재료: \(materialName)"
        }
    }
    
    private func getColorForMaterial(_ material: MaterialType) -> UIColor {
        let color = material.defaultColor()
        return UIColor(
            red: CGFloat(color.r) / 255.0,
            green: CGFloat(color.g) / 255.0,
            blue: CGFloat(color.b) / 255.0,
            alpha: CGFloat(color.a) / 255.0
        )
    }
}
