//
//  LucidwidgetExtensionBundle.swift
//  LucidwidgetExtension
//
//  Created by Lucid on 5/24/26.
//

import WidgetKit
import SwiftUI

@main
struct LucidwidgetExtensionBundle: WidgetBundle {
    var body: some Widget {
        LucidwidgetExtension()
        LucidwidgetExtensionControl()
        if #available(iOS 16.1, *) {
            Twenty2020ActivityWidget()
        }
    }
}
