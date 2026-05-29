//
//  ProfilePageTableViewController.swift
//  Lucid
//
//  Created by GEU on 28/01/26.
//

import UIKit

class ProfilePageTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let user = SwiftDataManager.shared.getOrCreateUser()

    }

    // MARK: - Table view data source

//    override func numberOfSections(in tableView: UITableView) -> Int {
//        // #warning Incomplete implementation, return the number of sections
//        return 0
//    }
//
//    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        // #warning Incomplete implementation, return the number of rows
//        return 0
//    }

    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    @IBAction func backButtonTapped(_ sender: Any) {
        // Double-dismiss to ensure we clear the report AND the exercise, returning to Care Page
        if let rootPresenter = self.presentingViewController?.presentingViewController {
            rootPresenter.dismiss(animated: true, completion: nil)
        } else if let exercisePresenter = self.presentingViewController {
            exercisePresenter.dismiss(animated: true, completion: nil)
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 0 && indexPath.row == 3 {
            shareReport()
        } else if indexPath.section == 1 {
            if indexPath.row == 0 {
                showAboutUsPopup()
            } else if indexPath.row == 1 {
                showHelpPopup()
            }
        }
    }
    
    private func showAboutUsPopup() {
        let title = "About Lucid"
        let message = """
        Welcome to Lucid, your cozy companion for happy, healthy eyes in our digital world!

        • What we do together:
        We help you soothe and protect your eyes from digital strain using fun, scientifically-designed exercises and check-ups.

        • How we support you:
        Through simple, relaxing exercises like Near Far Focus, Saccadic Jumps, and Blink Training, we'll work on building focus, keeping your eyes refreshed, and improving how your eyes work together. With easy check-ups like the OSDI survey and Landolt C tests, you can watch your eye wellness bloom!
        """
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Awesome!", style: .default, handler: nil))
        present(alert, animated: true)
    }
    
    private func showHelpPopup() {
        let title = "Support & Help"
        let message = """
        Got questions, ideas, or just want to say hi? We'd love to hear from you!

        Feel free to reach out to us anytime:
        • abhinavbarthwal212@gmail.com
        • mekanishkaBansal@gmail.com
        """
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Copy Abhinav's Email", style: .default) { _ in
            UIPasteboard.general.string = "abhinavbarthwal212@gmail.com"
            let copyAlert = UIAlertController(title: "Copied!", message: "We've copied that email address for you! Ready to paste.", preferredStyle: .alert)
            copyAlert.addAction(UIAlertAction(title: "Got it!", style: .default))
            self.present(copyAlert, animated: true)
        })
        
        alert.addAction(UIAlertAction(title: "Copy Kanishka's Email", style: .default) { _ in
            UIPasteboard.general.string = "mekanishkaBansal@gmail.com"
            let copyAlert = UIAlertController(title: "Copied!", message: "We've copied that email address for you! Ready to paste.", preferredStyle: .alert)
            copyAlert.addAction(UIAlertAction(title: "Got it!", style: .default))
            self.present(copyAlert, animated: true)
        })
        
        alert.addAction(UIAlertAction(title: "Close", style: .cancel, handler: nil))
        
        present(alert, animated: true)
    }
    
    private func shareReport() {
        let alert = UIAlertController(title: nil, message: "Creating your personalized report... almost ready!", preferredStyle: .alert)
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = .medium
        loadingIndicator.startAnimating()
        alert.view.addSubview(loadingIndicator)
        present(alert, animated: true)
        
        PDFGenerator.generateReportPDF { [weak self] fileURL in
            DispatchQueue.main.async {
                alert.dismiss(animated: true) {
                    guard let self = self else { return }
                    guard let fileURL = fileURL else {
                        let errorAlert = UIAlertController(
                            title: "Oops!",
                            message: "We couldn't generate your report PDF just now. Let's try again in a moment!",
                            preferredStyle: .alert
                        )
                        errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(errorAlert, animated: true)
                        return
                    }
                    
                    let activityVC = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
                    if let popover = activityVC.popoverPresentationController {
                        if let cell = self.tableView.cellForRow(at: IndexPath(row: 3, section: 0)) {
                            popover.sourceView = cell
                            popover.sourceRect = cell.bounds
                        } else {
                            popover.sourceView = self.view
                            popover.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
                        }
                    }
                    self.present(activityVC, animated: true)
                }
            }
        }
    }

}
