import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  void _showRecipeDetails(Map<String, dynamic> recipe) {
    List directionsList = [];
    if (recipe['directions'] != null) {
      directionsList = recipe['directions'];
    } else if (recipe['preparation_steps'] != null) {
      directionsList = recipe['preparation_steps'];
    }

    List ingredientsList = [];
    if (recipe['ingredients'] != null) {
      ingredientsList = recipe['ingredients'];
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                recipe['recipe_title'] ?? "Unnamed Recipe",
                style: GoogleFonts.raleway(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Ingredients",
                style: GoogleFonts.raleway(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(),
              for (var ing in ingredientsList)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    "• $ing",
                    style: GoogleFonts.raleway(fontSize: 16),
                  ),
                ),
              const SizedBox(height: 25),
              Text(
                "Preparation Steps",
                style: GoogleFonts.raleway(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(),
              if (directionsList.isEmpty)
                Text(
                  "No steps provided.",
                  style: GoogleFonts.raleway(color: Colors.grey),
                )
              else
                for (int i = 0; i < directionsList.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${i + 1}. ",
                          style: GoogleFonts.raleway(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            directionsList[i].toString(),
                            style: GoogleFonts.raleway(
                              fontSize: 16,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  /// Clears the entire history for the current user
  Future<void> _clearHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Clear History", style: GoogleFonts.raleway(fontWeight: FontWeight.bold)),
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
            child: const Text("Clear", style: TextStyle(color: Colors.redAccent)),
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
      return const Scaffold(
        body: Center(child: Text("No user signed in")),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "History",
          style: GoogleFonts.raleway(
            textStyle: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.green),
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
              child: CircularProgressIndicator(color: Colors.green),
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
      leading: const Icon(Icons.history, color: Colors.green),
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
              isFavorited ? Icons.favorite : Icons.favorite_border,
              color: isFavorited ? Colors.red : Colors.grey,
            ),
            onPressed: () => _toggleFavorite(recipe),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        ],
      ),
      onTap: () => _showRecipeDetails(recipe),
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