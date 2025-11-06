import SwiftUI

struct AddRecurringExpenseView: View {
    @EnvironmentObject var financeData: FinanceData
    @Environment(\.dismiss) var dismiss

    @State private var title = ""
    @State private var amount = ""
    // @State private var startDate = Date()
    @Binding var startDate: Date
    @State private var interval: TimeInterval = 30*24*60*60  // Default monthly
    @State private var recurrenceType: RecurringExpense.RecurrenceType = .monthly

    var body: some View {
        Form {
            TextField("Title", text: $title)
            TextField("Amount", text: $amount)
                .keyboardType(.decimalPad)
            DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
            
            Picker("Recurrence", selection: $recurrenceType) {
                Text("Weekly").tag(RecurringExpense.RecurrenceType.weekly)
                Text("Biweekly").tag(RecurringExpense.RecurrenceType.biweekly)
                Text("Monthly").tag(RecurringExpense.RecurrenceType.monthly)
            }
            .pickerStyle(SegmentedPickerStyle()) // optional for nicer UI
        }
        .navigationTitle("Add Recurring Expense")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    if let amt = Double(amount) {
                        let recurring = RecurringExpense(
                            title: title,
                            amount: amt,
                            startDate: startDate,
                            recurrenceType: recurrenceType
                        )
                        financeData.recurringExpenses.append(recurring)
                        dismiss()
                    }
                }
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
    }
}
