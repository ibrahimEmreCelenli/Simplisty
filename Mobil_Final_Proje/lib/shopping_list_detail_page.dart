import 'package:flutter/material.dart';
import 'database_helper.dart';

class ShoppingListDetailPage extends StatefulWidget {
  final Map<String, dynamic> list;
  final Function(String) onItemAdded;
  final Function onPriceUpdated;

  const ShoppingListDetailPage({
    required this.list,
    required this.onItemAdded,
    required this.onPriceUpdated,
  });

  @override
  _ShoppingListDetailPageState createState() => _ShoppingListDetailPageState();
}

class _ShoppingListDetailPageState extends State<ShoppingListDetailPage> {
  final TextEditingController _itemController = TextEditingController();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _items = [];
  double _totalPrice = 0.0;
  String _currentInput = '';
  List<String> _suggestedItems = [];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    try {
      final items = await _dbHelper.getItemsForList(widget.list['id']);
      setState(() {
        _items = items;
        _calculateTotalPrice(); // Toplam fiyatı hesapla
      });
    } catch (e) {
      _showErrorMessage('Ürünler yüklenirken bir hata oluştu.');
    }
  }

  Future<void> _addItemToDatabase(String name) async {
    if (name
        .trim()
        .isEmpty) {
      _showErrorMessage('Ürün adı boş olamaz.');
      return;
    }
    try {
      await _dbHelper.insertShoppingListItem(
        widget.list['id'],
        name.trim(),
        0,
        0.0,
        false,
      );
      widget.onItemAdded(name);
      await _loadItems();
      _itemController.clear();
      setState(() {
        _currentInput = '';
        _suggestedItems.clear();
      });
    } catch (e) {
      _showErrorMessage('Ürün eklenirken bir hata oluştu.');
    }
  }

  Future<void> _updateItemPrice(int index, double price) async {
    final item = _items[index];
    try {
      await _dbHelper.updateItem(item['id'], item['quantity'], price, 1);
      await _loadItems();
      widget.onPriceUpdated();
    } catch (e) {
      _showErrorMessage('Fiyat güncellenirken bir hata oluştu.');
    }
  }

  void _calculateTotalPrice() {
    setState(() {
      _totalPrice = _items.fold(0.0, (sum, item) {
        if (item['isChecked'] == 1) {
          return sum + (item['price'] as double);
        }
        return sum;
      });
    });
  }

  Future<void> _showPricePerKgCalculator() async {
    final totalPriceController = TextEditingController();
    final weightController = TextEditingController();

    final result = await showDialog<double>(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Fiyat/Kilo Hesapla'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: totalPriceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Toplam Fiyat (TL)',
                  ),
                ),
                TextField(
                  controller: weightController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Kilo (kg)',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(null),
                child: const Text('İptal'),
              ),
              TextButton(
                onPressed: () {
                  final totalPrice = double.tryParse(
                      totalPriceController.text.trim());
                  final weight = double.tryParse(weightController.text.trim());
                  if (totalPrice != null && weight != null && weight > 0) {
                    final pricePerKg = totalPrice / weight;
                    Navigator.of(context).pop(pricePerKg);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Lütfen geçerli değerler girin.')),
                    );
                  }
                },
                child: const Text('Hesapla'),
              ),
            ],
          ),
    );

    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Birim Fiyat: ${result.toStringAsFixed(2)} TL/kg')),
      );
    }
  }


  Future<void> _toggleItemCheckedWithPrice(int index) async {
    final item = _items[index];

    if (item['isChecked'] == 0) {
      final priceController = TextEditingController();
      final price = await _promptForPrice(priceController);
      if (price != null) {
        await _updateItemPrice(index, price);
      }
    } else {
      await _resetItem(index);
      await _loadItems();
    }
  }

  Future<void> _resetItem(int index) async {
    final item = _items[index];
    try {
      await _dbHelper.updateItem(item['id'], item['quantity'], 0.0, 0);
      await _loadItems();
      widget.onPriceUpdated();
    } catch (e) {
      _showErrorMessage('Ürün durumu sıfırlanırken bir hata oluştu.');
    }
  }

  Future<double?> _promptForPrice(TextEditingController priceController) async {
    return showDialog<double>(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Fiyat Gir'),
            content: TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Fiyat'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(null),
                child: const Text('İptal'),
              ),
              TextButton(
                onPressed: () {
                  final price = double.tryParse(priceController.text.trim());
                  Navigator.of(context).pop(price);
                },
                child: const Text('Kaydet'),
              ),
            ],
          ),
    );
  }

  void _onInputChanged(String input) {
    setState(() {
      _currentInput = input;
      _suggestedItems = _getSuggestions(input);
    });
  }

  List<String> _getSuggestions(String query) {
    final databaseItems = [
      'Elma', 'Portakal', 'Muz', 'Üzüm', 'Çilek', 'Brokoli', 'Havuç', 'Patates', 'Sarımsak', 'Soğan', 'Tuz', 'Zeytinyağı', 'Un', 'Süt', 'Yumurta', 'Peynir', 'Yoğurt', 'Kekik', 'Karabiber', 'Şeker', 'Çay', 'Kahve', 'Makarn', 'Kek', 'Çikolata', 'Soda', 'Su', 'Tuzlu Kraker', 'Meyve Suyu', 'Tuzlu Cips', 'Şampuan', 'Diş Macunu', 'Tuzlu Kuruyemiş', 'Kola', 'Sütlü Çikolata', 'Beyaz Peynir', 'Zeytin', 'Beyaz Ekmek', 'Kepekli Ekmek', 'Tavuk', 'Balık', 'Et', 'Köfte', 'Mantar', 'Kavun', 'Karpuz','Patates Kızartması', 'Beyaz Çikolata', 'Mısır Gevreği', 'Soya Sütü', 'Fındık', 'Ceviz', 'Badem', 'Kuşkonmaz', 'Karnabahar', 'Ispanak', 'Kabak', 'Turp', 'Domates', 'Salatalık', 'Roka', 'Marul', 'Lahana', 'Fasulye', 'Nohut', 'Mercimek', 'Bulgur', 'Pirinc', 'Kuskus', 'Dondurma', 'Kek Karışımı', 'Pasta Malzemeleri', 'Zeytin Yağı', 'Limon', 'Portakal Suyu', 'Limonata', 'Fırın Ekmeği', 'Beyaz Peyniri', 'Kaşar Peyniri', 'Mozzarella', 'Tavuk Göğsü', 'Dana Eti', 'Sığır Eti', 'Sosis', 'Balkabağı', 'Cevizli Kek', 'Tarçın', 'Kakao', 'Pudra Şekeri', 'Vanilin', 'Beyaz Sirkesi', 'Bira', 'Şarap', 'Meyve Suyu', 'Makarna Sosu', 'Pizza Hamuru', 'Krem Şanti', 'Bisküvi', 'Sütsüz Çikolata', 'Yulaf', 'Kumru', 'Kuzu Eti', 'Dondurulmuş Pizza', 'Fırın Tavuk', 'Sosisli Sandviç', 'Chia Tohumu', 'Yaban Mersini', 'Fasulye Suyu','Kuzu Kafası', 'Kuzu Pirzola', 'Kuzu Sırt', 'Börülce', 'Kumpir Malzemeleri', 'Meyveli Yoğurt', 'Dondurulmuş Sebze', 'Kumpir Sosu', 'Makarna Salçası', 'Tuzlu Fıstık', 'Yumuşatıcı', 'Beyaz Sabun', 'Yüz Maskesi', 'Saç Maskesi', 'Yüz Temizleyici', 'Bebek Bezi', 'Bebek Maması', 'Bebek Şampuanı', 'Bebek Yağı', 'Bebek Önlüğü', 'Bebek Çorabı', 'Çamaşır Deterjanı', 'Bulaşık Deterjanı', 'Halka Biber', 'Siyah Zeytin', 'Sarı Lahana', 'Taze Kekik', 'Dondurulmuş Makarna', 'Dondurulmuş Börek', 'Tavuk Kanat', 'Tavuk Baget', 'Dondurulmuş Patates', 'Hazır Çorba', 'Domates Sosu', 'Baharat Karışımı', 'Soya Sosu', 'Zencefil', 'Tuzlu Bisküvi', 'Krem Peynir', 'Beyaz Dondurma', 'Çilekli Dondurma', 'Karpuzlu Dondurma', 'Limonlu Dondurma', 'Kakao Tozu', 'Kurutulmuş Kayısı', 'Kurutulmuş Erik', 'Kurutulmuş Yaban Mersini', 'Tuzlu Kuruyemiş Karışımı', 'Fındık Ezmesi', 'Badem Ezmesi', 'Dondurulmuş Tatlı', 'Ev Yapımı Reçel', 'Zeytin Reçeli', 'Gıda Boyası', 'Pirinç Unu', 'Mercimek Unu', 'Kepek Unu', 'Yemeklik Yağ', 'Bal Kabağı', 'Sarı Çay', 'Kapsüllü Kahve', 'Badem Sütü', 'Elma Sirkesi', 'Acılı Sos', 'Köy Ekmeği', 'Beyaz Et Sarması', 'Mısır Tohumu', 'Kavurmalı Ekmek', 'Soğuk Çay', 'Buzlu Çay', 'Rakı', 'Vodka', 'Tekila', 'Beyaz Şarap', 'Kırmızı Şarap', 'Ekmek Arası Köfte', 'Tavuk Şiş', 'Dondurulmuş Yemek', 'Patates Püresi Karışımı', 'Pizza Malzemeleri', 'Tavuk Salatası', 'Kısır','Ananas Suyu', 'Çilek Suyu', 'Nar Suyu', 'Yaban Mersini Suyu', 'Şeftali Suyu', 'Vișne Suyu', 'Karpuz Suyu', 'Kiraz Suyu', 'Mango Suyu', 'Elma Suyu', 'Portakal Nektarı', 'Limonata', 'Greyfurt Suyu', 'Narenciye Karışımı', 'Cennet Hurması Suyu', 'Avokado Suyu','Papaya', 'Avokado', 'Mango', 'Şeftali', 'Nektarin', 'Kivi', 'Tropikal Meyve Karışımı', 'Beyaz Kiraz', 'Alkollü Elma', 'Kakadu Plum', 'Ananas', 'Hurma', 'Kızılcık', 'Limon', 'Yaban Mersini', 'Böğürtlen', 'Armut', 'Ayva', 'Şahter', 'Böğürtlen', 'Sitrus', 'Misket Limonu','Kereviz', 'Bezelye', 'Enginar', 'Pancar', 'Zeytin Dalı', 'Taze Fasulye', 'Roka', 'Taze Mısır', 'Beyaz Lahana', 'Kabak Çekirdeği', 'Ispanak', 'Kuşkonmaz', 'Tatlı Patates', 'Karnabahar', 'Taze Kekik', 'Mısır Tohumu', 'Yaprak Lahana', 'Taze Soğan', 'Beyaz Turp', 'Yeşil Biber', 'Tatlı Biber', 'Rende Havuç', 'Turp', 'Taze Sarımsak', 'Taze Nane', 'Maydanoz','Salatalık Turşusu', 'Lahana Turşusu', 'Biber Turşusu', 'Domates Turşusu', 'Karnıbahar Turşusu', 'Havuç Turşusu', 'Zeytin Turşusu', 'Mantar Turşusu', 'Çeşni Turşusu', 'Patlıcan Turşusu', 'Beyaz Lahana Turşusu', 'Zeytinli Limon Turşusu', 'Yoğurtlu Turşu','Baklava', 'Kadayıf', 'Tavuk Göğsü', 'Sütlaç', 'Künefe', 'Revani', 'Muhallebi', 'Fırın Sütlaç', 'Pasta', 'Meyveli Tatlı', 'Dondurmalı Tatlı', 'Çikolatalı Tatlı', 'Krem Karamel', 'Kumpir Tatlısı', 'Cızlak Tatlısı', 'Çörek', 'Şekerpare', 'Kremalı Kek', 'Meyve Tabağı', 'Fırın Kurabiye', 'Çikolatalı Kurabiye', 'Bisküvili Pasta', 'Elmalı Tatlı', 'Kumpir Dondurması', 'Çikolatalı Bar', 'Bisküvi', 'Patates Cipsi', 'Mısır Cipsi', 'Sosisli Sandviç', 'Hamburger', 'Tavuk Nugget', 'Çikolata Kaplı Fındık', 'Cevizli Bisküvi', 'Çikolata Parçalı Kurabiye', 'Tuzlu Bisküvi', 'Tuzlu Kraker', 'Kola', 'Gazoz', 'Çilekli Jöle', 'Şekerleme', 'Lokum', 'Gofret', 'Patlamış Mısır', 'Cips', 'Süper Kuruyemiş Karışımı', 'Çikolatalı Fındık Kreması', 'Dondurulmuş Kraker', 'Peynirli Çubuk Kraker', 'Soda', 'Fanta', 'Sprite', 'Karpuzlu Gazoz'
    ];
    if (query.isEmpty) {
      return [];
    }
    return databaseItems
        .where((item) => item.toLowerCase().contains(query.toLowerCase()))
        .toList()
      ..addIfAbsent(query);
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.list['title'] ?? 'Başlık Yok',
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
            Text(
              'Toplam Fiyat: ${_totalPrice.toStringAsFixed(2)} TL',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16.0, vertical: 8.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _itemController,
                        onChanged: _onInputChanged,
                        decoration: InputDecoration(
                          hintText: 'Ürün adı girin...',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          border: UnderlineInputBorder(),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.green),
                          ),
                        ),
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.add, color: Colors.green),
                      onPressed: () {
                        if (_currentInput.isNotEmpty) {
                          _addItemToDatabase(_currentInput);
                        }
                      },
                    ),
                  ],
                ),
                if (_suggestedItems.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4.0),
                    color: Colors.grey[850],
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _suggestedItems.length,
                      itemBuilder: (context, index) {
                        final suggestion = _suggestedItems[index];
                        return ListTile(
                          leading: IconButton(
                            icon: Icon(Icons.add, color: Colors.green),
                            onPressed: () => _addItemToDatabase(suggestion),
                          ),
                          title: Text(
                            suggestion,
                            style: TextStyle(color: Colors.white),
                          ),
                          onTap: () {
                            _addItemToDatabase(suggestion);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _items.isEmpty
                ? Center(
              child: Text(
                'Henüz ürün eklenmemiş.',
                style: TextStyle(color: Colors.white70),
              ),
            )
                : ListView.builder(
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return Card(
                  color: Colors.grey[850],
                  child: ListTile(
                    leading: Checkbox(
                      value: item['isChecked'] == 1,
                      onChanged: (_) => _toggleItemCheckedWithPrice(index),
                      activeColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50), // Yuvarlak checkbox
                      ),
                    ),
                    title: Text(
                      item['isChecked'] == 1
                          ? '${item['itemName']} (${item['price']
                          .toStringAsFixed(2)} TL)'
                          : item['itemName'],
                      style: TextStyle(
                        color: item['isChecked'] == 1
                            ? Colors.grey
                            : Colors.white,
                        decoration: item['isChecked'] == 1
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        final confirm = await showDialog(
                          context: context,
                          builder: (context) =>
                              AlertDialog(
                                title: Text(
                                    'Ürünü silmek istediğinize emin misiniz?'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: Text('Hayır'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: Text('Evet'),
                                  ),
                                ],
                              ),
                        );
                        if (confirm == true) {
                          await _dbHelper.deleteItem(item['id']);
                          _loadItems();
                        }
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showPricePerKgCalculator, // Hesaplama dialogunu çağırır
        backgroundColor: Colors.green,
        child: const Icon(Icons.calculate, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      backgroundColor: Colors.black,
    );
  }
}

extension ListUtils<T> on List<T> {
  void addIfAbsent(T element) {
    if (!contains(element)) {
      add(element);
    }
  }
}
