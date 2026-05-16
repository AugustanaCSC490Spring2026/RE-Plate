import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GroceryListPage extends StatefulWidget {
  const GroceryListPage({super.key});

  @override
  State<GroceryListPage> createState() => _GroceryListPageState();
}

class _GroceryListPageState extends State<GroceryListPage> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> _groceryItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGroceryList();
  }

  // Load items from Firestore when page opens
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

  // Add a new item
  Future<void> _addItem() async {
    String input = _controller.text.trim();
    if (input.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Add to Firestore
    final docRef = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('groceryList')
        .add({
          'name': input,
          'checked': false,
          'added_at': FieldValue.serverTimestamp(),
        });

    // Add to local state immediately so UI updates fast
    setState(() {
      _groceryItems.add({
        'id': docRef.id,
        'name': input,
        'checked': false,
      });
      _controller.clear();
    });
  }

  // Toggle checked/unchecked
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

  // Delete a single item
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

  // Clear all checked items
  Future<void> _clearChecked() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final checkedItems = _groceryItems.where((item) => item['checked']).toList();

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
    int checkedCount = _groceryItems.where((i) => i['checked']).length;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 245, 218, 122),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 245, 218, 122),
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Color.fromARGB(255, 236, 110, 31),
        ),
        title: Text(
          'Grocery List',
          style: GoogleFonts.raleway(
            textStyle: const TextStyle(
              color: Color.fromARGB(255, 195, 88, 17),
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
        ),
        // Show clear checked button only if something is checked
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

              // Item count summary
              Text(
                '${_groceryItems.length} items · $checkedCount checked',
                style: GoogleFonts.raleway(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),

              // Input field
              TextField(
                controller: _controller,
                onSubmitted: (_) => _addItem(),
                decoration: InputDecoration(
                  hintText: 'Add item...',
                  suffixIcon: IconButton(
                    icon: const Icon(
                      Icons.add_circle,
                      color: Color.fromARGB(255, 159, 77, 207),
                    ),
                    onPressed: _addItem,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // List of items
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color.fromARGB(255, 205, 180, 91),
                        ),
                      )
                    : _groceryItems.isEmpty
                        ? Center(
                            child: Text(
                              'Your grocery list is empty.\nAdd something above!',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.raleway(
                                color: Colors.grey,
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
                                // Swipe left to delete
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
                                        ? Colors.grey[200]
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListTile(
                                    leading: Checkbox(
                                      value: isChecked,
                                      activeColor: const Color.fromARGB(
                                          255, 159, 77, 207),
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
                                            ? Colors.grey
                                            : Colors.black87,
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