import 'package:base_app/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:base_app/pages/home.dart';
import 'package:base_app/pages/history.dart';
import 'package:base_app/pages/profile.dart';
import 'package:base_app/pages/favorites.dart';

class GroceryListPage extends StatefulWidget {
  const GroceryListPage({super.key});

  @override
  State<GroceryListPage> createState() => _GroceryListPageState();
}

class _GroceryListPageState extends State<GroceryListPage> {
  static const Color background = Color.fromARGB(255, 222, 209, 182);
  static const Color softMaroon = Color.fromARGB(255, 117, 52, 61);
  static const Color sage = Color.fromARGB(255, 126, 153, 120);

  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> _groceryItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGroceryList();
  }

  Future<void> _loadGroceryList() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('groceryList')
        .orderBy('added_at', descending: false)
        .get();

    setState(() {
      _groceryItems = snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'name': doc['name'],
          'checked': doc['checked'] ?? false,
        };
      }).toList();
      _isLoading = false;
    });
  }

  Future<void> _addItem() async {
    String input = _controller.text.trim();
    if (input.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final docRef = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('groceryList')
        .add({
          'name': input,
          'checked': false,
          'added_at': FieldValue.serverTimestamp(),
        });

    setState(() {
      _groceryItems.add({'id': docRef.id, 'name': input, 'checked': false});
      _controller.clear();
    });
  }

  Future<void> _toggleItem(int index) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    bool newValue = !_groceryItems[index]['checked'];

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('groceryList')
        .doc(_groceryItems[index]['id'])
        .update({'checked': newValue});

    setState(() {
      _groceryItems[index]['checked'] = newValue;
    });
  }

  Future<void> _deleteItem(int index) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('groceryList')
        .doc(_groceryItems[index]['id'])
        .delete();

    setState(() {
      _groceryItems.removeAt(index);
    });
  }

  Future<void> _clearChecked() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final checkedItems = _groceryItems
        .where((item) => item['checked'])
        .toList();

    for (var item in checkedItems) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('groceryList')
          .doc(item['id'])
          .delete();
    }

    setState(() {
      _groceryItems.removeWhere((item) => item['checked']);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    int checkedCount = _groceryItems.where((i) => i['checked']).length;

    return Scaffold(
      backgroundColor: background,
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [softMaroon, softMaroon],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              accountName: Text(
                user?.displayName ?? '',
                style: GoogleFonts.raleway(
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              accountEmail: Text(
                user?.email ?? '',
                style: GoogleFonts.raleway(
                  textStyle: const TextStyle(fontSize: 13),
                ),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  user?.displayName?.substring(0, 1).toUpperCase() ?? 'U',
                  style: GoogleFonts.raleway(
                    textStyle: const TextStyle(
                      color: softMaroon,
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                    ),
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home_outlined, color: softMaroon),
              title: Text(
                'Home',
                style: GoogleFonts.raleway(
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => Home()),
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.favorite_outline_rounded,
                color: softMaroon,
              ),
              title: Text(
                'My Plates',
                style: GoogleFonts.raleway(
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FavoritesPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.history_outlined, color: softMaroon),
              title: Text(
                'History',
                style: GoogleFonts.raleway(
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HistoryPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.shopping_cart_outlined,
                color: softMaroon,
              ),
              title: Text(
                'Grocery List',
                style: GoogleFonts.raleway(
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GroceryListPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_outline, color: softMaroon),
              title: Text(
                'My Profile',
                style: GoogleFonts.raleway(
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: Text(
                'Sign Out',
                style: GoogleFonts.raleway(
                  textStyle: const TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              onTap: () async {
                Navigator.pop(context);
                await AuthService().signout(context: context);
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        iconTheme: const IconThemeData(color: softMaroon),
        title: Text(
          'Grocery List',
          style: GoogleFonts.raleway(
            textStyle: const TextStyle(
              color: softMaroon,
              fontWeight: FontWeight.bold,
              fontSize: 34,
            ),
          ),
        ),
        actions: [
          if (checkedCount > 0)
            TextButton(
              onPressed: _clearChecked,
              child: Text(
                'Clear ($checkedCount)',
                style: GoogleFonts.raleway(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_groceryItems.length} items · $checkedCount checked',
                style: GoogleFonts.raleway(
                  fontSize: 14,
                  color: softMaroon.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                onSubmitted: (_) => _addItem(),
                decoration: InputDecoration(
                  hintText: 'Add item...',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add_circle, color: sage),
                    onPressed: _addItem,
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.6),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: softMaroon),
                      )
                    : _groceryItems.isEmpty
                    ? Center(
                        child: Text(
                          'Your grocery list is empty.\nAdd something above!',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.raleway(
                            color: softMaroon.withOpacity(0.5),
                            fontSize: 16,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _groceryItems.length,
                        itemBuilder: (context, index) {
                          final item = _groceryItems[index];
                          final isChecked = item['checked'] as bool;

                          return Dismissible(
                            key: Key(item['id']),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.delete_outline,
                                color: Colors.white,
                              ),
                            ),
                            onDismissed: (_) => _deleteItem(index),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: isChecked
                                    ? background.withOpacity(0.5)
                                    : Colors.white.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                leading: Checkbox(
                                  value: isChecked,
                                  activeColor: sage,
                                  onChanged: (_) => _toggleItem(index),
                                ),
                                title: Text(
                                  item['name'],
                                  style: GoogleFonts.raleway(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    decoration: isChecked
                                        ? TextDecoration.lineThrough
                                        : null,
                                    color: isChecked
                                        ? softMaroon.withOpacity(0.4)
                                        : softMaroon,
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.redAccent,
                                    size: 20,
                                  ),
                                  onPressed: () => _deleteItem(index),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
