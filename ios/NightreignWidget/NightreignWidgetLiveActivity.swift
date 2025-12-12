//
//  NightreignWidgetLiveActivity.swift
//  NightreignWidget
//
//  Created by Tim OLeary on 6/24/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct NightreignWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: NightreignWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack(alignment: .center, spacing: 8) {
                Text("Phase:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(context.state.phaseLabel)
                    .font(.title3)
                    .bold()
                Text("⏱ \(formatTime(context.state.timeRemaining)) remaining")
                    .font(.headline)
                    .monospacedDigit()
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.state.phaseLabel)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(formatTime(context.state.timeRemaining))
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("\(context.state.phaseLabel): \(formatTime(context.state.timeRemaining)) left")
                }
            } compactLeading: {
                Text("⏱")
            } compactTrailing: {
                Text("\(context.state.timeRemaining)")
            } minimal: {
                Text("\(context.state.timeRemaining)")
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

private func formatTime(_ seconds: Int) -> String {
    let minutes = seconds / 60
    let secs = seconds % 60
    return String(format: "%d:%02d", minutes, secs)
}

extension NightreignWidgetAttributes {
    fileprivate static var preview: NightreignWidgetAttributes {
        NightreignWidgetAttributes(name: "World")
    }
}

extension NightreignWidgetAttributes.ContentState {
    fileprivate static var smiley: NightreignWidgetAttributes.ContentState {
        NightreignWidgetAttributes.ContentState(timeRemaining: 30, phaseLabel: "Smiley Phase")
     }
     
     fileprivate static var starEyes: NightreignWidgetAttributes.ContentState {
         NightreignWidgetAttributes.ContentState(timeRemaining: 10, phaseLabel: "Star Eyes Phase")
     }
}

#Preview("Notification", as: .content, using: NightreignWidgetAttributes.preview) {
   NightreignWidgetLiveActivity()
} contentStates: {
    NightreignWidgetAttributes.ContentState.smiley
    NightreignWidgetAttributes.ContentState.starEyes
}
