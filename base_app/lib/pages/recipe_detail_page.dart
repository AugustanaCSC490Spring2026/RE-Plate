// recipe_detail_sheet.dart
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RecipeDetailSheet extends StatelessWidget {
  final Map<String, dynamic> recipe;
  final Future<void> Function(Map<String, dynamic>)? onLogHistory;

  const RecipeDetailSheet({
    super.key,
    required this.recipe,
    this.onLogHistory,
  });

  /// Call this static method from anywhere to show the bottom sheet
  static Future<void> show(
    BuildContext context,
    Map<String, dynamic> recipe, {
    Future<void> Function(Map<String, dynamic>)? onLogHistory,
  }) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          const Center(child: CircularProgressIndicator(color: Colors.green)),
    );

    try {
      final doc = await FirebaseFirestore.instance
          .collection('Recipes')
          .doc(recipe['id'])
          .get();

      Navigator.of(context, rootNavigator: true).pop(); // dismiss loader

      if (!doc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Recipe details not found.")),
        );
        return;
      }

      final fullData = doc.data()!;
      final ingredients = _ensureList(fullData['ingredients']);
      final directions = _ensureList(fullData['directions']);

      final fullRecipe = {
        'id': recipe['id'],
        'title': fullData['title'],
        'ingredients': ingredients,
        'directions': directions,
      };

      // Log history if callback provided
      await onLogHistory?.call(fullRecipe);

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => RecipeDetailSheet(recipe: fullRecipe),
      );
    } catch (e) {
      if (Navigator.canPop(context)) Navigator.pop(context);
      debugPrint("Error in RecipeDetailSheet.show: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching recipe: $e")),
      );
    }
  }

  /// Safely converts a field to a List, even if it's a JSON string
  static List<dynamic> _ensureList(dynamic field) {
    if (field == null) return [];
    if (field is List) return field;
    if (field is String) {
      try {
        return json.decode(field) as List<dynamic>;
      } catch (_) {
        return [field];
      }
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final ingredients = _ensureList(recipe['ingredients']);
    final directions = _ensureList(recipe['directions']);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: ListView(
          controller: scrollController,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header row
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios,
                      color: Color.fromARGB(255, 195, 88, 17)),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    recipe['title'] ?? 'Recipe',
                    style: GoogleFonts.raleway(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: const Color.fromARGB(255, 154, 67, 208),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Ingredients
            Text('Ingredients',
                style: GoogleFonts.raleway(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...ingredients.map(
              (ingredient) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.fiber_manual_record,
                        size: 8, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(ingredient.toString(),
                          style: GoogleFonts.raleway(fontSize: 14)),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Directions
            Text('Directions',
                style: GoogleFonts.raleway(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...directions.asMap().entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor:
                          const Color.fromARGB(255, 195, 88, 17),
                      child: Text(
                        '${entry.key + 1}',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 11),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(entry.value.toString(),
                          style: GoogleFonts.raleway(fontSize: 14)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}