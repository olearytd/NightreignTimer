import SwiftUI
import CloudKit

struct SettingsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @State private var iCloudStatus: CKAccountStatus?

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("iCloud Sync")) {
                    if let status = iCloudStatus {
                        switch status {
                        case .available:
                            Label("Sync Enabled", systemImage: "cloud.fill")
                        case .noAccount:
                            Label("No iCloud Account", systemImage: "cloud.slash")
                        case .restricted:
                            Label("iCloud Restricted", systemImage: "exclamationmark.triangle")
                        case .couldNotDetermine:
                            Label("Unknown Status", systemImage: "questionmark")
                        default:
                            Label("Unknown Status", systemImage: "questionmark")
                        }
                    } else {
                        Text("Checking iCloud status…")
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                verifyICloudAccount()
            }
        }
    }

    private func verifyICloudAccount() {
        CKContainer.default().accountStatus { status, error in
            DispatchQueue.main.async {
                iCloudStatus = status
            }
        }
    }
}
