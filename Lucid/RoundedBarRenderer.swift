import UIKit
import DGCharts

class RoundedBarRenderer: BarChartRenderer {
    var cornerRadius: CGFloat = 6.0

    nonisolated override init(dataProvider: BarChartDataProvider?, animator: Animator?, viewPortHandler: ViewPortHandler?) {
        super.init(dataProvider: dataProvider!, animator: animator!, viewPortHandler: viewPortHandler!)
    }

    nonisolated override func drawDataSet(context: CGContext, dataSet: BarChartDataSetProtocol, index: Int) {
        MainActor.assumeIsolated {
            guard let dataProvider = dataProvider,
                  let barData = dataProvider.barData else { return }
            
            let trans = dataProvider.getTransformer(forAxis: dataSet.axisDependency)
            let phaseY = animator.phaseY
            let barWidthHalf = barData.barWidth / 2.0
            
            for i in 0..<dataSet.entryCount {
                guard let e = dataSet.entryForIndex(i) as? BarChartDataEntry else { continue }
                
                let x = e.x
                let y = e.y
                
                let left = x - barWidthHalf
                let right = x + barWidthHalf
                let top = y >= 0 ? y * phaseY : 0
                let bottom = y <= 0 ? y * phaseY : 0
                
                var rect = CGRect(x: left, y: top, width: right - left, height: bottom - top)
                trans.rectValueToPixel(&rect)
                
                if !viewPortHandler.isInBoundsRight(rect.origin.x) { break }
                if !viewPortHandler.isInBoundsLeft(rect.origin.x + rect.size.width) { continue }

                context.setFillColor(dataSet.color(atIndex: i).cgColor)
                
                let path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
                context.addPath(path.cgPath)
                context.fillPath()
            }
        }
    }
}
