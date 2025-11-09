import SwiftUI
import Combine

// MARK: - Models

struct Expense: Identifiable, Codable {
    var id = UUID()
    var title: String
    var amount: Double
    var date: Date
}

struct RecurringExpense: Codable, Identifiable {
    var id = UUID()
    var title: String
    var amount: Double
    var startDate: Date
    var recurrenceType: RecurrenceType

    /// Use String raw values so Codable is unambiguous across files/compilations
    enum RecurrenceType: String, Codable {
        case weekly
        case biweekly
        case monthly
    }
}

struct Paycheck: Identifiable, Codable {
    var id = UUID()
    var amount: Double
    var date: Date
}

// MARK: - FinanceData

class FinanceData: ObservableObject {
    @Published var expenses: [Expense] = []
    @Published var paychecks: [Paycheck] = []
    @Published var recurringExpenses: [RecurringExpense] = []

    @Published var paycheckStartDate: Date? = Calendar.current.date(from: DateComponents(year: 2025, month: 11, day: 14))
    let paycheckInterval: TimeInterval = 14 * 24 * 60 * 60 // two weeks in seconds

    private let expensesKey = "expenses"
    private let paychecksKey = "paychecks"
    private let recurringExpensesKey = "recurringExpenses" // NEW

    init() {
        loadData()
    }

    // MARK: - Public methods

    func addExpense(_ expense: Expense) {
        expenses.append(expense)
        saveData()
    }

    func addPaycheck(_ paycheck: Paycheck) {
        paychecks.append(paycheck)
        saveData()
    }

    // MARK: - Persistence

    private func saveData() {
        let encoder = JSONEncoder()
        if let expensesData = try? encoder.encode(expenses) {
            UserDefaults.standard.set(expensesData, forKey: expensesKey)
        }
        if let paychecksData = try? encoder.encode(paychecks) {
            UserDefaults.standard.set(paychecksData, forKey: paychecksKey)
        }
        // save recurring expenses too
        if let recurringData = try? encoder.encode(recurringExpenses) {
            UserDefaults.standard.set(recurringData, forKey: recurringExpensesKey)
        }
    }

    private func loadData() {
        let decoder = JSONDecoder()
        if let expenseData = UserDefaults.standard.data(forKey: expensesKey),
           let decodedExpenses = try? decoder.decode([Expense].self, from: expenseData) {
            self.expenses = decodedExpenses
        }

        if let paychecksData = UserDefaults.standard.data(forKey: paychecksKey),
           let decodedPaychecks = try? decoder.decode([Paycheck].self, from: paychecksData) {
            self.paychecks = decodedPaychecks
        }

        if let recurringData = UserDefaults.standard.data(forKey: recurringExpensesKey),
           let decodedRecurring = try? decoder.decode([RecurringExpense].self, from: recurringData) {
            self.recurringExpenses = decodedRecurring
        }
    }

    // MARK: - Balance calculation

    func balance(on date: Date) -> Double {
        let manualPay = paychecks.filter { $0.date <= date }
                                 .reduce(0) { $0 + $1.amount }
        let autoPay = autoPaychecks(upTo: date).reduce(0) { $0 + $1.amount }

        let manualExp = expenses.filter { $0.date <= date }
                                .reduce(0) { $0 + $1.amount }
        let autoExp = autoExpenses(upTo: date).reduce(0) { $0 + $1.amount }

        return (manualPay + autoPay) - (manualExp + autoExp)
    }

    // MARK: - Auto paycheck generator

    func autoPaychecks(upTo date: Date) -> [Paycheck] {
        guard let start = paycheckStartDate else { return [] }
        var autoList: [Paycheck] = []

        var nextDate = start
        while nextDate <= date {
            // only add if this date isn't already in paychecks
            if !paychecks.contains(where: { Calendar.current.isDate($0.date, inSameDayAs: nextDate) }) {
                autoList.append(Paycheck(amount: paychecks.first?.amount ?? 0, date: nextDate))
            }
            nextDate = nextDate.addingTimeInterval(paycheckInterval)
        }
        return autoList
    }

