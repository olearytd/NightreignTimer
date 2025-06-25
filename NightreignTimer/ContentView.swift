import SwiftUI
import ActivityKit

struct GameTimerPhase {
    let name: String
    let duration: TimeInterval
}

let dayPhases = [
    GameTimerPhase(name: "Explore", duration: 270),   // 4:30
    GameTimerPhase(name: "First Circle Closing", duration: 180),   // 3:00
    GameTimerPhase(name: "Explore", duration: 210),   // 3:30
    GameTimerPhase(name: "Last Circle Closing", duration: 180)   // 3:00
//    GameTimerPhase(name: "Explore", duration: 5),   // test
//    GameTimerPhase(name: "Circle Closing", duration: 5),   // test
//    GameTimerPhase(name: "Explore", duration: 5),   // test
//    GameTimerPhase(name: "Circle Closing", duration: 5)   // test
]

struct ContentView: View {
    @State private var timer: Timer? = nil
    @State private var timeRemaining: TimeInterval = dayPhases.first?.duration ?? 0
    @State private var isRunning = false
    @State private var currentPhaseIndex = 0
    @State private var day = 1
    @State private var wasPaused = false
    @State private var hasAnswered = false
    @State private var backgroundDate: Date? = nil
    @Environment(\.scenePhase) var scenePhase
    @AppStorage("winCount") private var winCount = 0
    @AppStorage("totalAttempts") private var totalAttempts = 0
    @State private var liveActivity: Activity<NightreignWidgetAttributes>?

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 54/255, green: 44/255, blue: 30/255), // warm deep bronze
                    Color(red: 20/255, green: 20/255, blue: 20/255)  // soft black
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            VStack(spacing: 30) {
                VStack(spacing: 4) {
                    Text("Elden Ring: Nightreign")
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color("EldenGold"))
                        .shadow(color: .black.opacity(0.8), radius: 2, x: 0, y: 1)
                    Text("Timer")
                        .font(.largeTitle)
                        .fontWeight(.medium)
                        .foregroundStyle(Color("EldenGold"))
                        .shadow(color: .black.opacity(0.8), radius: 2, x: 0, y: 1)
                }
                .multilineTextAlignment(.center)
                .padding(.top)
                if day < 3 {
                    VStack(spacing: 30) {
                        Text("Day \(day) – Phase \(currentPhaseIndex + 1) of \(dayPhases.count)")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding(.top)
                        
                        ProgressView(value: progressForCurrentPhase())
                            .progressViewStyle(LinearProgressViewStyle(tint: .white))
                            .padding(.horizontal)
                            .animation(.easeInOut(duration: 0.3), value: timeRemaining)
                        
                        Text(timeString(from: timeRemaining))
                            .font(.system(size: 48, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)

                        Text("Phase: \(currentPhaseName())")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                            .transition(.opacity)
                            .animation(.easeInOut, value: currentPhaseIndex)

                        if !isRunning && timeRemaining == 0 && currentPhaseIndex == dayPhases.count - 1 && day < 3 {
                            Button("Start Day \(day + 1)") {
                                day += 1
                                currentPhaseIndex = 0
                                timeRemaining = dayPhases[0].duration
                                wasPaused = false
                                if day == 2 {
                                    startTimer()
                                }
                            }
                            .buttonStyle(.borderedProminent)
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
                                .scaleEffect(isRunning ? 1.0 : 1.05)
                                .animation(.easeInOut(duration: 0.2), value: isRunning)
                            }
                        }

                        Button("Reset") {
                            stopTimer()
                            day = 1
                            currentPhaseIndex = 0
                            timeRemaining = dayPhases[0].duration
                            isRunning = false
                            wasPaused = false
                        }
                        .padding(.top)
                        .buttonStyle(.bordered)
                        .scaleEffect(isRunning ? 1.0 : 1.05)
                        .animation(.easeInOut(duration: 0.2), value: isRunning)
                    }
                }

                if day == 3 && !isRunning && currentPhaseIndex == 0 && timeRemaining == dayPhases[0].duration {
                    VStack(spacing: 20) {
                        Text("Nightlord Battle")
                            .font(.largeTitle)
                            .bold()
                        Text("Did you win?")
                            .font(.title2)

                        HStack(spacing: 20) {
                            Button("Yes") {
                                guard !hasAnswered else { return }
                                winCount += 1
                                totalAttempts += 1
                                hasAnswered = true
                            }
                            .buttonStyle(.borderedProminent)

                            Button("No") {
                                guard !hasAnswered else { return }
                                totalAttempts += 1
                                hasAnswered = true
                            }
                            .buttonStyle(.bordered)
                        }

                        Text("Wins: \(winCount)")
                            .font(.headline)
                            .padding(.top)

                        Text("Attempts: \(totalAttempts)")
                            .font(.subheadline)

                        if totalAttempts > 0 {
                            let winRate = Double(winCount) / Double(totalAttempts) * 100
                            Text(String(format: "Win Rate: %.1f%%", winRate))
                                .font(.subheadline)
                        }

                        Button("Reset Stats") {
                            winCount = 0
                            totalAttempts = 0
                        }
                        .buttonStyle(.bordered)
                        .padding(.top)

                        Button("Restart") {
                            restartGame()
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.top)
                    }
                }
            }
            .padding()
            .onAppear {
                stopTimer()
                timeRemaining = dayPhases[currentPhaseIndex].duration
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
                default:
                    break
                }
            }
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
            return "Stop"
        } else if wasPaused {
            return "Resume"
        } else {
            return "Start Day \(day)"
        }
    }

    func restartGame() {
        stopTimer()
        day = 1
        currentPhaseIndex = 0
        timeRemaining = dayPhases[0].duration
        isRunning = false
        wasPaused = false
        hasAnswered = false
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
}

#Preview {
    ContentView()
}
