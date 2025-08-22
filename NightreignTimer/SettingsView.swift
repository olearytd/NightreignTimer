import SwiftUI
import CloudKit
import CoreData

struct SettingsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @AppStorage("batterySaverEnabled") private var batterySaverEnabled: Bool = false

    @State private var iCloudStatus: CKAccountStatus?
    @State private var isSyncing: Bool = false
    @State private var lastSync: Date?
    @State private var ckEventToken: NSObjectProtocol?
    @State private var lastCKError: String?
    @State private var lastCKEvent: String?

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
                    if let last = lastSync {
                        Label {
                            Text(String(format: NSLocalizedString("last_sync_format", comment: "Last Sync"),
                                        DateFormatter.localizedString(from: last, dateStyle: .short, timeStyle: .short)))
                        } icon: {
                            Image(systemName: "clock.arrow.2.circlepath")
                        }
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    }

                    if let ev = lastCKEvent {
                        Label {
                            Text(ev)
                        } icon: {
                            Image(systemName: "waveform.path.ecg")
                        }
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    }

                    if let err = lastCKError {
                        Label {
                            Text(err)
                        } icon: {
                            Image(systemName: "exclamationmark.triangle")
                        }
                        .font(.footnote)
                        .foregroundColor(.orange)
                    }

                    Button(action: { manualSync() }) {
                        if isSyncing {
                            HStack {
                                ProgressView()
                                Text(NSLocalizedString("syncing", comment: "Syncing label"))
                            }
                        } else {
                            Label(NSLocalizedString("sync_now", comment: "Sync Now label"), systemImage: "arrow.clockwise.circle")
                        }
                    }
                    .disabled(isSyncing)
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
                // Observe CloudKit import/export events to update lastSync
                ckEventToken = NotificationCenter.default.addObserver(
                    forName: NSPersistentCloudKitContainer.eventChangedNotification,
                    object: nil,
                    queue: .main
                ) { note in
                    if let event = note.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey] as? NSPersistentCloudKitContainer.Event {
                        switch event.type {
                        case .import:
                            lastSync = Date()
                            lastCKEvent = NSLocalizedString("ck_event_import", comment: "CloudKit import event")
                        case .export:
                            lastSync = Date()
                            lastCKEvent = NSLocalizedString("ck_event_export", comment: "CloudKit export event")
                        case .setup:
                            lastCKEvent = NSLocalizedString("ck_event_setup", comment: "CloudKit setup event")
                        default:
                            lastCKEvent = NSLocalizedString("ck_event_other", comment: "CloudKit other event")
                        }

                        // If the event carried an error, surface it regardless of type
                        if let nsErr = (event as NSObject).value(forKey: "error") as? NSError {
                            lastCKError = nsErr.localizedDescription
                            lastCKEvent = NSLocalizedString("ck_event_error", comment: "CloudKit error event")
                        }
                    }
                }
            }
            .onDisappear {
                if let token = ckEventToken {
                    NotificationCenter.default.removeObserver(token)
                    ckEventToken = nil
                }
            }
        }
    }

    private func manualSync() {
        guard !isSyncing else { return }
        isSyncing = true

        let ctx = viewContext
        ctx.perform {
            do {
                if ctx.hasChanges { try ctx.save() }
            } catch {
                // Ignore save errors for this manual nudge
            }

            if let psc = ctx.persistentStoreCoordinator {
                let bg = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
                bg.persistentStoreCoordinator = psc
                bg.perform {
                    do { try bg.save() } catch { }
                    DispatchQueue.main.async {
                        lastSync = Date()
                        isSyncing = false
                    }
                }
            } else {
                DispatchQueue.main.async {
                    lastSync = Date()
                    isSyncing = false
                }
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
