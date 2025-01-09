import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'shopping_list_detail_page.dart';

class ShoppingList extends StatefulWidget {
  @override
  _ShoppingListsPageState createState() => _ShoppingListsPageState();
}

class _ShoppingListsPageState extends State<ShoppingList> {
  final List<Map<String, dynamic>> _shoppingLists = [];
  final TextEditingController _listTitleController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchVisible = false;
  bool _isGridView = true;
  String _searchQuery = '';
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _loadShoppingLists();
  }

  Future<void> _loadShoppingLists() async {
    final lists = await _dbHelper.getShoppingLists();
    setState(() {
      _shoppingLists.clear();
      for (var list in lists) {
        _shoppingLists.add({
          'id': list['id'],
          'title': list['title'],
          'items': [],
          'totalPrice': 0.0,
        });
      }
    });
  }

  Future<void> _addShoppingList(String title) async {
    if (title.isEmpty) return;
    final listId = await _dbHelper.insertShoppingList(title);
    setState(() {
      _shoppingLists.insert(0, {
        'id': listId,
        'title': title,
        'items': [],
        'totalPrice': 0.0,
      });
    });
  }

  void _deleteShoppingList(int index) async {
    final listId = _shoppingLists[index]['id'];
    await _dbHelper.deleteShoppingList(listId);
    setState(() {
      _shoppingLists.removeAt(index);
    });
  }

  void _confirmDeleteShoppingList(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Listeyi Sil'),
        content: const Text('Bu listeyi silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              _deleteShoppingList(index);
              Navigator.of(context).pop();
            },
            child: const Text(
              'Sil',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredLists {
    if (_searchQuery.isEmpty) return _shoppingLists;
    return _shoppingLists
        .where((list) =>
        list['title'].toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  void _showAddListDialog() {
    _listTitleController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeni Liste Ekle'),
        content: TextField(
          controller: _listTitleController,
          decoration: const InputDecoration(labelText: 'Liste Başlığı'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              final title = _listTitleController.text.trim();
              if (title.isNotEmpty) {
                _addShoppingList(title);
                Navigator.of(context).pop();
              }
            },
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
  }

  void _viewListContent(Map<String, dynamic> list, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShoppingListDetailPage(
          list: list,
          onItemAdded: (itemName) => _addItemToList(index, itemName),
          onPriceUpdated: () => _updateTotalPrice(index),
        ),
      ),
    );
  }

  void _addItemToList(int index, String itemName) {
    setState(() {
      _shoppingLists[index]['items'].add({
        'name': itemName,
        'isChecked': false,
        'price': 0.0,
      });
    });
  }

  void _updateTotalPrice(int listIndex) {
    final items = _shoppingLists[listIndex]['items'] as List;
    final total = items
        .where((item) => item['isChecked'] as bool)
        .fold(0.0, (sum, item) => sum + (item['price'] as double));
    setState(() {
      _shoppingLists[listIndex]['totalPrice'] = total;
    });
  }

  void _toggleViewMode() {
    setState(() {
      _isGridView = !_isGridView;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alışveriş Listeleri'),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: _toggleViewMode,
          ),
          IconButton(
            icon: Icon(_isSearchVisible ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearchVisible = !_isSearchVisible;
                if (!_isSearchVisible) {
                  _searchQuery = '';
                  _searchController.clear();
                }
              });
            },
          ),
        ],
        bottom: _isSearchVisible
            ? PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Liste Ara',
                hintStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
              ),
            ),
          ),
        )
            : null,
      ),
      body: _filteredLists.isEmpty
          ? const Center(child: Text('Hiç liste bulunamadı.'))
          : _isGridView
          ? GridView.builder(
        padding: const EdgeInsets.all(10),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: _filteredLists.length,
        itemBuilder: (context, index) {
          final list = _filteredLists[index];
          return _buildListCard(list, index);
        },
      )
          : ListView.builder(
        itemCount: _filteredLists.length,
        itemBuilder: (context, index) {
          final list = _filteredLists[index];
          return _buildListTile(list, index);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddListDialog,
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
      backgroundColor: Colors.black,
    );
  }

  Widget _buildListCard(Map<String, dynamic> list, int index) {
    final itemsPreview = (list['items'] as List)
        .map((item) => item['name'])
        .take(3)
        .join(', ');
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      elevation: 5,
      color: Colors.yellow[100],
      child: Stack(
        children: [
          InkWell(
            onTap: () => _viewListContent(list, index),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    list['title'],
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Text(
                      itemsPreview.isEmpty ? '' : itemsPreview,
                      style: const TextStyle(color: Colors.black),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmDeleteShoppingList(index),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(Map<String, dynamic> list, int index) {
    final itemsPreview = (list['items'] as List)
        .map((item) => item['name'])
        .take(3)
        .join(', ');
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      elevation: 5,
      color: Colors.yellow[100],
      child: ListTile(
        title: Text(
          list['title'],
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black, // Yazı rengini siyah yapıyoruz
          ),
        ),
        subtitle: Text(
          itemsPreview.isEmpty ? '' : itemsPreview,
          style: const TextStyle(
            color: Colors.black, // Yazı rengini siyah yapıyoruz
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _confirmDeleteShoppingList(index),
        ),
        onTap: () => _viewListContent(list, index),
      ),
    );
  }

}
