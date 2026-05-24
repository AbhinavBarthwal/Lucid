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
    private var eyeSelected: Set<String> = []
    private var bodySelected: Set<String> = []
    
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
        eyeSelected = selectedConditions.intersection(Set(eyeConditions))
        bodySelected = selectedConditions.intersection(Set(bodyConditions))
        selectedConditions = eyeSelected.union(bodySelected)
        setupBubbles()
    }
    
    func setupBubbles() {
        
        let eyeView = ConditionBubblesView(
            conditions: eyeConditions,
            initialSelected: eyeSelected
        ) { [weak self] selection in
            guard let self else { return }
            self.eyeSelected = selection
            self.selectedConditions = self.eyeSelected.union(self.bodySelected)
        }
        
        let bodyView = ConditionBubblesView(
            conditions: bodyConditions,
            initialSelected: bodySelected
        ) { [weak self] selection in
            guard let self else { return }
            self.bodySelected = selection
            self.selectedConditions = self.eyeSelected.union(self.bodySelected)
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
    
    struct ConditionBubblesView: View {
        
        let conditions: [String]
        let initialSelected: Set<String>
        var onSelectionChange: (Set<String>) -> Void
        
        @State private var selected: Set<String> = []
        
        init(
            conditions: [String],
            initialSelected: Set<String> = [],
            onSelectionChange: @escaping (Set<String>) -> Void
        ) {
            self.conditions = conditions
            self.initialSelected = initialSelected
            self.onSelectionChange = onSelectionChange
            _selected = State(initialValue: initialSelected.intersection(Set(conditions)))
        }
        
        var body: some View {
            
            FlowLayout(tags: conditions) { tag in
                
                Text(tag)
                    .font(.system(size: 14))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        selected.contains(tag)
                        ? .accent
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
