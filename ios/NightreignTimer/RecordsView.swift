import SwiftUI
import CoreData
import UniformTypeIdentifiers

struct CSVDocument: FileDocument {
    static var readableContentTypes: [UTType] = [.commaSeparatedText]
    var text: String

    init(text: String) { self.text = text }

    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents,
           let s = String(data: data, encoding: .utf8) {
            self.text = s
        } else {
            self.text = ""
        }
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = text.data(using: .utf8) ?? Data()
        return .init(regularFileWithContents: data)
    }
}

struct RecordsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    // Aggregate “singleton” access you were using earlier
    @FetchRequest(
        entity: GameStats.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \GameStats.id, ascending: false)]
    ) private var statsAggregateFetch: FetchedResults<GameStats>

    // Table rows: GameStats sorted by dateTime (oldest -> newest)
    @FetchRequest(
        entity: GameStats.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \GameStats.dateTime, ascending: true)],
        predicate: NSPredicate(format: "dateTime != nil")
    ) private var records: FetchedResults<GameStats>

    @State private var showResetConfirm = false
    @State private var isExportingCSV = false
    @State private var csvDoc = CSVDocument(text: "")

    private var gameStats: GameStats {
        if let existing = statsAggregateFetch.first {
            return existing
        } else {
            let newStats = GameStats(context: viewContext)
            newStats.id = UUID()
            newStats.winCount = 0
            newStats.totalAttempts = 0
            newStats.dateTime = nil
            return newStats
        }
    }

    private let rowDateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        return df
    }()
    
    private let iso8601 = ISO8601DateFormatter()

    private func csvField(_ value: String) -> String {
        // Quote and escape internal quotes per RFC 4180
        "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
    }

    private func makeCSV() -> String {
        // Export ALL attributes in a consistent order, using ISO-8601 for date and raw values for the rest.
        let header = [
            "character",
            "nightLord",
            "gameType",
            "dateTime",
            "didWin",
            "id"
        ].joined(separator: ",")
        var lines: [String] = [header]
        for record in records {
            let character = record.character ?? ""
            let nightLord = record.nightLord ?? ""
            let gameType = record.gameType ?? ""
            let dateTime = record.dateTime.map { iso8601.string(from: $0) } ?? ""
            let didWin = record.didWin ? "Win" : "Loss"
            let id = (record.value(forKey: "id") as? UUID)?.uuidString
                ?? (record.responds(to: Selector(("id"))) ? "\(record.value(forKey: "id") ?? "")" : "")
            lines.append([
                csvField(character),
                csvField(nightLord),
                csvField(gameType),
                csvField(dateTime),
                csvField(didWin),
                csvField(id)
            ].joined(separator: ","))
        }
        return lines.joined(separator: "\n")
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    // Header row
                    HStack {
                        Text(NSLocalizedString("hero_name", comment: "Hero column"))
                            .font(.footnote).foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(NSLocalizedString("nightlord_name", comment: "Boss column"))
                            .font(.footnote).foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(NSLocalizedString("result", comment: "Result column"))
                            .font(.footnote).foregroundStyle(.secondary)
                            .frame(width: 70, alignment: .leading)
                    }
                }

                ForEach(records) { record in
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Text(record.character ?? "-")
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text(record.nightLord ?? "-")
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text(record.didWin ? NSLocalizedString("win", comment: "Win") : NSLocalizedString("loss", comment: "Loss"))
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background((record.didWin ? Color.green : Color.red).opacity(0.15))
                            .clipShape(Capsule())
                            .frame(width: 70, alignment: .leading)
                    }
                    .contentShape(Rectangle())
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(record.character ?? ""), \(record.nightLord ?? ""), \(record.didWin ? NSLocalizedString("win", comment: "Win") : NSLocalizedString("loss", comment: "Loss"))")
                }

                if records.isEmpty {
                    VStack(spacing: 8) {
                        Text(NSLocalizedString("no_runs_yet", comment: "No runs yet"))
                            .font(.headline)
                        Text(NSLocalizedString("no_runs_yet_hint", comment: "Complete a run to see it here."))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(NSLocalizedString("records", comment: "Records"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                    }
                    .accessibilityLabel(Text(NSLocalizedString("close", comment: "Close")))
                }

                ToolbarItem(placement: .bottomBar) {
                    HStack {
                        Button {
                            csvDoc.text = makeCSV()
                            isExportingCSV = true
                        } label: {
                            Label(NSLocalizedString("export_csv", comment: "Export CSV"), systemImage: "square.and.arrow.up")
                        }

                        Spacer(minLength: 16)

                        Button(role: .destructive) {
                            showResetConfirm = true
                        } label: {
                            Text(NSLocalizedString("reset_stats", comment: "Reset Stats"))
                        }
                        .accessibilityHint(Text(NSLocalizedString("reset_stats_hint", comment: "Clears all run history and totals")))
                    }
                }
            }
            .alert(NSLocalizedString("reset_stats_confirm_title", comment: "Confirm Reset"),
                   isPresented: $showResetConfirm) {
                Button(NSLocalizedString("cancel", comment: "Cancel"), role: .cancel) { }
                Button(NSLocalizedString("reset", comment: "Reset"), role: .destructive) {
                    // Clear aggregate
                    let stats = gameStats
                    stats.winCount = 0
                    stats.totalAttempts = 0
                    stats.dateTime = nil

                    // Delete all GameStats rows (used as records here)
                    records.forEach { viewContext.delete($0) }

                    try? viewContext.save()
                }
            } message: {
                Text(NSLocalizedString("reset_stats_confirm_message",
                                       comment: "Are you sure you want to clear all records?"))
            }
            .fileExporter(isPresented: $isExportingCSV,
                          document: csvDoc,
                          contentType: .commaSeparatedText,
                          defaultFilename: "Nightreign_Records") { _ in }
        }
    }
}

#Preview {
    RecordsView().environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
