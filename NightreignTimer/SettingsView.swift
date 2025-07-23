import SwiftUI
import CloudKit

struct SettingsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @AppStorage("batterySaverEnabled") private var batterySaverEnabled: Bool = false

    @State private var iCloudStatus: CKAccountStatus?

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(NSLocalizedString("icloud_sync", comment: "iCloud Sync label"))) {
                    if let status = iCloudStatus {
                        switch status {
                        case .available:
                            Label(NSLocalizedString("sync_enabled", comment: "Sync Enabled label"), systemImage: "cloud.fill")
                        case .noAccount:
                            Label(NSLocalizedString("no_icloud_account", comment: "No Account label"), systemImage: "cloud.slash")
                        case .restricted:
                            Label(NSLocalizedString("icloud_restricted", comment: "iCloud Restricted label"), systemImage: "exclamationmark.triangle")
                        case .couldNotDetermine:
                            Label(NSLocalizedString("unknown_status", comment: "Unknown Status label"), systemImage: "questionmark")
                        default:
                            Label(NSLocalizedString("unknown_status", comment: "Unknown Status label"), systemImage: "questionmark")
                        }
                    } else {
                        Text(NSLocalizedString("check_icloud_status", comment: "iCloud Status text"))
                    }
                }
                Section(header: Text(NSLocalizedString("battery", comment: "Battery label"))) {
                    Toggle(NSLocalizedString("battery_saver", comment: "Battery Saver label"), isOn: $batterySaverEnabled)
                    Text(NSLocalizedString("battery_info", comment: "Battery info text"))
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle(NSLocalizedString("settings", comment: "Settings label"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(NSLocalizedString("done", comment: "Done phase label")) {
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
