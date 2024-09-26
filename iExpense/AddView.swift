import SwiftUI

// Представление для добавления нового расхода.
struct AddView: View {
    // Состояние для хранения данных, которые пользователь вводит.
    @State private var name = "" // Название расхода.
    @State private var type = "Personal" // Тип расхода, по умолчанию "Personal".
    @State private var amount = 0.0 // Сумма расхода, по умолчанию 0.0.
    @State private var currency = "USD"
    @Environment(\.dismiss) var dismiss
    
    // Массив возможных типов расходов.
    let types = ["Business", "Personal"]
    let currencyType = ["USD", "EUR", "RUB", "CNY"]
    
    // Объект класса Expenses для доступа к списку расходов.
    var expenses: Expenses
    
    var body: some View {
        // Формуляр для ввода данных.
        NavigationStack {
            Form {
                // Поле для ввода названия расхода.
                TextField("Name", text: $name)
                
                // Выбор типа расхода.
                Picker("Type", selection: $type) {
                    ForEach(types, id: \.self) {
                        Text($0) // Отображение каждого типа в списке.
                    }
                }
                
                Picker("Сurrency type", selection: $currency) {
                    ForEach(currencyType, id: \.self){
                        Text($0)
                    }
                }
                
                // Поле для ввода суммы расхода.
                TextField("Amount", value: $amount, format: .currency(code: currency))
                    .keyboardType(.decimalPad) // Установка клавиатуры для ввода чисел.
            }
            .navigationTitle("Add new expense") // Заголовок экрана.
            .toolbar {
                // Кнопка "Сохранить" для добавления нового расхода.
                Button("Save") {
                    // Создание нового элемента расхода и добавление его в список.
                    let item = ExpenseItem(name: name, type: type, amount: amount, currency: currency)
                    expenses.items.append(item)
                    dismiss()
                }
            }}
    }
}

// Превью для быстрого просмотра AddView в редакторе Xcode.
#Preview {
    AddView(expenses: Expenses())
}
