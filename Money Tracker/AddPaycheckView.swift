import SwiftUI

struct AddPaycheckView: View {
    @EnvironmentObject var financeData: FinanceData
    @Environment(\.dismiss) var dismiss
    
    @State private var amount = ""
    // @State private var date = Date()
    @Binding var selectedDate: Date
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Amount", text: $amount)
                    .keyboardType(.decimalPad)
                DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
            }
            .navigationTitle("Add Paycheck")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let amt = Double(amount) {
                            let paycheck = Paycheck(amount: amt, date: selectedDate)
                            financeData.addPaycheck(paycheck)
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
}
