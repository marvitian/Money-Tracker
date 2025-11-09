# $tack

I've always wanted a money tracking app that allows me to look at how my budget is tracking day to day, but 
nothing ever was quite what I was looking for, so I built it. 


## Roadmap 

### Feature Alpha - 2025 Nov 6
Implement daily color codes to know if you're on track for your next bills/payments.

 Blue (wip) means you have enough money to splurge. You will have enough money to put away your savings (which you can define), and then some. 

Green means you don't have to worry about money, you can pay all your bills, though you should really should prioritizing putting your money away, life happens, and here you don't have to starve yourself all day at work when you forgot your lunch. 


yellow means you are within a threshold (that you define). if you stop spending money now you will not have to worry about missing payments.

Red means you will not have enough money to make the next payment before you get paid next. 


### Feature Bravo - 2025 Nov 8
Implement save load data. Manage Multiple saves. 

Future update Bravo 2 (vb.2) will include functionality to duplicate save files



#  Future Optimizations for $tack

These are suggested optimizations and best practices to improve performance, reliability, and user experience as the app grows.

---

##  Data & Performance

- **Cache auto-generated paychecks and expenses**
  - Instead of regenerating recurring items on each calendar redraw, compute them once for a given horizon (e.g. one year ahead) and reuse.
  - Improves performance when scrolling or redrawing the calendar.

- **Pre-compute balances**
  - Store cumulative balances by date to avoid recalculating totals repeatedly when displaying many days.
  - Use a lightweight struct like `DailySummary { Date, balance }` to enable fast lookups.

- **Batch save operations**
  - Instead of calling `saveData()` after every single addition/removal, batch save operations to reduce disk writes.

- **Lazy date calculations**
  - When possible, only compute projected balances for days currently visible on screen, not for the entire month/year.

---

##  UI & UX Enhancements

- **Calendar performance**
  - Avoid heavy logic inside `ForEach` loops; move expensive computations (like filtering or date math) outside when possible.
  
- **Theming**
  - Centralize all colors, fonts, and spacing in a single `Theme.swift` file.  
  - This makes the app consistent and easy to style later.

- **Accessibility**
  - Add VoiceOver labels and dynamic text support for visually impaired users.

- **Animations**
  - Use subtle `withAnimation {}` transitions when switching months or adding expenses to improve user flow.

---

##  Persistence & Syncing

- **CloudKit or iCloud Sync (future)**
  - Let users keep data across devices.  
  - Add a toggle for local-only vs. cloud-synced mode.

- **Data Encryption**
  - Encrypt sensitive data at rest using `CryptoKit` for user privacy.

- **Backup & Restore**
  - Allow exporting/importing data as JSON for manual backup.

---

##  Testing & Stability

- **Unit tests for recurring logic**
  - Ensure auto-generated paychecks/expenses produce correct dates.

- **Snapshot tests for the calendar**
  - Validate the calendar view layout across devices and themes.

- **Error handling**
  - Wrap all file I/O with `do-catch` to show user-friendly alerts if saving/loading fails.

---

##  Scalability

- **Modularize the codebase**
  - Separate logic into modules:
    - `FinanceModel.swift`
    - `Persistence.swift`
    - `CalendarView.swift`
    - `AddExpenseView.swift`
  - Easier to maintain and test.

- **Future integrations**
  - Integrate APIs for exchange rates, tax calculations, or budgeting insights.

---

>  **Goal:** Keep the app fast, intuitive, and trustworthy as the number of entries grows.