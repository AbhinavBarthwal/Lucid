//
//  PreviousConditionsViewController.swift
//  Lucid
//
//  Created by GEU on 09/03/26.
//

import UIKit
import SwiftUI

protocol PreviousConditionsDelegate: AnyObject {
    func didSelectConditions(_ conditions: [String])
}

class PreviousConditionsViewController: UITableViewController {
    
    @IBOutlet weak var eyeContainer: UIView!
    @IBOutlet weak var bodyContainer: UIView!
    
    weak var delegate: PreviousConditionsDelegate?
    
    var selectedConditions: Set<String> = []
    
    let eyeConditions = [
        "Digital Eye Strain",
        "Dry Eyes",
        "Blurry Vision",
        "Eye Fatigue",
        "Convergence Issues",
        "Lazy Eye",
        "Astigmatism",
        "Presbyopia",
        "Crossed Eyes",
        "Light Sensitivity",
        "Other"
    ]
    
    let bodyConditions = [
        "Diabetes",
        "High Blood Pressure",
        "Thyroid Issues",
        "Migraine",
        "Autoimmune Disease",
        "Neurological Issues"
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBubbles()
    }
    
    func setupBubbles() {
        
        let eyeView = ConditionBubblesView(
            conditions: eyeConditions
        ) { [weak self] selection in
            self?.selectedConditions.formUnion(selection)
        }
        
        let bodyView = ConditionBubblesView(
            conditions: bodyConditions
        ) { [weak self] selection in
            self?.selectedConditions.formUnion(selection)
        }
        
        let eyeHost = UIHostingController(rootView: eyeView)
        let bodyHost = UIHostingController(rootView: bodyView)
        
        addChild(eyeHost)
        addChild(bodyHost)
        
        eyeHost.view.translatesAutoresizingMaskIntoConstraints = false
        bodyHost.view.translatesAutoresizingMaskIntoConstraints = false
        
        eyeContainer.addSubview(eyeHost.view)
        bodyContainer.addSubview(bodyHost.view)
        
        NSLayoutConstraint.activate([
            eyeHost.view.topAnchor.constraint(equalTo: eyeContainer.topAnchor),
            eyeHost.view.leadingAnchor.constraint(equalTo: eyeContainer.leadingAnchor),
            eyeHost.view.trailingAnchor.constraint(equalTo: eyeContainer.trailingAnchor),
            eyeHost.view.bottomAnchor.constraint(equalTo: eyeContainer.bottomAnchor),
            
            bodyHost.view.topAnchor.constraint(equalTo: bodyContainer.topAnchor),
            bodyHost.view.leadingAnchor.constraint(equalTo: bodyContainer.leadingAnchor),
            bodyHost.view.trailingAnchor.constraint(equalTo: bodyContainer.trailingAnchor),
            bodyHost.view.bottomAnchor.constraint(equalTo: bodyContainer.bottomAnchor)
        ])
        
        eyeHost.didMove(toParent: self)
        bodyHost.didMove(toParent: self)
    }
    
    // Call this when user taps Done
    @IBAction func doneTapped(_ sender: UIButton) {
        
        print("DONE PRESSED")
        
        delegate?.didSelectConditions(Array(selectedConditions))
        
        if navigationController != nil {
            navigationController?.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }
    
    @IBAction func qioo(_ sender: Any) {
        print("DONE PRESSED")
        
        delegate?.didSelectConditions(Array(selectedConditions))
        
        if navigationController != nil {
            navigationController?.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }
    
    struct ConditionBubblesView: View {
        
        let conditions: [String]
        var onSelectionChange: (Set<String>) -> Void
        
        @State private var selected: Set<String> = []
        
        var body: some View {
            
            FlowLayout(tags: conditions) { tag in
                
                Text(tag)
                    .font(.system(size: 14))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        selected.contains(tag)
                        ? Color.orange.opacity(0.9)
                        : Color.white.opacity(0.12)
                    )
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                    .onTapGesture {
                        
                        if selected.contains(tag) {
                            selected.remove(tag)
                        } else {
                            selected.insert(tag)
                        }
                        
                        onSelectionChange(selected)
                    }
            }
            .padding(.horizontal)
        }
    }
    
    
    struct FlowLayout<Data: RandomAccessCollection, Content: View>: View where Data.Element: Hashable {
        
        var tags: Data
        var content: (Data.Element) -> Content
        
        @State private var totalHeight = CGFloat.zero
        
        init(tags: Data, @ViewBuilder content: @escaping (Data.Element) -> Content) {
            self.tags = tags
            self.content = content
        }
        
        var body: some View {
            
            GeometryReader { geo in
                generateContent(in: geo)
            }
            .frame(height: totalHeight)
        }
        
        func generateContent(in geo: GeometryProxy) -> some View {
            
            var width = CGFloat.zero
            var height = CGFloat.zero
            
            return ZStack(alignment: .topLeading) {
                
                ForEach(Array(tags), id: \.self) { tag in
                    
                    content(tag)
                        .padding(4)
                        .alignmentGuide(.leading) { dimension in
                            
                            if abs(width - dimension.width) > geo.size.width {
                                width = 0
                                height -= dimension.height
                            }
                            
                            let result = width
                            
                            if tag == tags.last {
                                width = 0
                            } else {
                                width -= dimension.width
                            }
                            
                            return result
                        }
                        .alignmentGuide(.top) { _ in
                            
                            let result = height
                            
                            if tag == tags.last {
                                height = 0
                            }
                            
                            return result
                        }
                }
            }
            .background(
                GeometryReader { geo -> Color in
                    
                    DispatchQueue.main.async {
                        totalHeight = geo.size.height
                    }
                    
                    return Color.clear
                }
            )
        }
    }
    
}
