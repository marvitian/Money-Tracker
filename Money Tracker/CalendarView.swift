import SwiftUI

struct CalendarView: View
{
    @Binding var selectedDate: Date
    @State private var displayDate = Date()
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
                        Button(action: {
                            if let newDate = calendar.date(bySetting: .day, value: day, of: displayDate)
                            {
                                selectedDate = newDate
                            }
                            
                        })
                        {
                            Text("\(day)")
                                .frame(width: 40, height: 40)
                                .background(
                                    //  background color
                                    calendar.isDate(selectedDate, inSameDayAs:calendar.date(bySetting: .day, value: day, of: displayDate)!)
                                    ? Color.blue.opacity(0.3)
                                    : calendar.isDateInToday(calendar.date(bySetting: .day, value: day, of: displayDate)!)
                                    ? Color("Todays_date")
                                    : Color.clear
                                )
                                .cornerRadius(8)
                                .foregroundColor(
                                    calendar.isDate( selectedDate, inSameDayAs: calendar.date(bySetting: .day, value: day, of: displayDate)! )
                                    ? .white
                                    : .primary
                                )
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
    
    
}
