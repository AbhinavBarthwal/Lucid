import UIKit

class TermsViewController: UIViewController {

    private let containerView = UIView()
    private let headerLabel = UILabel()
    private let textView = UITextView()
    private let closeButton = UIButton()
    private let gradientLayer = CAGradientLayer()
    private let accentColor = UIColor(named: "AccentColor") ?? UIColor(red: 1.0, green: 0.50, blue: 0.16, alpha: 1.0)
    var onClose: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupBackground()
        setupLayout()
        populateTermsText()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = view.bounds
    }

    private func setupBackground() {
        // Premium dark gradient matching the Lucid theme
        gradientLayer.colors = [
            UIColor(red: 0.08, green: 0.09, blue: 0.13, alpha: 1.0).cgColor,
            UIColor(red: 0.04, green: 0.05, blue: 0.07, alpha: 1.0).cgColor
        ]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
        view.layer.insertSublayer(gradientLayer, at: 0)
    }

    private func setupLayout() {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = .clear
        view.addSubview(containerView)

        // Header Title Label
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        headerLabel.text = "Terms & Conditions"
        headerLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        headerLabel.textColor = .white
        headerLabel.textAlignment = .center
        containerView.addSubview(headerLabel)

        // Scrollable Terms TextView
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.backgroundColor = .clear
        textView.textColor = UIColor(white: 1.0, alpha: 0.85)
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.isEditable = false
        textView.isSelectable = true
        textView.showsVerticalScrollIndicator = true
        textView.indicatorStyle = .white
        textView.contentInset = UIEdgeInsets(top: 10, left: 16, bottom: 20, right: 16)
        containerView.addSubview(textView)

        // Close Button (capsule style)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setTitle("Got it, thanks!", for: .normal)
        closeButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        closeButton.setTitleColor(.black, for: .normal)
        closeButton.backgroundColor = accentColor
        closeButton.layer.cornerRadius = 20
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        
        // Add subtle shadow to button
        closeButton.layer.shadowColor = accentColor.withAlphaComponent(0.4).cgColor
        closeButton.layer.shadowOpacity = 0.8
        closeButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        closeButton.layer.shadowRadius = 8
        
        containerView.addSubview(closeButton)

        // Auto Layout Constraints
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            headerLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 24),
            headerLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            headerLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),

            textView.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 16),
            textView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: closeButton.topAnchor, constant: -20),

            closeButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),
            closeButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24),
            closeButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -24),
            closeButton.heightAnchor.constraint(equalToConstant: 48)
        ])
    }

    private func populateTermsText() {
        let boldAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 18, weight: .bold),
            .foregroundColor: UIColor.white
        ]
        
        let bodyAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 15, weight: .regular),
            .foregroundColor: UIColor(white: 1.0, alpha: 0.8)
        ]

        let bulletAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 15, weight: .medium),
            .foregroundColor: accentColor
        ]

        let attributedText = NSMutableAttributedString()

        func appendSection(_ title: String, body: String) {
            attributedText.append(NSAttributedString(string: "\n\(title)\n", attributes: boldAttributes))
            attributedText.append(NSAttributedString(string: "\(body)\n", attributes: bodyAttributes))
        }

        func appendBullet(_ boldPrefix: String, desc: String) {
            attributedText.append(NSAttributedString(string: "\n• ", attributes: bulletAttributes))
            attributedText.append(NSAttributedString(string: "\(boldPrefix): ", attributes: [
                .font: UIFont.systemFont(ofSize: 15, weight: .bold),
                .foregroundColor: UIColor.white
            ]))
            attributedText.append(NSAttributedString(string: "\(desc)\n", attributes: bodyAttributes))
        }

        // Title Intro
        attributedText.append(NSAttributedString(string: "Welcome to Lucid! By using our app, you agree to these Terms and Conditions. Please read them carefully.\n", attributes: bodyAttributes))

        appendSection("1. Purpose & Scope", body: "Lucid is designed to help users soothe and protect their eyes from digital strain through relaxation exercises and wellness check-ups.")

        appendSection("2. Disclaimer - Not Medical Advice", body: "All content, exercises, surveys, and reports provided by Lucid are for educational and wellness purposes only. Lucid is not a medical device and is not a substitute for professional medical advice, diagnosis, or treatment. Always consult with a qualified ophthalmologist or optometrist if you experience persistent eye discomfort or vision changes.")

        appendSection("3. User Guidelines & Commitments", body: "To ensure your eye wellness journey is safe and effective, you agree to:")
        appendBullet("Perform exercises safely", desc: "Stop any exercise immediately if you experience pain, dizziness, or strain.")
        appendBullet("Accuracy", desc: "Provide accurate answers to check-ups (like Landolt C or OSDI) to receive valid progress reports.")
        appendBullet("Personal Use", desc: "Use the application for your own personal, non-commercial purposes only.")

        appendSection("4. Privacy & Data Security", body: "Your privacy matters to us. Your exercise logs, goals, and survey results are stored locally on your device or via secure encrypted services. We do not sell or share your personal health metrics with third parties.")

        appendSection("5. Intellectual Property", body: "All original layouts, custom icons, graphics, text, and scientific exercise designs inside Lucid are the property of the Lucid Development Team and are protected under copyright laws.")

        appendSection("6. Limitation of Liability", body: "To the maximum extent permitted by law, the Lucid Development Team shall not be liable for any direct, indirect, incidental, or consequential damages resulting from your use or inability to use the application.")

        appendSection("7. Changes to Terms", body: "We may update these terms from time to time to reflect new features or regulations. Continued use of the app constitutes acceptance of any updated terms.")

        appendSection("8. Support & Feedback", body: "If you have any questions, feel free to reach out to us via the Help section in the Profile settings.")

        textView.attributedText = attributedText
    }

    @objc private func closeButtonTapped() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        if let onClose {
            onClose()
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
}
