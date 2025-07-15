import SwiftUI
import ActivityKit
import UIKit

struct GameTimerPhase {
    let name: String
    let duration: TimeInterval
}

let dayPhases = [
    GameTimerPhase(name: "Explore", duration: 270),   // 4:30
    GameTimerPhase(name: "First Circle Closing", duration: 180),   // 3:00
    GameTimerPhase(name: "Explore", duration: 210),   // 3:30
    GameTimerPhase(name: "Last Circle Closing", duration: 180)   // 3:00
//    GameTimerPhase(name: "Explore", duration: 2),   // test
//    GameTimerPhase(name: "Circle Closing", duration: 2),   // test
//    GameTimerPhase(name: "Explore", duration: 2),   // test
//    GameTimerPhase(name: "Circle Closing", duration: 32)   // test
]

struct ContentView: View {
    @AppStorage("batterySaverEnabled") private var batterySaverEnabled: Bool = false
    @State private var timer: Timer? = nil
    @State private var timeRemaining: TimeInterval = dayPhases.first?.duration ?? 0
    @State private var isRunning = false
    @State private var currentPhaseIndex = 0
    @State private var day = 1
    @State private var wasPaused = false
    @State private var hasAnswered = false
    @State private var backgroundDate: Date? = nil
    @State private var showPhaseWarning = false
    @State private var tooltipText: String = "Start the timer when you see \"Day One\" on screen."
    @Environment(\.scenePhase) var scenePhase

    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: GameStats.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \GameStats.id, ascending: false)]
    ) private var stats: FetchedResults<GameStats>

    private var gameStats: GameStats {
        if let existing = stats.first {
            return existing
        } else {
            // 1. Read old values from UserDefaults
            let defaults = UserDefaults.standard
            let oldWins = defaults.integer(forKey: "winCount")
            let oldAttempts = defaults.integer(forKey: "totalAttempts")

            // 2. Create and seed new Core Data record
            let newStats = GameStats(context: viewContext)
            newStats.id = UUID()
            newStats.winCount = Int64(oldWins)
            newStats.totalAttempts = Int64(oldAttempts)

            // 3. Persist and clean up UserDefaults
            defaults.removeObject(forKey: "winCount")
            defaults.removeObject(forKey: "totalAttempts")
            DispatchQueue.main.async {
                do {
                    try viewContext.save()
                } catch {
                    print("Migration save failed:", error)
                }
            }

            return newStats
        }
    }

    @State private var liveActivity: Activity<NightreignWidgetAttributes>?

    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 35/255, green: 20/255, blue: 50/255), // deep purple
                    Color(red: 10/255, green: 10/255, blue: 30/255)  // dark blue
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            VStack {
                VStack(spacing: 4) {
                    Text("ER Nightreign")
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color("EldenBlue"))
                        .shadow(color: .black.opacity(0.9), radius: 4, x: 0, y: 4)
                        .overlay(
                            Text("ER Nightreign")
                                .font(.largeTitle)
                                .fontWeight(.semibold)
                                .foregroundColor(.white.opacity(0.2))
                                .offset(x: 1, y: 1)
                        )
                    Text("Timer")
                        .font(.largeTitle)
                        .fontWeight(.medium)
                        .foregroundStyle(Color("EldenBlue"))
                        .shadow(color: .black.opacity(0.9), radius: 4, x: 0, y: 4)
                        .overlay(
                            Text("Timer")
                                .font(.largeTitle)
                                .fontWeight(.medium)
                                .foregroundColor(.white.opacity(0.2))
                                .offset(x: 1, y: 1)
                        )
                }
                .multilineTextAlignment(.center)
                .padding(.top, 40)
                Spacer()
                if day < 3 {
                    VStack(spacing: 30) {
                        Text("Day \(dayName()): \n\(currentPhaseName())")
                            .font(.largeTitle)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.top)
                        
                        ProgressView(value: progressForCurrentPhase())
                            .progressViewStyle(LinearProgressViewStyle(tint: showPhaseWarning ? .yellow : .white))
                            .padding(.horizontal)
                            .animation(.easeInOut(duration: 0.3), value: timeRemaining)
                        
                        Text(timeString(from: timeRemaining))
                            .font(.system(size: 48, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                        
                        if showPhaseWarning {
                            Text(
                                currentPhaseName().contains("Circle") ? "Move to the Safe Zone!" :
                                currentPhaseName().contains("Explore") ? "The Night Rain Approaches!" :
                                "Phase ending soon"
                            )
                                .font(.title2)
                                .foregroundColor(.yellow)
                                .transition(.opacity)
                        }


                        if !isRunning && timeRemaining == 0 && currentPhaseIndex == dayPhases.count - 1 && day < 3 {
                            Button(day + 1 == 3 ? "Fight the Nightlord" : "Start Day \(dayName(for: day + 1))") {
                                day += 1
                                currentPhaseIndex = 0
                                timeRemaining = dayPhases[0].duration
                                wasPaused = false
                                tooltipText = "Start the timer when you see \"Day \(dayName())\" on screen."
                                if day == 2 {
                                    startTimer()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                            .font(.title2)
                            .scaleEffect(1.05)
                            .animation(.easeInOut(duration: 0.2), value: isRunning)
                        } else {
                            HStack(spacing: 20) {
                                Button(buttonLabel()) {
                                    if isRunning {
                                        stopTimer()
                                        wasPaused = true
                                    } else {
                                        startTimer()
                                        wasPaused = false
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.large)
                                .font(.title2)
                                .scaleEffect(isRunning ? 1.0 : 1.05)
                                .animation(.easeInOut(duration: 0.2), value: isRunning)
                            }
                        }

                        Button("Reset") {
                            tooltipText = "Start the timer when you see \"Day One\" on screen."
                            stopTimer()
                            day = 1
                            currentPhaseIndex = 0
                            timeRemaining = dayPhases[0].duration
                            isRunning = false
                            wasPaused = false
                            showPhaseWarning = false
                        }
                        .padding(.top)
                        .controlSize(.large)
                        .font(.title2)
                        .foregroundColor(.white)
                        .buttonStyle(.bordered)
                        .scaleEffect(isRunning ? 1.0 : 1.05)
                        .animation(.easeInOut(duration: 0.2), value: isRunning)
                    
                    Text(tooltipText)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.top, 10)
                        .padding(.horizontal)
                    }
                }

                if day == 3 && !isRunning && currentPhaseIndex == 0 && timeRemaining == dayPhases[0].duration {
                    VStack(spacing: 20) {
                        Text("Nightlord Battle")
                            .font(.largeTitle)
                            .bold()
                            .foregroundColor(.white)
                        Text("Did you win?")
                            .font(.title2)
                            .foregroundColor(.white)

                        HStack(spacing: 20) {
                            Button("Yes") {
                                guard !hasAnswered else { return }
                                let stats = gameStats
                                stats.winCount += 1
                                stats.totalAttempts += 1
                                stats.dateTime = Date()
                                try? viewContext.save()
                                hasAnswered = true
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                            .font(.title2)

                            Button("No") {
                                guard !hasAnswered else { return }
                                let stats = gameStats
                                stats.totalAttempts += 1
                                stats.dateTime = Date()
                                try? viewContext.save()
                                hasAnswered = true
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.large)
                            .font(.title2)
                        }

                        Text("Wins: \(gameStats.winCount)")
                            .font(.title3)
                            .padding(.top)
                            .foregroundColor(.white)

                        Text("Attempts: \(gameStats.totalAttempts)")
                            .font(.title3)
                            .foregroundColor(.white)


                        if gameStats.totalAttempts > 0 {
                            let winRate = Double(gameStats.winCount) / Double(gameStats.totalAttempts) * 100
                            Text(String(format: "Win Rate: %.1f%%", winRate))
                                .font(.title3)
                                .foregroundColor(.white)
                        }

                        Button("Reset Stats") {
                            let stats = gameStats
                            stats.winCount = 0
                            stats.totalAttempts = 0
                            try? viewContext.save()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .foregroundColor(.white)
                        .padding(.top)

                        Button("Restart") {
                            restartGame()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .padding(.top)
                    }
                }
                Spacer()
            }
            .padding()
            .onAppear {
                print("👍 Got a MOC:", viewContext)
                stopTimer()
                timeRemaining = dayPhases[currentPhaseIndex].duration
                UIApplication.shared.isIdleTimerDisabled = !batterySaverEnabled
            }
            .onChange(of: scenePhase) {
                switch scenePhase {
                case .background:
                    if isRunning {
                        backgroundDate = Date()
                    }
                case .active:
                    if let backgroundDate = backgroundDate, isRunning {
                        let elapsed = Date().timeIntervalSince(backgroundDate)
                        timeRemaining = max(0, timeRemaining - elapsed)
                    }
                    backgroundDate = nil
                    UIApplication.shared.isIdleTimerDisabled = !batterySaverEnabled
                default:
                    break
                }
            }
        }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showingSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                        }
                    }
                }
        } // end NavigationStack
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environment(\.managedObjectContext, viewContext)
        }
    }

    func startTimer() {
        if timeRemaining <= 0 {
            timeRemaining = dayPhases[currentPhaseIndex].duration
        }

        if ActivityAuthorizationInfo().areActivitiesEnabled {
            let attributes = NightreignWidgetAttributes(name: "Nightreign")
            let contentState = NightreignWidgetAttributes.ContentState(
                timeRemaining: Int(timeRemaining),
                phaseLabel: currentPhaseName()
            )
            let content = ActivityContent(state: contentState, staleDate: Date().addingTimeInterval(timeRemaining))
            do {
                liveActivity = try Activity.request(attributes: attributes, content: content)
            } catch {
                print("Failed to start live activity: \(error)")
            }
        }

        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            guard isRunning else { return }
            if timeRemaining > 0 {
                timeRemaining -= 1
                if timeRemaining == 30 {
                    triggerHaptic()
                    showPhaseWarning = true
                }
                if timeRemaining == 0 {
                    showPhaseWarning = false
                }

                let sharedDefaults = UserDefaults(suiteName: "group.com.toleary.NightreignTimer")
                sharedDefaults?.set(currentPhaseName(), forKey: "currentPhaseName")
                sharedDefaults?.set(Int(timeRemaining), forKey: "timeRemaining")

                Task {
                    await liveActivity?.update(
                        ActivityContent(
                            state: NightreignWidgetAttributes.ContentState(
                                timeRemaining: Int(timeRemaining),
                                phaseLabel: currentPhaseName()
                            ),
                            staleDate: Date().addingTimeInterval(timeRemaining)
                        )
                    )
                }
            } else {
                advanceToNextPhaseOrPause()
            }
        }
    }
    
    func advanceToNextPhaseOrPause() {
        if currentPhaseIndex + 1 < dayPhases.count {
            currentPhaseIndex += 1
            timeRemaining = dayPhases[currentPhaseIndex].duration
        } else {
            stopTimer()
            Task {
                await liveActivity?.end(
                    ActivityContent(
                        state: NightreignWidgetAttributes.ContentState(
                            timeRemaining: 0,
                            phaseLabel: "Done"
                        ),
                        staleDate: nil
                    ),
                    dismissalPolicy: .immediate
                )
                liveActivity = nil
            }
            timeRemaining = 0
            if day + 1 == 3 {
                tooltipText = ""
            } else {
                tooltipText = "Start the timer when you see \"Day \(dayName(for: day + 1))\" on screen."
            }
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }

    func updateCurrentPhase() {
        // No longer needed with countdown timer.
    }

    func currentPhaseName() -> String {
        if currentPhaseIndex >= dayPhases.count || (timeRemaining == 0 && !isRunning) {
            return "Night Boss Fight"
        }
        return dayPhases[currentPhaseIndex].name
    }
    
    func dayName() -> String {
        switch day {
        case 1: return "One"
        case 2: return "Two"
        case 3: return "Three"
        default: return "\(day)"
        }
    }
    
    func dayName(for index: Int) -> String {
        switch index {
        case 1: return "One"
        case 2: return "Two"
        case 3: return "Three"
        default: return "\(index)"
        }
    }

    func totalDayDuration() -> TimeInterval {
        dayPhases.map { $0.duration }.reduce(0, +)
    }

    func timeString(from interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    func progressForCurrentPhase() -> Double {
        guard currentPhaseIndex < dayPhases.count else { return 1.0 }
        let total = dayPhases[currentPhaseIndex].duration
        return max(0, min(1, (total - timeRemaining) / total))
    }
    
    func buttonLabel() -> String {
        if isRunning {
            return "Pause"
        } else if wasPaused {
            return "Resume"
        } else {
            return "Start Day \(dayName())"
        }
    }

    func restartGame() {
        stopTimer()
        day = 1
        currentPhaseIndex = 0
        timeRemaining = dayPhases[0].duration
        isRunning = false
        wasPaused = false
        showPhaseWarning = false
        hasAnswered = false
        tooltipText = "Start the timer when you see \"Day One\" on screen."
        Task {
            await liveActivity?.end(
                ActivityContent(
                    state: NightreignWidgetAttributes.ContentState(
                        timeRemaining: 0,
                        phaseLabel: "Reset"
                    ),
                    staleDate: nil
                ),
                dismissalPolicy: .immediate
            )
            liveActivity = nil
        }
    }

    func triggerHaptic() {
        let notificationGenerator = UINotificationFeedbackGenerator()
        notificationGenerator.notificationOccurred(.error)

        let impactGenerator = UIImpactFeedbackGenerator(style: .heavy)
        impactGenerator.impactOccurred()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            impactGenerator.impactOccurred()
        }
    }
}

#Preview {
    ContentView()
}
