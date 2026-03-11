//
//  TrandsCollectionViewCell.swift
//  Lucid
//
//  Created by Kanishka Bansal on 10/02/26.
//

import UIKit
import DGCharts

class TrandsCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var barChartView: BarChartView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var averageScoreLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
        setupChart()
        hardCodeTrendData()
    }
    
    private func setupUI() {
        containerView.layer.cornerRadius = 20
        containerView.backgroundColor = UIColor(white: 1.0, alpha: 0.05)
    }
    
    private func setupChart() {
        barChartView.isUserInteractionEnabled = false
        barChartView.chartDescription.enabled = false
        barChartView.legend.enabled = false
        barChartView.rightAxis.enabled = false
        barChartView.leftAxis.enabled = false
        
        let xAxis = barChartView.xAxis
        xAxis.labelPosition = .bottom
        xAxis.drawGridLinesEnabled = false
        xAxis.labelTextColor = .white
        xAxis.valueFormatter = IndexAxisValueFormatter(values: ["Jun", "Jul", "Aug", "Sep", "Oct", "Nov"])
        xAxis.centerAxisLabelsEnabled = true
        xAxis.granularity = 1
        
        let limitLine = ChartLimitLine(limit: 65, label: "")
        limitLine.lineColor = .systemOrange
        limitLine.lineWidth = 1.5
        barChartView.leftAxis.addLimitLine(limitLine)
        barChartView.leftAxis.axisMinimum = 0
        barChartView.leftAxis.axisMaximum = 100

        let renderer = RoundedBarRenderer(dataProvider: barChartView, animator: barChartView.chartAnimator, viewPortHandler: barChartView.viewPortHandler)
        renderer.cornerRadius = 8.0
        barChartView.renderer = renderer
    }
    
    private func hardCodeTrendData() {
        let checkupValues: [Double] = [50, 60, 55, 70, 75, 85]
        let accuracyValues: [Double] = [40, 55, 50, 65, 70, 80]
        
        let checkupEntries = checkupValues.enumerated().map { BarChartDataEntry(x: Double($0), y: $1) }
        let accuracyEntries = accuracyValues.enumerated().map { BarChartDataEntry(x: Double($0), y: $1) }
        
        let set1 = BarChartDataSet(entries: checkupEntries, label: "Checkup")
        set1.colors = [.systemGray4]
        
        let set2 = BarChartDataSet(entries: accuracyEntries, label: "Accuracy")
        set2.colors = [.systemGray2]
        
        let data = BarChartData(dataSets: [set1, set2])
        data.barWidth = 0.3
        data.setDrawValues(false)
        
        barChartView.data = data
        
        let groupSpace = 0.3
        let barSpace = 0.05
        barChartView.groupBars(fromX: 0, groupSpace: groupSpace, barSpace: barSpace)
        barChartView.xAxis.axisMinimum = 0
        barChartView.xAxis.axisMaximum = Double(checkupValues.count)
    }
    
    func configure(title: String, score: String, values: [Double]) {
        titleLabel.text = title
        averageScoreLabel.text = score
        
        let entries = values.enumerated().map { BarChartDataEntry(x: Double($0), y: $1) }
        let set = BarChartDataSet(entries: entries)
        set.colors = [.systemGray4]
        set.drawValuesEnabled = false
        
        let data = BarChartData(dataSet: set)
        
        data.barWidth = 0.2
        barChartView.data = data
        
        let xAxis = barChartView.xAxis
        xAxis.valueFormatter = IndexAxisValueFormatter(values: ["Jun", "Jul", "Aug", "Sep", "Oct", "Nov"])
        xAxis.labelCount = 6
        
        xAxis.axisMinimum = -0.5
        xAxis.axisMaximum = 5.5
        
        barChartView.leftAxis.axisMaximum = 100
        barChartView.leftAxis.axisMinimum = 0
        
        barChartView.leftAxis.removeAllLimitLines()
        let limitLine = ChartLimitLine(limit: 65, label: "")
        limitLine.lineColor = .systemOrange
        limitLine.lineWidth = 1.5
        barChartView.leftAxis.addLimitLine(limitLine)
        
        barChartView.notifyDataSetChanged()
    }
}
