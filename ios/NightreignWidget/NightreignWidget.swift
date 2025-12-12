//
//  NightreignWidget.swift
//  NightreignWidget
//
//  Created by Tim OLeary on 6/24/25.
//

import WidgetKit
import SwiftUI

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationAppIntent(), phase: "Loading", timeRemaining: 0)
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: configuration, phase: "Snapshot", timeRemaining: 60)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let sharedDefaults = UserDefaults(suiteName: "group.com.toleary.NightreignTimer")
        let phaseName = sharedDefaults?.string(forKey: "currentPhaseName") ?? "Unknown"
        let timeLeft = sharedDefaults?.integer(forKey: "timeRemaining") ?? 0

        let entry = SimpleEntry(date: Date(), configuration: configuration, phase: phaseName, timeRemaining: timeLeft)

        WidgetCenter.shared.reloadAllTimelines()

        return Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(15)))
    }

//    func relevances() async -> WidgetRelevances<ConfigurationAppIntent> {
//        // Generate a list containing the contexts this widget is relevant in.
//    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let phase: String
    let timeRemaining: Int
}

struct NightreignWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack {
            Text("Phase:")
            Text(entry.phase)
                .font(.headline)

            Text("Remaining:")
            Text("\(entry.timeRemaining) sec")
                .font(.title2)
        }
        .padding()
    }
}

struct NightreignWidget: Widget {
    let kind: String = "NightreignWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            NightreignWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
    }
}

extension ConfigurationAppIntent {
    fileprivate static var smiley: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.favoriteEmoji = "😀"
        return intent
    }
    
    fileprivate static var starEyes: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.favoriteEmoji = "🤩"
        return intent
    }
}

#Preview(as: .systemSmall) {
    NightreignWidget()
} timeline: {
    SimpleEntry(date: .now, configuration: .smiley, phase: "Loading", timeRemaining: 0)
    SimpleEntry(date: .now, configuration: .starEyes, phase: "Active", timeRemaining: 120)
}
