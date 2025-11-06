import SwiftUI
import Combine

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

    enum RecurrenceType: Codable {
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



class FinanceData: ObservableObject {
    @Published var expenses: [Expense] = []
    @Published var paychecks: [Paycheck] = []
    @Published var recurringExpenses: [RecurringExpense] = []

    
    @Published var paycheckStartDate: Date? = Calendar.current.date(from: DateComponents(year: 2025, month: 11, day: 14))
    let paycheckInterval: TimeInterval = 14 * 24 * 60 * 60 // two weeks in seconds
    
    
    private let expensesKey = "expenses"
    private let paychecksKey = "paychecks"
    
    
    
    
    
    
    init()
    {
        loadData()
        
    }
    
    // MARK: - Public methods
    func addExpense(_ expense: Expense)
    {
        expenses.append(expense)
        saveData()
    }
    
    func addPaycheck(_ paycheck: Paycheck)
    {
        paychecks.append(paycheck)
        saveData()
    }

    // MARK: - Persistance

    private func saveData()
    {
        let encoder = JSONEncoder()
        if let expensesData = try? encoder.encode(expenses)
        {
            UserDefaults.standard.set(expensesData, forKey: expensesKey)
            
        }
        if let paychecksData = try? encoder.encode(paychecks)
        {
            UserDefaults.standard.set(paychecksData, forKey: paychecksKey)
        }
    }
    
    private func loadData()
    {
        let decoder = JSONDecoder()
        if let expenseData = UserDefaults.standard.data(forKey: expensesKey),
            let decodedExpenses = try? decoder.decode([Expense].self, from: expenseData)
        {
            self.expenses = decodedExpenses
        }

        if let paychecksData = UserDefaults.standard.data(forKey: paychecksKey), let decodedPaychecks = try? decoder.decode([Paycheck].self, from: paychecksData)
        {
            self.paychecks = decodedPaychecks
        }
    }

        // Helper to calculate balance for a date
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
    func autoPaychecks(upTo date: Date) -> [Paycheck]
    {
        guard let start = paycheckStartDate else { return [] }
        var autoList: [Paycheck] = []
        
        var nextDate = start
        while nextDate <= date
        {
            // only add if this date isnt already in paycheckjs
            if !paychecks.contains(where: { Calendar.current.isDate($0.date, inSameDayAs: nextDate)})
            {
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
                if !expenses.contains(where: { Calendar.current.isDate($0.date, inSameDayAs: nextDate) && $0.title == recurring.title }) {
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
    
    // Optional: remove recurring items
    func removeRecurringExpense(at offsets: IndexSet) {
        recurringExpenses.remove(atOffsets: offsets)
        saveData()
    }
    
//    func removeRecurringPaycheck() {
//        recurringPaycheck = nil
//        saveData()
//    }
    
    
}










struct ContentView: View {
    @EnvironmentObject var financeData: FinanceData
    @State private var selectedDate = Date()
    @State private var showingAddExpense = false
    @State private var showingAddPaycheck = false
    @State private var showingRecPay = false
    
    var body: some View {
        NavigationView {
            ZStack{
                
                Color("Background_main")
                    .ignoresSafeArea()
                
                VStack {
//                    DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
//                        .datePickerStyle(.graphical)
//                        .padding()
////                        .tint(Color("Text"))
                    CalendarView(selectedDate: $selectedDate)
                    
                    Text("Balance: $\(financeData.balance(on: selectedDate), specifier: "%.2f")")
                        .font(.title)
                        .padding()
                    
                    HStack {
                        Button("Add Expense") { showingAddExpense = true }
                            .buttonStyle(.borderedProminent)
                        
                        Button("Add Paycheck") { showingAddPaycheck = true }
                            .buttonStyle(.borderedProminent)
                        Button("Rec Expense") { showingRecPay = true}
                            .buttonStyle(.borderedProminent)
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
                                Text("Pay: $\(paycheck.amount, specifier: "%.2f")")
                            }
                        }
                    }
                }
                .navigationTitle("Money Tracker")
                .sheet(isPresented: $showingAddExpense) {
                    AddExpenseView()
                }
                .sheet(isPresented: $showingAddPaycheck) {
                    AddPaycheckView()
                }
                .sheet(isPresented: $showingRecPay)
                {
                    AddRecurringExpenseView()
                }
            }
        }
            
    }
}




@main
struct Money_TrackerApp: App {
    @StateObject private var financeData = FinanceData()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(financeData)
                .accentColor(Color("Color"))
//                .background(Color("Background"))
        }
    }
}
