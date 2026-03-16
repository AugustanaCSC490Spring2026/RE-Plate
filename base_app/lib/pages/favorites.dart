import 'package:base_app/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
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

  Future<void> _removeFavorite(String recipeId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(recipeId)
        .delete();
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
          "My Plates",
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
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('favorites')
            .orderBy('saved_at', descending: true)
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
                "No favorite recipes yet",
                style: GoogleFonts.raleway(color: Colors.grey),
              ),
            );
          }

          final favoriteDocs = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: favoriteDocs.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final recipe =
                  favoriteDocs[index].data() as Map<String, dynamic>;

              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.restaurant_menu, color: Colors.green),
                title: Text(
                  recipe['recipe_title'] ?? 'Unnamed Recipe',
                  style: GoogleFonts.raleway(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.favorite, color: Colors.red),
                  onPressed: () => _removeFavorite(recipe['id']),
                ),
                onTap: () => _showRecipeDetails(recipe),
              );
            },
          );
        },
      ),
    );
  }
}