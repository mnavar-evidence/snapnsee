import SwiftUI
import SwiftData

struct ServiceSelectorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var preferences: [UserPreferences]

    var currentPreferences: UserPreferences {
        if let existing = preferences.first {
            return existing
        } else {
            let new = UserPreferences()
            modelContext.insert(new)
            return new
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("My Streaming Services")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Select the services you have access to. We'll show you where to watch items from your watchlist.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.top)

                    // Service Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(StreamingService.allServices) { service in
                            ServiceCard(
                                service: service,
                                isSelected: currentPreferences.hasService(service.id),
                                onTap: {
                                    withAnimation(.spring(response: 0.3)) {
                                        currentPreferences.toggleService(service.id)
                                        try? modelContext.save()
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal)

                    // Summary
                    if currentPreferences.hasAnyServices {
                        VStack(spacing: 12) {
                            Divider()

                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("\(currentPreferences.selectedServices.count) service\(currentPreferences.selectedServices.count == 1 ? "" : "s") selected")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding(.horizontal)
                        }
                    }

                    Spacer(minLength: 40)
                }
            }
            .navigationTitle("Streaming Services")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ServiceCard: View {
    let service: StreamingService
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color(hex: service.color).opacity(0.1))
                        .frame(width: 60, height: 60)

                    Image(systemName: service.logoName)
                        .font(.system(size: 28))
                        .foregroundColor(Color(hex: service.color))
                }

                Text(service.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color(hex: service.color).opacity(0.1) : Color.gray.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        isSelected ? Color(hex: service.color) : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
