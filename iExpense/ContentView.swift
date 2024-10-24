import SwiftUI
import SwiftData

// Структура для хранения информации о расходах
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
    
    @State private var isSortingByName = true // Флаг для определения типа сортировки
    @State private var filterType: String = "All" // Тип фильтрации

    // Используем @Query для фильтрации и сортировки расходов
    var filteredAndSortedItems: [ExpenseItem] {
        let filteredItems = expenses.items.filter { item in
            filterType == "All" || item.type == filterType
        }
        
        return filteredItems.sorted {
            if isSortingByName {
                return $0.name < $1.name // Сортировка по имени
            } else {
                return $0.amount < $1.amount // Сортировка по сумме
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
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)

            .toolbar {
                Menu("Sort") {
                    Button("Name") {
                        isSortingByName = true // Установите флаг на сортировку по имени
                    }
                    Button("Amount") {
                        isSortingByName = false // Установите флаг на сортировку по сумме
                    }
                }

                Menu("Filter") {
                    Button("Personal") { filterType = "Personal" }
                    Button("Business") { filterType = "Business" }
                    Button("All") { filterType = "All" } // Добавлено для сброса фильтрации
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
