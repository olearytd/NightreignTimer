import SwiftUI

struct SetupView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedGameType = "Solo"
    @State private var selectedCharacter = "Wylder"
    @State private var selectedNightLord = "Tricephalos"
    @State private var navigateToMain = false

    let gameTypes = ["Solo", "Duos", "Trios"]
    let characters = ["Wylder", "Ironeye", "Duchess", "Guardian", "Raider", "Recluse", "Revenant", "Executor"]
    let nightLords = [
        "Tricephalos",
        "Gaping Jaw",
        "Sentient Pest",
        "Augur",
        "Equilibrious Beast",
        "Darkdrift Knight",
        "Fissure in the Fog",
        "Night Aspect",
        "Gaping Jaw (Everdark)",
        "Sentient Pest (Everdark)",
        "Augur (Everdark)",
        "Darkdrift Knight (Everdark)",
        "Fissure in the Fog (Everdark)"
    ]

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
                        Text(NSLocalizedString("title_er_nightreign_timer", comment: "Title: ER Nightreign Timer"))
                            .font(.largeTitle)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color("EldenBlue"))
                            .shadow(color: .black.opacity(0.9), radius: 4, x: 0, y: 4)
                            .overlay(
                                Text(NSLocalizedString("title_er_nightreign_timer", comment: "Title: ER Nightreign Timer"))
                                    .font(.largeTitle)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white.opacity(0.2))
                                    .offset(x: 1, y: 1)
                            )
                    }
                    .multilineTextAlignment(.center)
                    .padding(.top, 40)

                    Spacer()

                    Text(NSLocalizedString("setup_description", comment: "Setup Description Tooltip"))
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    VStack(spacing: 36) {
                        // Game Type Picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text(NSLocalizedString("game_type", comment: "Game Type Selection"))
                                .font(.title3)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .center)
                            GeometryReader { geometry in
                                ZStack {
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(Color.white.opacity(0.08))
                                    HStack {
                                        Spacer()
                                        Picker(NSLocalizedString("game_type", comment: "Game Type Selection"), selection: $selectedGameType) {
                                            ForEach(gameTypes, id: \.self) { type in
                                                Text(type)
                                            }
                                        }
                                        .pickerStyle(.menu)
                                        .labelsHidden()
                                        // Removed .frame(maxWidth: .infinity) here
                                        Spacer()
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .contentShape(Rectangle())
                                .frame(width: geometry.size.width * 0.8, height: 48)
                                .position(x: geometry.size.width / 2, y: 24)
                            }
                            .frame(height: 48)
                        }

                        // Character Picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text(NSLocalizedString("hero_name", comment: "Hero Selection"))
                                .font(.title3)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .center)
                            GeometryReader { geometry in
                                ZStack {
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(Color.white.opacity(0.08))
                                    HStack {
                                        Spacer()
                                        Picker(NSLocalizedString("hero_name", comment: "Hero Selection"), selection: $selectedCharacter) {
                                            ForEach(characters, id: \.self) { character in
                                                Text(character)
                                            }
                                        }
                                        .pickerStyle(.menu)
                                        .labelsHidden()
                                        // Removed .frame(maxWidth: .infinity) here
                                        Spacer()
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .contentShape(Rectangle())
                                .frame(width: geometry.size.width * 0.8, height: 48)
                                .position(x: geometry.size.width / 2, y: 24)
                            }
                            .frame(height: 48)
                        }

                        // Nightlord Picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text(NSLocalizedString("nightlord_name", comment: "Nightlord Selection"))
                                .font(.title3)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .center)
                            GeometryReader { geometry in
                                ZStack {
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(Color.white.opacity(0.08))
                                    HStack {
                                        Spacer()
                                        Picker(NSLocalizedString("nightlord_name", comment: "Nightlord Selection"), selection: $selectedNightLord) {
                                            ForEach(nightLords, id: \.self) { lord in
                                                Text(lord)
                                            }
                                        }
                                        .pickerStyle(.menu)
                                        .labelsHidden()
                                        // Removed .frame(maxWidth: .infinity) here
                                        Spacer()
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .contentShape(Rectangle())
                                .frame(width: geometry.size.width * 0.8, height: 48)
                                .position(x: geometry.size.width / 2, y: 24)
                            }
                            .frame(height: 48)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 24)
                    .padding(.top, 20)

                    Button(NSLocalizedString("ready", comment: "ready")) {
                        saveSetup()
                        navigateToMain = true
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .font(.title2)
                    .padding(.top, 40)

                    Spacer()
                }
                .padding(.horizontal)
            }
            .navigationDestination(isPresented: $navigateToMain) {
                ContentView()
                    .environment(\.managedObjectContext, viewContext)
            }
        }
    }

    private func saveSetup() {
        let stats = GameStats(context: viewContext)
        stats.id = UUID()
        stats.gameType = selectedGameType
        stats.character = selectedCharacter
        stats.nightLord = selectedNightLord
        stats.dateTime = Date()
        stats.winCount = 0
        stats.totalAttempts = 0
        try? viewContext.save()
    }
}
