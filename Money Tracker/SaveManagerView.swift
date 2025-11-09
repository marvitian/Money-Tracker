import SwiftUI
import UIKit   // required for ActivityView (UIActivityViewController)

// SaveManagerView: UI to create / list / load / export saves
struct SaveManagerView: View {
    @EnvironmentObject var financeData: FinanceData
    @Environment(\.dismiss) var dismiss

    @State private var saveName: String = ""
    @State private var snapshots: [SnapshotFileInfo] = []
    @State private var shareURL: URL? = nil
    @State private var showingShare = false
    @State private var alertMessage: String? = nil

    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    TextField("Name this save", text: $saveName)
                        .textFieldStyle(.roundedBorder)
                    Button("Save") {
                        let name = saveName.isEmpty ? "Save" : saveName
                        if let _ = financeData.saveSnapshot(named: name) {
                            refresh()
                            saveName = ""
                        } else {
                            alertMessage = "Save failed."
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()

                List {
                    ForEach(snapshots) { item in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(item.name).font(.headline)
                                Text(item.createdAt, format: .dateTime.year().month().day().hour().minute())
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Button("Load") {
                                _ = financeData.loadSnapshot(filename: item.filename)
                                refresh()
                            }
                            .buttonStyle(.bordered)

                            Button("Export") {
                                shareURL = financeData.urlForSnapshot(filename: item.filename)
                                showingShare = true
                            }
                            .buttonStyle(.bordered)
                            .padding(.leading, 6)
                        }
                    }
                    .onDelete(perform: delete)
                }
            }
            .navigationTitle("Saves")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear(perform: refresh)
            .sheet(isPresented: $showingShare) {
                if let url = shareURL {
                    ActivityView(activityItems: [url])
                }
            }
            // show alert if string set
            .alert(item: $alertMessage) { msg in
                Alert(title: Text("Error"), message: Text(msg), dismissButton: .default(Text("OK")))
            }
        }
    }

    func refresh() {
        snapshots = financeData.listSnapshots()
    }

    func delete(at offsets: IndexSet) {
        let toDelete = offsets.map { snapshots[$0].filename }
        for f in toDelete {
            _ = financeData.deleteSnapshot(filename: f)
        }
        refresh()
    }
}

// MARK: - Helpers

/// Make String conform to Identifiable so we can use .alert(item:)
extension String: Identifiable {
    public var id: String { self }
}

// UIKit share-sheet wrapper (ActivityView)
struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
