import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

void main() {
  runApp(const ExpenseTrackerApp());
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF2E7D5B),
        scaffoldBackgroundColor: const Color(0xFFF3F5F4),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Color(0xFFF3F5F4),
          foregroundColor: Colors.black87,
        ),
        cardTheme: const CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

/// ------------------- MODEL -------------------
enum ExpenseCategory {
  petrol,
  daily,
  food,
  grocery,
  transport,
  bills,
  rent,
  mobile,
  health,
  entertainment,
  shopping,
  education,
  other,
}

extension ExpenseCategoryExt on ExpenseCategory {
  String get label {
    switch (this) {
      case ExpenseCategory.petrol:
        return 'Petrol';
      case ExpenseCategory.daily:
        return 'Roz ka Kharcha';
      case ExpenseCategory.food:
        return 'Food & Dining';
      case ExpenseCategory.grocery:
        return 'Grocery';
      case ExpenseCategory.transport:
        return 'Transport';
      case ExpenseCategory.bills:
        return 'Bills & Utilities';
      case ExpenseCategory.rent:
        return 'Rent';
      case ExpenseCategory.mobile:
        return 'Mobile & Internet';
      case ExpenseCategory.health:
        return 'Health & Medical';
      case ExpenseCategory.entertainment:
        return 'Entertainment';
      case ExpenseCategory.shopping:
        return 'Shopping';
      case ExpenseCategory.education:
        return 'Education';
      case ExpenseCategory.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case ExpenseCategory.petrol:
        return Icons.local_gas_station_rounded;
      case ExpenseCategory.daily:
        return Icons.wallet_rounded;
      case ExpenseCategory.food:
        return Icons.restaurant_rounded;
      case ExpenseCategory.grocery:
        return Icons.local_grocery_store_rounded;
      case ExpenseCategory.transport:
        return Icons.directions_bus_rounded;
      case ExpenseCategory.bills:
        return Icons.receipt_long_rounded;
      case ExpenseCategory.rent:
        return Icons.home_rounded;
      case ExpenseCategory.mobile:
        return Icons.wifi_rounded;
      case ExpenseCategory.health:
        return Icons.local_hospital_rounded;
      case ExpenseCategory.entertainment:
        return Icons.movie_rounded;
      case ExpenseCategory.shopping:
        return Icons.shopping_bag_rounded;
      case ExpenseCategory.education:
        return Icons.school_rounded;
      case ExpenseCategory.other:
        return Icons.category_rounded;
    }
  }

  Color get color {
    switch (this) {
      case ExpenseCategory.petrol:
        return const Color(0xFFE07A3F);
      case ExpenseCategory.daily:
        return const Color(0xFF2E7D5B);
      case ExpenseCategory.food:
        return const Color(0xFFD6484F);
      case ExpenseCategory.grocery:
        return const Color(0xFF3F9D5C);
      case ExpenseCategory.transport:
        return const Color(0xFF3B82C4);
      case ExpenseCategory.bills:
        return const Color(0xFFC98A26);
      case ExpenseCategory.rent:
        return const Color(0xFF7A5AF8);
      case ExpenseCategory.mobile:
        return const Color(0xFF00A6A6);
      case ExpenseCategory.health:
        return const Color(0xFFE0507A);
      case ExpenseCategory.entertainment:
        return const Color(0xFF9C5FE0);
      case ExpenseCategory.shopping:
        return const Color(0xFFE0507A);
      case ExpenseCategory.education:
        return const Color(0xFF4A6FE0);
      case ExpenseCategory.other:
        return const Color(0xFF5B6EE1);
    }
  }
}

class Expense {
  final String id;
  final ExpenseCategory category;
  final double amount;
  final String note;
  final DateTime date;

  Expense({
    required this.id,
    required this.category,
    required this.amount,
    required this.note,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category.index,
        'amount': amount,
        'note': note,
        'date': date.toIso8601String(),
      };

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        id: json['id'],
        category: ExpenseCategory.values[json['category']],
        amount: (json['amount'] as num).toDouble(),
        note: json['note'] ?? '',
        date: DateTime.parse(json['date']),
      );
}

