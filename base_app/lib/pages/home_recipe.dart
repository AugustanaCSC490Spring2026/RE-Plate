import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FeaturedRecipesSection extends StatelessWidget {
  final Function(Map<String, dynamic>) onRecipeTap;

  const FeaturedRecipesSection({super.key, required this.onRecipeTap});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Recipes')
          .where('featured', isEqualTo: true)
          .limit(6)
          .snapshots(),

      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 220,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final recipes = snapshot.data!.docs;

        if (recipes.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Featured Recipes",
              style: GoogleFonts.raleway(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color.fromARGB(255, 195, 88, 17),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              height: 230,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: recipes.length,

                separatorBuilder: (context, index) => const SizedBox(width: 16),

                itemBuilder: (context, index) {
                  final doc = recipes[index];

                  final data = doc.data() as Map<String, dynamic>;

                  return SizedBox(
                    width: 220,

                    child: RecipeImageCard(
                      title: data['title'] ?? doc.id,

                      imageUrl: data['imageURL'] ?? '',

                      onTap: () {
                        onRecipeTap({'id': doc.id});
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class RecipeImageCard extends StatelessWidget {
  final String title;
  final String imageUrl;
  final VoidCallback onTap;

  const RecipeImageCard({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              imageUrl,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                debugPrint('Image load error: $error');
                return _placeholder();
              },
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.raleway(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(255, 195, 88, 17),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      height: 150,
      color: Colors.grey[300],
      child: const Center(child: Icon(Icons.restaurant_menu, size: 50)),
    );
  }
}
