import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'shopping_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simplisty',
      theme: ThemeData(primarySwatch: Colors.blue, brightness: Brightness.dark),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  double weeklyExpense = 0.0;
  double monthlyExpense = 0.0;
  double yearlyExpense = 0.0;
  double totalExpense = 0.0;

  @override
  void initState() {
    super.initState();
    _calculateExpenses();
  }

  Future<void> _calculateExpenses() async {
    final shoppingLists = await _dbHelper.getShoppingLists(); // Tüm listeleri al
    double weekly = 0.0;
    double monthly = 0.0;
    double yearly = 0.0;
    double total = 0.0;

    final now = DateTime.now();

    for (var list in shoppingLists) {
      final listId = list['id'];
      final items = await _dbHelper.getShoppingItems(listId); // Her listenin ürünlerini al

      for (var item in items) {
        double price = item['price'];
        DateTime createdAt = DateTime.parse(item['created_at']); // Tarih bilgisi

        total += price;

        if (createdAt.isAfter(now.subtract(Duration(days: 7)))) {
          weekly += price;
        }
        if (createdAt.isAfter(now.subtract(Duration(days: 30)))) {
          monthly += price;
        }
        if (createdAt.isAfter(now.subtract(Duration(days: 365)))) {
          yearly += price;
        }
      }
    }

    setState(() {
      weeklyExpense = weekly;
      monthlyExpense = monthly;
      yearlyExpense = yearly;
      totalExpense = total;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(80),
        child: AppBar(
          title: Image.asset(
            'assets/images/logo.webp',
            height: 150,
          ),
          centerTitle: true,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: PageView(
                children: [
                  _buildExpenseCard('Bu Hafta', weeklyExpense, Colors.green),
                  _buildExpenseCard('Bu Ay', monthlyExpense, Colors.orange),
                  _buildExpenseCard('Bu Yıl', yearlyExpense, Colors.blue),
                  _buildExpenseCard('Toplam', totalExpense, Colors.purple),
                ],
              ),
            ),
            SizedBox(height: 20),
            _buildActionButton(
              'Alışveriş Listesi',
              Icons.shopping_cart,
                  () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ShoppingList()),
                );
                // Listeye gidip geri dönüldüğünde harcamaları yeniden hesapla
                _calculateExpenses();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseCard(String title, double amount, Color color) {
    return Card(
      color: Colors.grey[850],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
            ),
            SizedBox(height: 10),
            Text(
              '${amount.toStringAsFixed(2)} TL',
              style: TextStyle(fontSize: 28, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, VoidCallback onPressed) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: Icon(icon, size: 24),
      label: Text(
        title,
        style: TextStyle(fontSize: 18),
      ),
      onPressed: onPressed,
    );
  }
}
