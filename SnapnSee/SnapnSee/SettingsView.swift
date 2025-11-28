import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var preferences: [UserPreferences]
    @State private var showServiceSelector = false

    var currentPreferences: UserPreferences {
        if let existing = preferences.first {
            return existing
        } else {
            let new = UserPreferences()
            modelContext.insert(new)
            try? modelContext.save()
            return new
        }
    }

    var body: some View {
        NavigationView {
            List {
                // Streaming Services Section
                Section {
                    Button(action: { showServiceSelector = true }) {
                        HStack {
                            Image(systemName: "tv.fill")
                                .foregroundColor(.blue)
                                .frame(width: 30)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Streaming Services")
                                    .foregroundColor(.primary)

                                if currentPreferences.hasAnyServices {
                                    Text("\(currentPreferences.selectedServices.count) service\(currentPreferences.selectedServices.count == 1 ? "" : "s") selected")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                } else {
                                    Text("None selected")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Services")
                } footer: {
                    Text("Select which streaming services you have access to")
                }

                // Notifications Section
                Section {
                    Toggle(isOn: Binding(
                        get: { currentPreferences.weeklyDigestEnabled },
                        set: { newValue in
                            currentPreferences.weeklyDigestEnabled = newValue
                            try? modelContext.save()
                        }
                    )) {
                        HStack {
                            Image(systemName: "bell.fill")
                                .foregroundColor(.orange)
                                .frame(width: 30)
                            Text("Weekly Digest")
                        }
                    }

                    if currentPreferences.weeklyDigestEnabled {
                        HStack {
                            Image(systemName: "clock.fill")
                                .foregroundColor(.purple)
                                .frame(width: 30)
                            Text("Notification Time")

                            Spacer()

                            Text(formatNotificationTime(currentPreferences.notificationTime))
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Notifications")
                } footer: {
                    Text("Get weekly reminders about items in your watchlist")
                }

                // About Section
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.3")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Recognition Engine")
                        Spacer()
                        Text("GPT-4o Vision")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showServiceSelector) {
                ServiceSelectorView()
            }
        }
    }

    func formatNotificationTime(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
        return formatter.string(from: date)
    }
}
