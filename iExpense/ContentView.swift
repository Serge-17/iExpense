import SwiftUI
import SwiftData

struct ExpenseItem: Identifiable, Codable {
    var id = UUID()
    let name: String
    let type: String // "Личные" или "Деловые"
    let amount: Double
    let currency: String
}

@Observable
class Expenses {
    var items = [ExpenseItem]() {
        didSet {
            if let encoded = try? JSONEncoder().encode(items) {
                UserDefaults.standard.set(encoded, forKey: "Items")
            }
        }
    }

    init() {
        if let savedItems = UserDefaults.standard.data(forKey: "Items") {
            if let decodedItems = try? JSONDecoder().decode([ExpenseItem].self, from: savedItems) {
                items = decodedItems
                return
            }
        }
        items = []
    }
}

struct ContentView: View {
    @State private var expenses = Expenses()
    @State private var showingAddExpense = false
    @State private var title = "iExpense"
    
    @State private var selectedSortKeyString: KeyPath<ExpenseItem, String> = \ExpenseItem.name // Ключ сортировки по имени
    @State private var selectedSortKeyDouble: KeyPath<ExpenseItem, Double> = \ExpenseItem.amount // Ключ сортировки по сумме
    @State private var isSortingByName = true // Флаг для определения типа сортировки
    @State private var filterType: String = "Все" // Тип фильтрации

    var filteredAndSortedItems: [ExpenseItem] {
        let filteredItems = expenses.items.filter { item in
            filterType == "Все" || item.type == filterType
        }
        
        return filteredItems.sorted {
            if isSortingByName {
                return $0[keyPath: selectedSortKeyString] < $1[keyPath: selectedSortKeyString]
            } else {
                return $0[keyPath: selectedSortKeyDouble] < $1[keyPath: selectedSortKeyDouble]
            }
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredAndSortedItems) { item in
                    let textColor = getTextColor(for: item)

                    HStack {
                        VStack(alignment: .leading) {
                            Text(item.name)
                                .font(.headline)
                            Text(item.type)
                        }
                        Spacer()
                        Text("\(item.amount, format: .currency(code: item.currency))")
                    }
                    .foregroundColor(textColor)
                }
                .onDelete(perform: removeItems)
            }
            .navigationTitle($title)
            .navigationBarTitleDisplayMode(.inline)

            .toolbar {
                Menu("Sort") {
                    Button("Name") {
                        isSortingByName = true
                    }
                    Button("Amount") {
                        isSortingByName = false
                    }
                }

                Menu("Filter") {
                    Button("All") { filterType = "All" }
                    Button("Personal") { filterType = "Personal" }
                    Button("Business") { filterType = "Business" }
                }

                Button("Добавить Расход", systemImage: "plus") {
                    showingAddExpense = true
                }
            }

            NavigationLink(
                destination: AddView(expenses: expenses),
                isActive: $showingAddExpense
            ) {
                EmptyView()
            }
        }
    }

    func removeItems(at offsets: IndexSet) {
        expenses.items.remove(atOffsets: offsets)
    }

    private func getTextColor(for item: ExpenseItem) -> Color {
        let summUSD = trueUSD(exchange: item.currency, value: item.amount)
        return summUSD > 100 ? .red : (summUSD <= 10 ? .blue : .green)
    }
}

// Превью ContentView для быстрого просмотра в редакторе Xcode.
#Preview {
    ContentView()
}

func trueUSD(exchange: String, value: Double) -> Int {
    switch exchange {
    case "USD":
        return Int(value)
    case "CNY":
        return Int(value / 7.12)
    case "RUB":
        return Int(value / 90)
    case "EUR":
        return Int(value * 0.9)
    default:
        return 0
    }
}
