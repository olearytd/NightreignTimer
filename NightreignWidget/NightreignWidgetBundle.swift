//
//  NightreignWidgetBundle.swift
//  NightreignWidget
//
//  Created by Tim OLeary on 6/24/25.
//

import WidgetKit
import SwiftUI

@main
struct NightreignWidgetBundle: WidgetBundle {
    var body: some Widget {
        NightreignWidget()
        NightreignWidgetControl()
        NightreignWidgetLiveActivity()
    }
}
