import SwiftUI

struct SetupView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedGameType = "Solo"
    @State private var selectedCharacter = "Wylder"
    @State private var selectedNightLord = "Tricephalos"
    @State private var navigateToMain = false
    @State private var showingSettings = false
    @State private var showingRecords = false

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
        "Tricephalos (Everdark)",
        "Gaping Jaw (Everdark)",
        "Sentient Pest (Everdark)",
        "Augur (Everdark)",
        "Equilibrious Beast (Everdark)",
        "Darkdrift Knight (Everdark)",
        "Fissure in the Fog (Everdark)",
        "Night Aspect (Everdark)",
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
                        SelectField(title: "game_type", options: gameTypes, selection: $selectedGameType)
                        SelectField(title: "hero_name",  options: characters, selection: $selectedCharacter)
                        SelectField(title: "nightlord_name", options: nightLords, selection: $selectedNightLord)
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
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingRecords = true } label: {
                        Image(systemName: "book")
                    }
                    .accessibilityLabel(Text(NSLocalizedString("records", comment: "Records")))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingSettings = true } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environment(\.managedObjectContext, viewContext)
        }
        .sheet(isPresented: $showingRecords) {
            RecordsView()
                .environment(\.managedObjectContext, viewContext)
        }
            .navigationDestination(isPresented: $navigateToMain) {
                ContentView()
                    .environment(\.managedObjectContext, viewContext)
            }
        }
    }

    private func saveSetup() {
        let defaults = UserDefaults.standard
        defaults.set(selectedGameType,  forKey: "selectedGameType")
        defaults.set(selectedCharacter,  forKey: "selectedCharacter")
        defaults.set(selectedNightLord, forKey: "selectedNightLord")
    }
}

struct SelectField: View {
    let title: String
    let options: [String]
    @Binding var selection: String
    @State private var isPresenting = false
    @State private var query = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(NSLocalizedString(title, comment: ""))
                .font(.title3).fontWeight(.medium)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .center)

            Button {
                isPresenting = true
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 48)
                    HStack {
                        Text(selection).foregroundColor(.white.opacity(0.9))
                        Spacer()
                        Image(systemName: "chevron.down").foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.horizontal)
                }
            }
            .sheet(isPresented: $isPresenting) {
                NavigationStack {
                    List(filtered) { item in
                        Button {
                            selection = item.value
                            isPresenting = false
                        } label: {
                            HStack {
                                Text(item.value)
                                if item.value == selection {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                        }
                    }
                    .searchable(text: $query)
                    .navigationTitle(NSLocalizedString(title, comment: ""))
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button(NSLocalizedString("done", comment: "Done button")) { isPresenting = false }
                        }
                    }
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
    }

    private var filtered: [Item] {
        let items = options.map { Item(value: $0) }
        return query.isEmpty ? items : items.filter { $0.value.localizedCaseInsensitiveContains(query) }
    }

    private struct Item: Identifiable {
        var id: String { value }
        let value: String
    }
}
