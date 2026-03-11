import UIKit
import DGCharts

class DigitalEyeStrainCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var barChartView: BarChartView!
    @IBOutlet weak var containerView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
        setupChart()
        configure(with: [75, 25, 60, 45, 80, 70, 48])
    }
    
    private func setupUI() {
        containerView.layer.cornerRadius = 20
        containerView.backgroundColor = UIColor(white: 1.0, alpha: 0.05)
    }
    
    private func setupChart() {
        barChartView.chartDescription.enabled = false
        barChartView.legend.enabled = false
        barChartView.isUserInteractionEnabled = false
        
        let xAxis = barChartView.xAxis
        xAxis.labelPosition = .bottom
        xAxis.drawGridLinesEnabled = false
        xAxis.drawAxisLineEnabled = true
        xAxis.axisLineColor = .white.withAlphaComponent(0.2)
        xAxis.labelTextColor = .white
        xAxis.labelFont = .systemFont(ofSize: 10)
        xAxis.valueFormatter = IndexAxisValueFormatter(values: ["S", "M", "T", "W", "T", "F", "S"])
        xAxis.labelCount = 7
        xAxis.granularity = 1
        
        //Left Axis
        let leftAxis = barChartView.leftAxis
        leftAxis.enabled = true
        leftAxis.drawLabelsEnabled = false
        leftAxis.drawGridLinesEnabled = true
        leftAxis.gridColor = .white.withAlphaComponent(0.1)
        leftAxis.gridLineWidth = 1.0
        leftAxis.drawAxisLineEnabled = false
        
        leftAxis.axisMinimum = 0
        leftAxis.axisMaximum = 100
        leftAxis.setLabelCount(6, force: true)
        leftAxis.spaceTop = 0

   
        let rightAxis = barChartView.rightAxis
        rightAxis.enabled = true
        rightAxis.drawLabelsEnabled = true
        rightAxis.drawGridLinesEnabled = false
        rightAxis.drawAxisLineEnabled = false
        rightAxis.labelTextColor = .white.withAlphaComponent(0.6)
        rightAxis.labelFont = .systemFont(ofSize: 10)
        
        rightAxis.axisMinimum = 0
        rightAxis.axisMaximum = 100
        rightAxis.setLabelCount(6, force: true)
        rightAxis.spaceTop = 0
        
 
        barChartView.drawGridBackgroundEnabled = false
        barChartView.drawValueAboveBarEnabled = false
        barChartView.autoScaleMinMaxEnabled = false
        barChartView.fitBars = true
        
        let renderer = RoundedBarRenderer(dataProvider: barChartView, animator: barChartView.chartAnimator, viewPortHandler: barChartView.viewPortHandler)
        renderer.cornerRadius = 6.0
        barChartView.renderer = renderer
    }
    
    func configure(with values: [Double]) {
        
        let entries = values.enumerated().map { BarChartDataEntry(x: Double($0), y: $1) }
        let set = BarChartDataSet(entries: entries)
        
        set.colors = values.map { $0 > 50 ? .systemGray4 : .systemOrange }
        set.drawValuesEnabled = false
        
        let data = BarChartData(dataSet: set)
        data.barWidth = 0.4
        
        barChartView.data = data
        barChartView.notifyDataSetChanged()
        barChartView.animate(yAxisDuration: 0.5) 
    }
}
