//
//  EyeTestTableViewController.swift
//  Lucid
//
//  Created by Kanishka Bansal on 27/01/26.
//

import UIKit

class EyeTestTableViewController: UITableViewController {

    var onTestComplete: (() -> Void)?  // ← added

    override func viewDidLoad() {
        super.viewDidLoad()

        let bgImageView = UIImageView(image: UIImage(named: "BackgroundGradient"))
        bgImageView.contentMode = .scaleAspectFill
        self.tableView.backgroundView = bgImageView
        self.tableView.backgroundColor = .clear

        view.subviews.forEach { subview in
            if let title = subview.viewWithTag(10) as? UILabel {
                title.font = UIFont.preferredFont(forTextStyle: .headline)
                title.setContentHuggingPriority(.defaultHigh, for: .vertical)
            }
            if let desc = subview.viewWithTag(20) as? UILabel {
                desc.numberOfLines = 0
                desc.setContentHuggingPriority(.defaultLow, for: .vertical)
            }
        }
    }

    // ← added: fires onTestComplete when user taps a row
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        onTestComplete?()
    }
}