/// ------------------- STORAGE -------------------
class ExpenseStorage {
  static const _key = 'expenses_list';

  static Future<List<Expense>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    final List decoded = jsonDecode(raw);
    return decoded.map((e) => Expense.fromJson(e)).toList();
  }

  static Future<void> save(List<Expense> expenses) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(expenses.map((e) => e.toJson()).toList());
    await prefs.setString(_key, raw);
  }
}

/// ------------------- HOME SCREEN -------------------
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Expense> _expenses = [];
  bool _loading = true;
  bool _showAllCategories = false;
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  final _currency = NumberFormat.currency(locale: 'en_PK', symbol: 'Rs ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    final data = await ExpenseStorage.load();
    data.sort((a, b) => b.date.compareTo(a.date));
    setState(() {
      _expenses = data;
      _loading = false;
    });
  }

  List<Expense> get _monthExpenses => _expenses.where((e) {
        return e.date.year == _selectedMonth.year &&
            e.date.month == _selectedMonth.month;
      }).toList();

  double get _monthTotal =>
      _monthExpenses.fold(0.0, (sum, e) => sum + e.amount);

  double _categoryTotal(ExpenseCategory cat) => _monthExpenses
      .where((e) => e.category == cat)
      .fold(0.0, (sum, e) => sum + e.amount);

  /// Categories that actually have spending this month, sorted highest first.
  List<MapEntry<ExpenseCategory, double>> get _activeCategoryTotals {
    final list = ExpenseCategory.values
        .map((c) => MapEntry(c, _categoryTotal(c)))
        .where((e) => e.value > 0)
        .toList();
    list.sort((a, b) => b.value.compareTo(a.value));
    return list;
  }

  Future<void> _addExpense() async {
    final result = await showModalBottomSheet<Expense>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddExpenseSheet(),
    );

    if (result != null) {
      setState(() => _expenses.insert(0, result));
      await ExpenseStorage.save(_expenses);
    }
  }

  Future<void> _deleteExpense(Expense e) async {
    setState(() => _expenses.removeWhere((x) => x.id == e.id));
    await ExpenseStorage.save(_expenses);
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth =
          DateTime(_selectedMonth.year, _selectedMonth.month + delta);
    });
  }

  /// Groups this month's expenses by day (e.g. "Today", "Yesterday", "12 Aug 2026")
  Map<String, List<Expense>> get _groupedByDay {
    final Map<String, List<Expense>> grouped = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (final e in _monthExpenses) {
      final day = DateTime(e.date.year, e.date.month, e.date.day);
      String label;
      if (day == today) {
        label = 'Aaj';
      } else if (day == yesterday) {
        label = 'Kal';
      } else {
        label = DateFormat('dd MMM yyyy').format(day);
      }
      grouped.putIfAbsent(label, () => []).add(e);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final monthLabel = DateFormat('MMMM yyyy').format(_selectedMonth);

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final activeCats = _activeCategoryTotals;
    final visibleCats = _showAllCategories ? activeCats : activeCats.take(4).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mera Kharcha', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addExpense,
        icon: const Icon(Icons.add),
        label: const Text('Kharcha Likhein'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadExpenses,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          children: [
            // Month selector
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => _changeMonth(-1),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text(
                    monthLabel,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  IconButton(
                    onPressed: () => _changeMonth(1),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Total card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2E7D5B), Color(0xFF184F37)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2E7D5B).withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.account_balance_wallet_rounded,
                          color: Colors.white70, size: 18),
                      const SizedBox(width: 6),
                      const Text('Total Monthly Kharcha',
                          style: TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currency.format(_monthTotal),
                    style: const TextStyle(
                        color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_monthExpenses.length} entries is mahine',
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Pie chart + category breakdown
            if (activeCats.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: 150,
                      child: Row(
                        children: [
                          Expanded(
                            flex: 4,
                            child: PieChart(
                              PieChartData(
                                sectionsSpace: 2,
                                centerSpaceRadius: 32,
                                sections: activeCats.map((entry) {
                                  final pct = (_monthTotal == 0)
                                      ? 0
                                      : (entry.value / _monthTotal * 100);
                                  return PieChartSectionData(
                                    color: entry.key.color,
                                    value: entry.value,
                                    title: pct >= 8 ? '${pct.toStringAsFixed(0)}%' : '',
                                    radius: 42,
                                    titleStyle: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 5,
                            child: ListView(
                              padding: EdgeInsets.zero,
                              children: activeCats.take(6).map((entry) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 3),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: entry.key.color,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          entry.key.label,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 11.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
            ],

            // Category breakdown grid
            if (activeCats.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Category-wise Kharcha',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800])),
                  if (activeCats.length > 4)
                    TextButton(
                      onPressed: () =>
                          setState(() => _showAllCategories = !_showAllCategories),
                      child: Text(_showAllCategories ? 'Kam dikhayen' : 'Sab dikhayen'),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: visibleCats.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2.6,
                ),
                itemBuilder: (context, i) {
                  final cat = visibleCats[i].key;
                  final total = visibleCats[i].value;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: cat.color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(cat.icon, color: cat.color, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(cat.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11.5, color: Colors.black54)),
                              Text(
                                _currency.format(total),
                                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],

            Text('Is Mahine ki Entries',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey[800])),
            const SizedBox(height: 10),

            if (_monthExpenses.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.receipt_long_rounded, size: 48, color: Colors.grey[300]),
                      const SizedBox(height: 10),
                      Text('Koi expense nahi mila.\n"Kharcha Likhein" button dabayen.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[500])),
                    ],
                  ),
                ),
              )
            else
              ..._groupedByDay.entries.map((group) {
                final dayTotal = group.value.fold(0.0, (s, e) => s + e.amount);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(group.key,
                                style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[500])),
                            Text(_currency.format(dayTotal),
                                style: TextStyle(fontSize: 12.5, color: Colors.grey[500])),
                          ],
                        ),
                      ),
                      ...group.value.map((e) => _ExpenseTile(
                            expense: e,
                            currency: _currency,
                            onDelete: () => _deleteExpense(e),
                          )),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  final Expense expense;
  final NumberFormat currency;
  final VoidCallback onDelete;

  const _ExpenseTile({
    required this.expense,
    required this.currency,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(expense.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.red[400],
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: expense.category.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(expense.category.icon, color: expense.category.color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(expense.category.label,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  if (expense.note.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(expense.note,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ),
                ],
              ),
            ),
            Text(
              currency.format(expense.amount),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
            ),
          ],
        ),
      ),
    );
  }
}

/// ------------------- ADD EXPENSE SHEET -------------------
class AddExpenseSheet extends StatefulWidget {
  const AddExpenseSheet({super.key});

  @override
  State<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<AddExpenseSheet> {
  ExpenseCategory _category = ExpenseCategory.daily;
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _submit() {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sahi amount daryen')),
      );
      return;
    }
    final expense = Expense(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      category: _category,
      amount: amount,
      note: _noteController.text.trim(),
      date: _date,
    );
    Navigator.pop(context, expense);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: ListView(
              controller: scrollController,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Naya Kharcha Likhein',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                const Text('Category chunein',
                    style: TextStyle(fontSize: 13, color: Colors.black54)),
                const SizedBox(height: 10),

                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: ExpenseCategory.values.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.85,
                  ),
                  itemBuilder: (context, i) {
                    final cat = ExpenseCategory.values[i];
                    final selected = _category == cat;
                    return InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => setState(() => _category = cat),
                      child: Container(
                        decoration: BoxDecoration(
                          color: selected ? cat.color.withOpacity(0.15) : Colors.grey[100],
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selected ? cat.color : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(cat.icon, color: cat.color, size: 22),
                            const SizedBox(height: 6),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Text(
                                cat.label,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 18),

                TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Amount (Rs)',
                    prefixIcon: const Icon(Icons.currency_rupee),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: _noteController,
                  decoration: InputDecoration(
                    labelText: 'Note (optional)',
                    prefixIcon: const Icon(Icons.edit_note),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                InkWell(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 18),
                        const SizedBox(width: 10),
                        Text(DateFormat('dd MMM yyyy').format(_date)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Save Kharcha', style: TextStyle(fontSize: 15)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
