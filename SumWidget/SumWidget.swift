//
//  SumWidget.swift
//  SumWidget
//
//  Created by Thalys Guimarães on 08/01/24.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), totalCost: 0)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), totalCost: readTotalCost())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entry = SimpleEntry(date: Date(), totalCost: readTotalCost())
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }

    private func readTotalCost() -> Double {
        // Read the total cost from shared UserDefaults
        return UserDefaults(suiteName: "group.com.nooma.Subscriptions")?.double(forKey: "totalCost") ?? 0
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let totalCost: Double
}

struct SumWidgetEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        VStack {
            Text("Total Cost:")
            Text("\(entry.totalCost, specifier: "%.2f") USD") // Format the cost
        }
        .padding()
        .background(Color.purple)
    }
}

struct SumWidget: Widget {
    let kind: String = "SumWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            SumWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Subscription Sum")
        .description("Displays the sum of your subscriptions.")
    }
}

struct SumWidget_Previews: PreviewProvider {
    static var previews: some View {
        SumWidgetEntryView(entry: SimpleEntry(date: Date(), totalCost: 123.45))
            .previewContext(WidgetPreviewContext(family: .systemSmall))

        SumWidgetEntryView(entry: SimpleEntry(date: Date(), totalCost: 123.45))
            .previewContext(WidgetPreviewContext(family: .systemMedium))

        SumWidgetEntryView(entry: SimpleEntry(date: Date(), totalCost: 123.45))
            .previewContext(WidgetPreviewContext(family: .systemLarge))
    }
}