    // MARK: - Auto Expenses

    func autoExpenses(upTo date: Date) -> [Expense] {
        var autoList: [Expense] = []
        let calendar = Calendar.current

        for recurring in recurringExpenses {
            var nextDate = recurring.startDate

            while nextDate <= date {
                // Avoid duplicates
                if !expenses.contains(where: { calendar.isDate($0.date, inSameDayAs: nextDate) && $0.title == recurring.title }) {
                    autoList.append(Expense(title: recurring.title, amount: recurring.amount, date: nextDate))
                }

                // Calculate next date based on recurrence type
                switch recurring.recurrenceType {
                case .weekly:
                    nextDate = calendar.date(byAdding: .weekOfYear, value: 1, to: nextDate)!
                case .biweekly:
                    nextDate = calendar.date(byAdding: .weekOfYear, value: 2, to: nextDate)!
                case .monthly:
                    nextDate = calendar.date(byAdding: .month, value: 1, to: nextDate)!
                }
            }
        }

        return autoList
    }

    // MARK: - Removal functions

    func removeExpense(at offsets: IndexSet) {
        expenses.remove(atOffsets: offsets)
        saveData()
    }

    func removePaycheck(at offsets: IndexSet) {
        paychecks.remove(atOffsets: offsets)
        saveData()
    }

    func removeRecurringExpense(at offsets: IndexSet) {
        recurringExpenses.remove(atOffsets: offsets)
        saveData()
    }
    
    // MARK: - Multiple saves again
    // Create Snapshot type (if you don't already have one)
    struct Snapshot: Codable, Identifiable {
        var id: UUID = UUID()
        var name: String
        var createdAt: Date = Date()
        var expenses: [Expense]
        var paychecks: [Paycheck]
        var recurringExpenses: [RecurringExpense]
    }

    // Save the current app state as a snapshot file, return filename on success
    @discardableResult
    func saveSnapshot(named name: String) -> String? {
        let snapshot = Snapshot(name: name, expenses: expenses, paychecks: paychecks, recurringExpenses: recurringExpenses)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        do {
            let data = try encoder.encode(snapshot)
            let filename = SaveFiles.filename(for: name)
            let url = SaveFiles.urlFor(filename: filename)
            try data.write(to: url, options: [.atomicWrite])
            return filename
        } catch {
            print("saveSnapshot error:", error)
            return nil
        }
    }

