import SwiftUI

struct CalendarView: View
{
    @Binding var selectedDate: Date
    @State private var displayDate = Date()
    @EnvironmentObject var financeData: FinanceData

    var threshold: Double = 1000.0
    
    var daysInMonth: [Int]
    {
        let range = calendar.range(of: .day, in: .month, for: displayDate)!
        return Array(range)
    }
    
    
    let calendar = Calendar.current
    
    

    
    var body: some View
    {
        VStack
        {
            
            
            HStack
            {
                // change month view
                Button(action: { changeMonth(by: -1) } )
                {
                    Image(systemName: "chevron.left")
                        .padding()
                }
                Spacer()
                Text(monthYearString(from:displayDate))
                    .font(.headline)
                
                Spacer()
                Button(action: {changeMonth(by: 1)})
                {
                    Image(systemName: "chevron.right")
                        .padding()
                }
            }
            Text("Current Month")
                .font(.headline)
                .padding()
            
            HStack
            {
                //show weekday symbols
                let weekdaySymbols = calendar.shortStandaloneWeekdaySymbols

                ForEach(weekdaySymbols, id: \.self)
                {
                    day in
                    Text(day)
                        .frame(maxWidth: .infinity)
                    
                }
                
            }
            // 7 column grid for weekdays
            let columns = Array(repeating: GridItem(.flexible()), count: 7)
            LazyVGrid(columns: columns)
            {
                ForEach(daysForGrid.indices, id: \.self)
                {
                    index in
                    if let day = daysForGrid[index] {
                        let dayDate = calendar.date(bySetting: .day, value: day, of: displayDate)!
                        let projected = projectedBalanceUntilNextPaycheck(from: dayDate)
                        let bgColor = colorForProjectedBalance(projected)

                        Button(action: {
                            selectedDate = dayDate
                        }) {
                            Text("\(day)")
                                .frame(width: 40, height: 40)
                                .background(
                                    // combine selection highlight + projection color
                                    ZStack {
                                        // colored pill showing projected health
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(bgColor)
                                            .opacity( selectedDate.isSameDay(as: dayDate) ? 1.0 : 0.25 )
                                        // selection stronger overlay
                                        if Calendar.current.isDate(selectedDate, inSameDayAs: dayDate) {
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.primary, lineWidth: 2)
                                        }
                                    }
                                )
                                .cornerRadius(8)
                                .foregroundColor(.primary)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    else
                    {
                        Text("")
                            .frame(width: 40, height: 40)
                    }
                    
                }
            }
            
        }
        .padding()
    }
    
    
    // MARK: Helpers
    private func changeMonth(by delta: Int)
    {
        // delta months to displayDate
        if let newDate = calendar.date(byAdding: .month, value: delta, to: displayDate)
        {
            displayDate = newDate
        }
    }
    
    
    private func monthYearString(from date: Date) -> String
    {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: date)
    }
    
    var daysForGrid: [Int?]
    {
        // 1. days in month
        let range = calendar.range(of: .day, in: .month, for: displayDate)!
        let numberOfDays = Array(range)
        
        // 2. weekday of the first day ( 1=sunday )
        let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: displayDate))!
        let weekdayOfFirst = calendar.component(.weekday, from: firstOfMonth)
        
        // 3. compute leading blanks
        var leadingBlanks = weekdayOfFirst - calendar.firstWeekday
        if leadingBlanks < 0 { leadingBlanks += 7 }
        
        // 4. build the array grid
        var days: [Int?] = Array(repeating: nil, count: leadingBlanks)
        days.append(contentsOf: numberOfDays.map {Optional($0) })
        return days


    }
    
    // find the next paycheck *after* a given date (searching both manual and auto paychecks)
    private func nextPaycheck(after date: Date) -> Date? {
        // gather paychecks (manual + auto generated for next year)
        let horizon = Calendar.current.date(byAdding: .year, value: 1, to: date) ?? date
        let manual = financeData.paychecks.map { $0.date }.filter { $0 > date }
        let auto = financeData.autoPaychecks(upTo: horizon).map { $0.date }.filter { $0 > date }

        let all = (manual + auto).sorted()
        return all.first
    }

    // sum of expenses with date >= start && date < end
    private func sumExpenses(between start: Date, and end: Date) -> Double {
        let startDay = Calendar.current.startOfDay(for: start)
        let endDay = Calendar.current.startOfDay(for: end)
        let manualSum = financeData.expenses
            .filter { $0.date >= startDay && $0.date < endDay }
            .reduce(0.0) { $0 + $1.amount }

        // include auto-generated expenses in the same window
        let auto = financeData.autoExpenses(upTo: endDay)
            .filter { $0.date >= startDay && $0.date < endDay }
            .reduce(0.0) { $0 + $1.amount }

        return manualSum + auto
    }

    // project balance from date until next paycheck: balance_at_date - upcoming_expenses
    private func projectedBalanceUntilNextPaycheck(from date: Date) -> Double {
        let dayStart = Calendar.current.startOfDay(for: date)
        // balance at the start of the day (counts paychecks <= date and expenses <= date)
        let balanceAtDate = financeData.balance(on: dayStart)

        if let next = nextPaycheck(after: dayStart) {
            let expenseUntilNext = sumExpenses(between: dayStart, and: next)
            return balanceAtDate - expenseUntilNext
        } else {
            // no paycheck found in next year -> use fallback window (30 days)
            let fallbackEnd = Calendar.current.date(byAdding: .day, value: 30, to: dayStart)!
            let expenseFallback = sumExpenses(between: dayStart, and: fallbackEnd)
            return balanceAtDate - expenseFallback
        }
    }

    // helper to pick color
    private func colorForProjectedBalance(_ amount: Double) -> Color {
        if amount < 0 { return Color.red.opacity(0.9) }
        if amount < threshold { return Color.yellow.opacity(0.9) }
        return Color.green.opacity(0.9)
    }
    

}


fileprivate extension Date {
    func isSameDay(as other: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: other)
    }
}
