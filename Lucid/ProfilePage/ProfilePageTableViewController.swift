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
        }
    }
    
    private func shareReport() {
        let alert = UIAlertController(title: nil, message: "Generating Report...", preferredStyle: .alert)
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
                        let errorAlert = UIAlertController(title: "Error", message: "Failed to generate report PDF.", preferredStyle: .alert)
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
