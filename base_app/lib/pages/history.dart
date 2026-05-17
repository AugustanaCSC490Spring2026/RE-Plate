import 'package:base_app/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:base_app/pages/favorites.dart';
import 'package:base_app/pages/home.dart';
import 'package:base_app/pages/profile.dart';
import 'package:base_app/pages/recipe_detail_page.dart';
import 'package:base_app/pages/grocery_list.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  /// Clears the entire history for the current user
  Future<void> _clearHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Clear History",
          style: GoogleFonts.raleway(fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Are you sure you want to clear all your recipe history?",
          style: GoogleFonts.raleway(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Clear",
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final historyRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('history');

    final snapshot = await historyRef.get();
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  Future<bool> _isFavorited(String recipeId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(recipeId)
        .get();

    return doc.exists;
  }

  Future<void> _toggleFavorite(Map<String, dynamic> recipe) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final recipeId = recipe['id'];
    final favoriteRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(recipeId);

    final doc = await favoriteRef.get();

    if (doc.exists) {
      await favoriteRef.delete();
    } else {
      await favoriteRef.set({
        'recipe_title': recipe['recipe_title'] ?? 'Unnamed Recipe',
        'ingredients': recipe['ingredients'] ?? [],
        'directions': recipe['directions'] ?? [],
        'preparation_steps': recipe['preparation_steps'] ?? [],
        'id': recipeId,
        'saved_at': FieldValue.serverTimestamp(),
      });
    }

    setState(() {});
  }

  /// Formats a Firestore Timestamp into a readable string
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final dt = timestamp.toDate();
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${dt.month}/${dt.day}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("No user signed in")));
    }

    return Scaffold(
      backgroundColor: Color.fromARGB(255, 245, 218, 122),
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color.fromARGB(255, 245, 218, 122),
                    Color.fromARGB(255, 226, 195, 110),
                  ],
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
                      color: Color.fromARGB(255, 103, 17, 195),
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                    ),
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.home_outlined,
                color: Color.fromARGB(255, 101, 76, 143),
              ),
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
                  MaterialPageRoute(
                    builder: (context) => Home(),
                  ), // replace HomePage with your actual class name
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.favorite_outline_rounded,
                color: Color.fromARGB(255, 102, 79, 186),
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
              leading: const Icon(
                Icons.history_outlined,
                color: Color.fromARGB(255, 111, 42, 175),
              ),
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
                color: Color.fromARGB(255, 109, 83, 194),
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
              leading: const Icon(
                Icons.person_outline,
                color: Color.fromARGB(255, 111, 40, 197),
              ),
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
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'lib/assets/images/replateLogo1.png',
              height: 36,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 4),
            Text(
              "History",
              style: GoogleFonts.raleway(
                textStyle: const TextStyle(
                  color: Color.fromARGB(255, 176, 70, 198),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Color.fromARGB(255, 245, 218, 122),
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Color.fromARGB(255, 149, 81, 222),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            tooltip: "Clear History",
            onPressed: _clearHistory,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('history')
            .orderBy('viewed_at', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color.fromARGB(255, 245, 218, 122),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                "No recipes viewed yet",
                style: GoogleFonts.raleway(color: Colors.grey),
              ),
            );
          }

          final historyDocs = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: historyDocs.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final recipe = historyDocs[index].data() as Map<String, dynamic>;
              final timestamp = recipe['viewed_at'] as Timestamp?;

              return FutureBuilder<bool>(
                future: _isFavorited(recipe['id'] ?? ''),
                builder: (context, snapshot) {
                  final isFavorited = snapshot.data ?? false;

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.history,
                      color: Color.fromARGB(255, 128, 68, 197),
                    ),
                    title: Text(
                      recipe['recipe_title'] ?? 'Unnamed Recipe',
                      style: GoogleFonts.raleway(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      _formatTimestamp(timestamp),
                      style: GoogleFonts.raleway(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            isFavorited
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: isFavorited ? Colors.red : Colors.grey,
                          ),
                          onPressed: () => _toggleFavorite(recipe),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                    onTap: () => RecipeDetailPage.show(context, recipe),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
