import ActivityKit

struct NightreignWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var timeRemaining: Int
        public var phaseLabel: String
    }

    public var name: String
}
