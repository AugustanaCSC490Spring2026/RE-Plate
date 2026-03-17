import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  /// stores the list of recipes that match the category button that was clicked, to be displayed in the results list
  List<Map<String, dynamic>> _recipesList = [];
  
  /// this boolean tracks whether we are currently loading data from the database, so we can show a loading sign while waiting for results
  bool _loading = false;

  /// list of all the categoreis from the database.
  final List<String> _myCategories = [
    "Air Fryer Recipes",
    "Beef Recipes",
    "Zucchini Breads",
    "Cakes",
    "Breakfast",
    "Main Dishes",
    "Desserts"
  ];

  /// This function queries the Firestore database for recipes that match the category button that was clicked, and updates the _recipesList with the results
  void _getRecipesFromDatabase(String categoryName) async {
    setState(() {
      _loading = true;
    });
/// we have to get all the recipes from the database and filter them in the app code, because Firestore doesn't support "OR" queries that would allow us to check both the category and subcategory fields at the same time
    try {
      var collection = FirebaseFirestore.instance.collection('recipes');
      var querySnapshot = await collection.get();

      List<Map<String, dynamic>> matches = [];

      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data();

        /// find the category and subcategory fields in the database, and check if either matches the category button that was clicked
        String categoryInDb = data['category'].toString();
        String subcategoryInDb = data['subcategory'].toString();

        if (categoryInDb == categoryName || subcategoryInDb == categoryName) {
          matches.add(data);
        }
      }

      setState(() {
        _recipesList = matches;
        _loading = false;
      });

    } catch (e) {
      setState(() {
        _loading = false;
      });
      print("Error! $e");
    }
  }

  /// This function opens a bottom sheet with the recipe details when a recipe is pressed on(tapped)
  void _openRecipeDetails(Map<String, dynamic> recipe) {
   /// list of steps can be under either 'directions' or 'preparation_steps' in the database, so we check both and use whichever is available
    List steps = recipe['directions'] ?? recipe['preparation_steps'] ?? [];
    /// list of ingredients, defaulting to empty list if not found
    List ingredients = recipe['ingredients'] ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// small drag handle at the top of the drawer
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                /// recipe title
                Text(
                  recipe['recipe_title'] ?? "No Title",
                  style: GoogleFonts.raleway(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
                ),
                const Divider(),
                
                ///ingredients section 
                const SizedBox(height: 10),
                Text("Ingredients", style: GoogleFonts.raleway(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (ingredients.isEmpty)
                  Text("No ingredients were listed.", style: GoogleFonts.raleway(color: Colors.grey))
                else
                  for (var item in ingredients)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Text("• $item", style: GoogleFonts.raleway(fontSize: 16)),
                    ),

                const SizedBox(height: 25),

                /// instructions section
                Text("Instructions", style: GoogleFonts.raleway(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (steps.isEmpty)
                  Text("No instructions were listed.", style: GoogleFonts.raleway(color: Colors.grey))
                else
                  for (int i = 0; i < steps.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("${i + 1}. ", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Expanded(
                            child: Text(
                              steps[i].toString(),
                              style: GoogleFonts.raleway(fontSize: 16, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }
/// The build method creates the UI for the categories page, including the horizontal scrolling category buttons and the list of recipes that match the selected category
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Categories List", style: GoogleFonts.raleway(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
        /// scrollable row of category buttons at the top
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const SizedBox(width: 10),
                  for (String name in _myCategories)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ElevatedButton(
                        onPressed: () => _getRecipesFromDatabase(name),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: Text(name),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const Divider(thickness: 1),

          /// the expanded UI section that shows either the loading spinner, the "select a category" message, or the list of recipes that match the selected category
          Expanded(
            child: _loading 
                ? const Center(child: CircularProgressIndicator(color: Colors.green))
                : _recipesList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.category_outlined, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text("Select a category!", style: GoogleFonts.raleway(color: Colors.grey, fontSize: 16)),
                          ],
                        ),
                      )
                    /// if there are recipes in the _recipesList, show them in a ListView with dividers between each item

                    : ListView.separated(
                        itemCount: _recipesList.length,
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: (context, index) {
                          Map<String, dynamic> currentRecipe = _recipesList[index];
                          return ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Colors.green,
                              child: Icon(Icons.restaurant, color: Colors.white, size: 18),
                            ),
                            title: Text(currentRecipe['recipe_title'] ?? "Recipe", style: GoogleFonts.raleway(fontWeight: FontWeight.w500)),
                            subtitle: Text(currentRecipe['subcategory'] ?? "General", style: const TextStyle(fontSize: 12)),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                            onTap: () => _openRecipeDetails(currentRecipe),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}