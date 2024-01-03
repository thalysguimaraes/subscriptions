//
//  SumWidgetBundle.swift
//  SumWidget
//
//  Created by Thalys Guimarães on 08/01/24.
//

import WidgetKit
import SwiftUI


struct SumWidgetBundle: WidgetBundle {
    @WidgetBundleBuilder
    var body: some Widget {
        SumWidget()
    }
}
