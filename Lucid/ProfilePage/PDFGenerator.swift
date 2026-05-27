import UIKit

class PDFGenerator {
    static func generateReportPDF(completion: @escaping (URL?) -> Void) {
        let user = SwiftDataManager.shared.getOrCreateUser()
        let htmlContent = self.generateHTML(for: user)
        
        DispatchQueue.main.async {
            let printFormatter = UIMarkupTextPrintFormatter(markupText: htmlContent)
            
            let renderer = UIPrintPageRenderer()
            renderer.addPrintFormatter(printFormatter, startingAtPageAt: 0)
            
            // Standard A4 paper size: 595.2 x 841.8 points
            let paperRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8)
            let printableRect = paperRect.insetBy(dx: 36, dy: 36)
            
            renderer.setValue(NSValue(cgRect: paperRect), forKey: "paperRect")
            renderer.setValue(NSValue(cgRect: printableRect), forKey: "printableRect")
            
            let pdfData = NSMutableData()
            UIGraphicsBeginPDFContextToData(pdfData, CGRect.zero, nil)
            
            for i in 0..<renderer.numberOfPages {
                UIGraphicsBeginPDFPage()
                renderer.drawPage(at: i, in: paperRect)
            }
            
            UIGraphicsEndPDFContext()
            
            let tempDirectory = FileManager.default.temporaryDirectory
            let pdfURL = tempDirectory.appendingPathComponent("Eye_Health_Report.pdf")
            
            do {
                try pdfData.write(to: pdfURL, options: .atomic)
                completion(pdfURL)
            } catch {
                print("Error saving PDF: \(error)")
                completion(nil)
            }
        }
    }
    
    private static func generateHTML(for user: User) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        let ageDobValue: String
        if let dob = user.dateOfBirth {
            let dobStr = formatter.string(from: dob)
            ageDobValue = "\(user.age) years (\(dobStr))"
        } else {
            ageDobValue = "\(user.age) years"
        }
        let genderStr = user.gender ?? "Not set"
        let conditionsStr = user.previousConditions.isEmpty ? "None" : user.previousConditions.joined(separator: ", ")
        
        let sortedOSDI = user.osdiSessions.sorted(by: { $0.date > $1.date }).prefix(5)
        var osdiRows = ""
        if sortedOSDI.isEmpty {
            osdiRows = "<tr><td colspan='3' class='no-data'>No data found</td></tr>"
        } else {
            for session in sortedOSDI {
                let dateStr = formatter.string(from: session.date)
                osdiRows += "<tr><td>\(dateStr)</td><td>\(String(format: "%.1f", session.score))</td><td>\(session.severity)</td></tr>"
            }
        }
        
        let oneMonthAgo = Date().addingTimeInterval(-30 * 24 * 60 * 60)
        let recentTests = user.eyeTestSessions.filter { $0.startingTime >= oneMonthAgo }.sorted(by: { $0.startingTime > $1.startingTime })
        var testRows = ""
        if recentTests.isEmpty {
            testRows = "<tr><td colspan='3' class='no-data'>No data found for the last 30 days</td></tr>"
        } else {
            for session in recentTests {
                let dateStr = formatter.string(from: session.startingTime)
                testRows += "<tr><td>\(dateStr)</td><td>\(session.eyeTested)</td><td>\(String(format: "%.1f", session.score))</td></tr>"
            }
        }
        
        let recentStreaks = user.streak.filter { $0.date >= oneMonthAgo }.sorted(by: { $0.date > $1.date })
        var streakRows = ""
        if recentStreaks.isEmpty {
            streakRows = "<tr><td colspan='2' class='no-data'>No streak data found for the last 30 days</td></tr>"
        } else {
            for day in recentStreaks {
                let dateStr = formatter.string(from: day.date)
                let status = day.isCompleted ? "<span class='badge completed'>Completed</span>" : "<span class='badge incomplete'>Not Completed</span>"
                streakRows += "<tr><td>\(dateStr)</td><td>\(status)</td></tr>"
            }
        }
        
        let reportDateStr = formatter.string(from: Date())
        
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
                    color: #2D3748;
                    margin: 0;
                    padding: 20px;
                    line-height: 1.5;
                }
                .header {
                    border-bottom: 2px solid #3182CE;
                    padding-bottom: 12px;
                    margin-bottom: 24px;
                }
                .header h1 {
                    margin: 0;
                    font-size: 24px;
                    color: #2B6CB0;
                }
                .header p {
                    margin: 4px 0 0 0;
                    font-size: 14px;
                    color: #718096;
                }
                .section {
                    margin-bottom: 24px;
                }
                .section-title {
                    font-size: 16px;
                    font-weight: bold;
                    color: #2B6CB0;
                    margin-bottom: 12px;
                    border-bottom: 1px solid #E2E8F0;
                    padding-bottom: 4px;
                }
                .grid {
                    display: grid;
                    grid-template-columns: 1fr 1fr;
                    gap: 12px;
                }
                .card {
                    background-color: #F7FAFC;
                    border: 1px solid #E2E8F0;
                    border-radius: 8px;
                    padding: 12px;
                    margin-bottom: 8px;
                }
                .card-title {
                    font-size: 11px;
                    color: #718096;
                    text-transform: uppercase;
                    margin-bottom: 4px;
                    font-weight: bold;
                }
                .card-value {
                    font-size: 14px;
                    font-weight: bold;
                    color: #2D3748;
                }
                table {
                    width: 100%;
                    border-collapse: collapse;
                    margin-top: 8px;
                }
                th, td {
                    text-align: left;
                    padding: 8px 12px;
                    border-bottom: 1px solid #E2E8F0;
                    font-size: 13px;
                }
                th {
                    background-color: #EDF2F7;
                    color: #4A5568;
                    font-weight: 600;
                }
                .no-data {
                    text-align: center;
                    color: #A0AEC0;
                    padding: 16px;
                    font-style: italic;
                }
                .badge {
                    display: inline-block;
                    padding: 2px 8px;
                    font-size: 11px;
                    font-weight: bold;
                    border-radius: 4px;
                }
                .completed {
                    background-color: #C6F6D5;
                    color: #22543D;
                }
                .incomplete {
                    background-color: #FED7D7;
                    color: #742A2A;
                }
            </style>
        </head>
        <body>
            <div class="header">
                <h1>Eye Health & Care Report</h1>
                <p>Generated on \(reportDateStr) for \(user.name)</p>
            </div>
            
            <div class="section">
                <div class="section-title">General Medical Profile</div>
                <div style="display: table; width: 100%; table-layout: fixed; border-spacing: 10px;">
                    <div style="display: table-row;">
                        <div style="display: table-cell; width: 50%;">
                            <div class="card">
                                <div class="card-title">Full Name</div>
                                <div class="card-value">\(user.name)</div>
                            </div>
                        </div>
                        <div style="display: table-cell; width: 50%;">
                            <div class="card">
                                <div class="card-title">Age / Date of Birth</div>
                                <div class="card-value">\(ageDobValue)</div>
                            </div>
                        </div>
                    </div>
                    <div style="display: table-row;">
                        <div style="display: table-cell; width: 50%;">
                            <div class="card">
                                <div class="card-title">Gender</div>
                                <div class="card-value">\(genderStr)</div>
                            </div>
                        </div>
                        <div style="display: table-cell; width: 50%;">
                            <div class="card">
                                <div class="card-title">Refractive Error (Power)</div>
                                <div class="card-value">Left: \(String(format: "%.2f D", user.leftEyePower)) | Right: \(String(format: "%.2f D", user.rightEyePower))</div>
                            </div>
                        </div>
                    </div>
                </div>
                <div style="padding: 0 10px;">
                    <div class="card">
                        <div class="card-title">Previous Conditions</div>
                        <div class="card-value">\(conditionsStr)</div>
                    </div>
                </div>
            </div>
            
            <div class="section">
                <div class="section-title">Dry Eye Evaluation (OSDI Score - Last 5 Sessions)</div>
                <table>
                    <thead>
                        <tr>
                            <th>Date</th>
                            <th>Score</th>
                            <th>Severity</th>
                        </tr>
                    </thead>
                    <tbody>
                        \(osdiRows)
                    </tbody>
                </table>
            </div>
            
            <div class="section">
                <div class="section-title">Vision Test History (Last 30 Days)</div>
                <table>
                    <thead>
                        <tr>
                            <th>Date</th>
                            <th>Eye Tested</th>
                            <th>Score</th>
                        </tr>
                    </thead>
                    <tbody>
                        \(testRows)
                    </tbody>
                </table>
            </div>
            
            <div class="section">
                <div class="section-title">Daily Exercise Goals & Streaks (Last 30 Days)</div>
                <table>
                    <thead>
                        <tr>
                            <th>Date</th>
                            <th>Status</th>
                        </tr>
                    </thead>
                    <tbody>
                        \(streakRows)
                    </tbody>
                </table>
            </div>
        </body>
        </html>
        """
        return html
    }
}