    // List snapshots for UI
    func listSnapshots() -> [SnapshotFileInfo] {
        let urls = SaveFiles.listSaveFiles()
        var out: [SnapshotFileInfo] = []
        for url in urls {
            if let snapshot = try? JSONDecoder().decode(Snapshot.self, from: Data(contentsOf: url)) {
                out.append(SnapshotFileInfo(filename: url.lastPathComponent, name: snapshot.name, createdAt: snapshot.createdAt, size: (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0))
            } else {
                let rv = try? url.resourceValues(forKeys: [.creationDateKey, .fileSizeKey])
                out.append(SnapshotFileInfo(filename: url.lastPathComponent, name: url.deletingPathExtension().lastPathComponent, createdAt: rv?.creationDate ?? Date(), size: rv?.fileSize ?? 0))
            }
        }
        return out
    }

    // Load snapshot (replace current state)
    func loadSnapshot(filename: String) -> Bool {
        let url = SaveFiles.urlFor(filename: filename)
        do {
            let data = try Data(contentsOf: url)
            let snapshot = try JSONDecoder().decode(Snapshot.self, from: data)
            DispatchQueue.main.async {
                self.expenses = snapshot.expenses
                self.paychecks = snapshot.paychecks
                self.recurringExpenses = snapshot.recurringExpenses
                self.saveData()
            }
            return true
        } catch {
            print("loadSnapshot error:", error)
            return false
        }
    }

    func deleteSnapshot(filename: String) -> Bool {
        let url = SaveFiles.urlFor(filename: filename)
        do {
            try FileManager.default.removeItem(at: url)
            return true
        } catch {
            print("deleteSnapshot error:", error)
            return false
        }
    }

    func urlForSnapshot(filename: String) -> URL {
        SaveFiles.urlFor(filename: filename)
    }
}


// MARK: - Multiple saves
// Small metadata struct used by the UI list
struct SnapshotFileInfo: Identifiable {
    var id: String { filename }
    let filename: String
    let name: String
    let createdAt: Date
    let size: Int
}

// Simple file helper (private)
fileprivate enum SaveFiles {
    static let savesFolderName = "saves"

    static var savesDirectoryURL: URL {
        let fm = FileManager.default
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dir = docs.appendingPathComponent(savesFolderName, isDirectory: true)
        if !fm.fileExists(atPath: dir.path) {
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    static func filename(for name: String) -> String {
        let safe = name.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: "\\", with: "-")
            .replacingOccurrences(of: " ", with: "_")
        let iso = ISO8601DateFormatter().string(from: Date())
        return "\(safe)__\(iso).json"
    }

    static func urlFor(filename: String) -> URL {
        return savesDirectoryURL.appendingPathComponent(filename)
    }

    static func listSaveFiles() -> [URL] {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(at: savesDirectoryURL, includingPropertiesForKeys: [.creationDateKey, .fileSizeKey], options: [.skipsHiddenFiles]) else { return [] }
        return files.filter { $0.pathExtension.lowercased() == "json" }
            .sorted {
                (try? $0.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date()
                >
                (try? $1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date()
            }
    }
}



// MARK: - ContentView

struct ContentView: View {
    @EnvironmentObject var financeData: FinanceData
    @State private var selectedDate = Date()
    @State private var showingAddExpense = false
    @State private var showingAddPaycheck = false
    @State private var showingRecPay = false
    @State private var showingExport = false

    var body: some View {
        NavigationView {
            ZStack {
                Color("Background_main")
                    .ignoresSafeArea()

                VStack {
                    // your custom calendar (assumes CalendarView exists)
                    CalendarView(selectedDate: $selectedDate)

                    Text("Balance: $\(financeData.balance(on: selectedDate), specifier: "%.2f")")
                        .font(.title)
                        .padding()

                    HStack {
                        Button("Add Expense") { showingAddExpense = true }
                            .buttonStyle(.borderedProminent)

                        Button("Add Paycheck") { showingAddPaycheck = true }
                            .buttonStyle(.borderedProminent)

                        Button("Rec Expense") { showingRecPay = true }
                            .buttonStyle(.borderedProminent)
                        Button("Export") { showingExport = true }
                    }
                    .padding()

                    List {
                        Section("Expenses") {
                            ForEach(financeData.expenses) { expense in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(expense.title)
                                            .font(.headline)
                                        Text(expense.date, style: .date)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Text("$\(expense.amount, specifier: "%.2f")")
                                        .bold()
                                }
                            }
                            .onDelete(perform: financeData.removeExpense)
                        }

                        Section("Paychecks") {
                            ForEach(financeData.paychecks) { paycheck in
                                HStack {
                                    Text("Pay: $\(paycheck.amount, specifier: "%.2f")")
                                    Spacer()
                                    Text(paycheck.date, style: .date)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .onDelete(perform: financeData.removePaycheck) // added delete
                        }
                    }
                }
                // Present sheets; AddExpenseView/AddPaycheckView/AddRecurringExpenseView must accept selectedDate binding
                .sheet(isPresented: $showingAddExpense) {
                    AddExpenseView(selectedDate: $selectedDate)
                }
                .sheet(isPresented: $showingAddPaycheck) {
                    AddPaycheckView(selectedDate: $selectedDate)
                }
                .sheet(isPresented: $showingRecPay) {
                    AddRecurringExpenseView(startDate: $selectedDate)
                }
                .sheet(isPresented: $showingExport) {
                    SaveManagerView()
                }
            }
            .navigationTitle("$TACK")
        }
    }
}

// MARK: - App Entry

@main
struct Money_TrackerApp: App {
    @StateObject private var financeData = FinanceData()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(financeData)
                .accentColor(Color("Color"))
        }
    }
}
