import SwiftUI

// Модель данных для элемента расходов, которая поддерживает протоколы Identifiable и Codable.
struct ExpenseItem: Identifiable, Codable {
    var id = UUID() // Уникальный идентификатор для каждого элемента.
    let name: String // Название расхода.
    let type: String // Тип расхода (например, "Личные" или "Деловые").
    let amount: Double // Сумма расхода.
    let currency: String
}

// Класс для управления списком расходов с использованием свойства @Observable.
@Observable
class Expenses {
    // Массив элементов расходов, который наблюдается за изменениями.
    var items = [ExpenseItem]() {
        didSet {
            // Сохранение изменений в UserDefaults, если массив изменился.
            if let encoded = try? JSONEncoder().encode(items) {
                UserDefaults.standard.set(encoded, forKey: "Items")
            }
        }
    }
    
    // Инициализатор, который загружает данные из UserDefaults, если они доступны.
    init() {
        if let savedItems = UserDefaults.standard.data(forKey: "Items") {
            // Декодирование сохраненных данных и их присвоение массиву items.
            if let decodedItems = try? JSONDecoder().decode([ExpenseItem].self, from: savedItems) {
                items = decodedItems
                return
            }
        }

        // Если данных нет, создается пустой массив.
        items = []
    }
}

// Основное представление приложения.
struct ContentView: View {
    @State private var expenses = Expenses() // Экземпляр класса Expenses для управления состоянием.
    @State private var showingAddExpense = false // Флаг для управления отображением листа добавления нового расхода.
    
    var body: some View {
        NavigationStack {
            // Список всех элементов расходов.
            List {
                ForEach(expenses.items) { item in
                    // Вычисляемый цвет текста для всего блока
                    let textColor = getTextColor(for: item)
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text(item.name) // Отображение названия каждого расхода.
                                .font(.headline)
                            Text(item.type)
                        }
                        Spacer()
                        
                        // Преобразование суммы в USD и использование для установки цвета текста
                        Text("\(item.amount, format: .currency(code: item.currency))")
                    }
                    .foregroundColor(textColor) // Применяем цвет текста ко всему HStack
                     // Добавляем отступ для лучшего визуального восприятия
                }
                .onDelete(perform: removeItems) // Добавление возможности удаления элемента из списка.
            }
            .navigationTitle("iExpense") // Заголовок экрана.
            .toolbar {
                // Кнопка для добавления нового расхода.
                Button("Add Expense", systemImage: "plus") {
                    showingAddExpense = true // Показать лист для добавления нового расхода.
                }
            }
        }
        .sheet(isPresented: $showingAddExpense) {
            // Лист для добавления нового расхода.
            AddView(expenses: expenses)
        }
    }
    
    // Функция для удаления элемента из списка.
    func removeItems(at offsets: IndexSet) {
        expenses.items.remove(atOffsets: offsets)
    }
    
    // Функция для получения цвета текста в зависимости от суммы в USD.
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
