import 'package:base_app/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:base_app/pages/favorites.dart';
import 'package:base_app/pages/history.dart';
import 'package:base_app/pages/chat_box.dart';

// credits to @MahdiNazmi for source code
// github link:

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final TextEditingController _controller = TextEditingController();

  /// state variables:
  List<String> _pantryList = [];

  // Store the actual map  data instead of just a string to access ingredients/steps later

  List<Map<String, dynamic>> _foundRecipes = [];
  bool _isSearching = false;

  /// Adds a new ingredient to the pantry list if it's not empty and not already present
  void _addIngredient() {
    String input = _controller.text.trim();

    if (input.isNotEmpty) {
      bool alreadyInList = false;
      for (String item in _pantryList) {
        if (item == input) {
          alreadyInList = true;
        }
      }

      if (alreadyInList == false) {
        setState(() {
          _pantryList.add(input);
          _controller.clear();
        });
      }
    }
  }

  String _getGreeting(String name) {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning, $name!';
    } else if (hour < 17) {
      return 'Good afternoon, $name!';
    } else {
      return 'Good evening, $name!';
    }
  }

  /// Removes a specific ingredient chip based on its index
  void _removeIngredient(int index) {
    setState(() {
      _pantryList.removeAt(index);
    });
  }

  /// Clears the entire pantry and results lists, resetting the search state
  void _clearAll() {
    setState(() {
      _pantryList.clear();
      _foundRecipes.clear();
    });
  }

  /// A function to show recipe details in a bottom sheet
  void _showRecipeDetails(Map<String, dynamic> recipe) async {
  showDialog(
    context: context,
    builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.green)),
  );

  try {
    var snapshot = await FirebaseFirestore.instance
        .collection('RecipeNLG')
        .where('title', isEqualTo: recipe['title'])
        .limit(1)
        .get();

    Navigator.pop(context); // Remove loader

    if (snapshot.docs.isNotEmpty) {
      var fullData = snapshot.docs.first.data();

      _logHistory({
        ...fullData,
        'id': recipe['title'],
        'recipe_title': fullData['title'],
      });

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => DraggableScrollableSheet(
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

// Back arrow + Title row
Row(
  children: [
    IconButton(
      icon: const Icon(Icons.arrow_back_ios, color: Colors.green),
      onPressed: () => Navigator.pop(context),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    ),
    const SizedBox(width: 8),
    Expanded(
      child: Text(
        fullData['title'] ?? 'Recipe',
        style: GoogleFonts.raleway(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
      ),
    ),
  ],
),

                // Title
                Text(
                  fullData['title'] ?? 'Recipe',
                  style: GoogleFonts.raleway(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 20),

                // Ingredients section
                Text(
                  'Ingredients',
                  style: GoogleFonts.raleway(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...(fullData['ingredients'] as List<dynamic>? ?? []).map(
                  (ingredient) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.fiber_manual_record, size: 8, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            ingredient.toString(),
                            style: GoogleFonts.raleway(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Directions section
                Text(
                  'Directions',
                  style: GoogleFonts.raleway(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...(fullData['directions'] as List<dynamic>? ?? []).asMap().entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.green,
                          child: Text(
                            '${entry.key + 1}',
                            style: const TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            entry.value.toString(),
                            style: GoogleFonts.raleway(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Recipe details not found.")),
      );
    }
  } catch (e) {
    Navigator.pop(context);
    debugPrint("Error loading recipe: $e");
  }
}
  /// Searches Firestore for recipes that contain all the ingredients in the pantry list
Future<void> _search() async {
  if (_pantryList.isEmpty) return;
  setState(() {
    _isSearching = true;
    _foundRecipes = [];
  });

  try {
    List<Set<String>> recipeSets = [];

    for (String ingredient in _pantryList) {
      String formattedName = ingredient.toLowerCase().trim().replaceAll(' ', '_');
      Set<String> ingredientRecipes = {};

      // 1. Exact match first
      String exactId = "-_$formattedName";
      DocumentSnapshot exactDoc = await FirebaseFirestore.instance
          .collection('IngredientIndex')
          .doc(exactId)
          .get();

      if (exactDoc.exists) {
        List<dynamic> recipes = exactDoc.get('recipes') ?? [];
        ingredientRecipes.addAll(recipes.cast<String>());
        debugPrint("Exact match for $formattedName: ${ingredientRecipes.length} recipes");
      }

      // 2. Prefix query to catch variants
      String startId = "-_$formattedName";
      String endId = "-_$formattedName\uf8ff";

      QuerySnapshot prefixSnapshot = await FirebaseFirestore.instance
          .collection('IngredientIndex')
          .orderBy(FieldPath.documentId)
          .startAt([startId])
          .endAt([endId])
          .get();

      for (var doc in prefixSnapshot.docs) {
        List<dynamic> recipes = doc.get('recipes') ?? [];
        ingredientRecipes.addAll(recipes.cast<String>());
      }

      debugPrint("Total recipes for '$ingredient': ${ingredientRecipes.length}");

      if (ingredientRecipes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("'$ingredient' not recognized, skipping...")),
        );
        continue;
      }

      recipeSets.add(ingredientRecipes);
    }

    if (recipeSets.isEmpty) {
      setState(() => _foundRecipes = []);
      return;
    }

    // Strict intersection
    Set<String> commonTitles = recipeSets.reduce((a, b) => a.intersection(b));
    debugPrint("Intersection result: ${commonTitles.length} recipes");

    // Fallback best-effort if intersection is empty
    if (commonTitles.isEmpty && recipeSets.length > 1) {
      Map<String, int> recipeCount = {};
      for (var set in recipeSets) {
        for (var title in set) {
          recipeCount[title] = (recipeCount[title] ?? 0) + 1;
        }
      }
      int threshold = (recipeSets.length / 2).ceil();
      commonTitles = recipeCount.entries
          .where((e) => e.value >= threshold)
          .map((e) => e.key)
          .toSet();

      if (commonTitles.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Showing closest matches for your ingredients")),
        );
      }
    }

    setState(() {
      _foundRecipes = commonTitles.take(30).map((title) => {
        'title': title,
        'id': title,
      }).toList();
    });

    if (_foundRecipes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No recipes found with those ingredients.")),
      );
    }

  } catch (e) {
    debugPrint("Search Error: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Something went wrong. Please try again.")),
    );
  } finally {
    setState(() => _isSearching = false);
  }
}

  /// Check if a recipe is already favorited by the current user
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

  /// Add or remove a recipe from favorites
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

  //keeps track of user history
  Future<void> _logHistory(Map<String, dynamic> recipe) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final recipeId = recipe['id'];
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('history')
        .doc(recipeId)
        .set({
          'recipe_title': recipe['recipe_title'] ?? 'Unnamed Recipe',
          'ingredients': recipe['ingredients'] ?? [],
          'directions': recipe['directions'] ?? [],
          'preparation_steps': recipe['preparation_steps'] ?? [],
          'id': recipeId,
          'viewed_at': FieldValue.serverTimestamp(),
        });
  }

  /// The main build method that constructs the UI of the home screen, including the search input, ingredient chips, search button, and results list
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Lets RE-Plate!',
          style: GoogleFonts.raleway(
            textStyle: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.green),
      ),
      // I used CLaude AI assistance to learn about scafolding and putting things into
      // the sidebar
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green, Colors.lightGreen],
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
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                    ),
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home_outlined, color: Colors.green),
              title: Text(
                'Home',
                style: GoogleFonts.raleway(
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(
                Icons.favorite_outline_rounded,
                color: Colors.green,
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
              leading: const Icon(Icons.history_outlined, color: Colors.green),
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getGreeting(user?.displayName ?? 'Chef'),
                style: GoogleFonts.raleway(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Pantry Search',
                style: GoogleFonts.raleway(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 5),
              const SizedBox(height: 5),
              Text(
                'Find recipes that use all these ingredients:',
                style: GoogleFonts.raleway(color: Colors.grey),
              ),
              const SizedBox(height: 20),

              // search the input field for adding ingredients to the pantry list, with an add button and submit on enter functionality
              TextField(
                controller: _controller,
                onSubmitted: (_) => _addIngredient(),
                decoration: InputDecoration(
                  hintText: "Add ingredient...",
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.green),
                    onPressed: _addIngredient,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              /// Display the list of added ingredients as chips with delete functionality
              Wrap(
                spacing: 8.0,
                children: [
                  for (int i = 0; i < _pantryList.length; i++)
                    InputChip(
                      label: Text(_pantryList[i], style: GoogleFonts.raleway()),
                      onDeleted: () => _removeIngredient(i),
                      deleteIconColor: Colors.redAccent,
                      backgroundColor: Colors.green[50],
                    ),
                ],
              ),

              /// if there are ingredients in the pantry list, show the "Search Recipes" button and "Clear All" option
              if (_pantryList.isNotEmpty) ...[
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _clearAll,
                    child: const Text(
                      "Clear All",
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _search,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "Search Recipes",
                      style: GoogleFonts.raleway(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 25),

              /// Display search results or loading indicator or a prompt to add ingredients
              ///
              Expanded(
                child: _isSearching
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.green),
                      )
                    : _foundRecipes.isEmpty
                    ? Center(
                        child: Text(
                          "Add ingredients to start",
                          style: GoogleFonts.raleway(color: Colors.grey),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _foundRecipes.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final recipe = _foundRecipes[index];

                          return FutureBuilder<bool>(
                            future: _isFavorited(recipe['id']),
                            builder: (context, snapshot) {
                              final isFavorited = snapshot.data ?? false;

                              return ListTile(
                                onTap: () {
                                  _logHistory(recipe);
                                  _showRecipeDetails(recipe);
                                },
                                leading: const Icon(
                                  Icons.restaurant_menu,
                                  color: Colors.green,
                                ),
                                title: Text(
                                  recipe['title'] ?? recipe['recipe_title'] ?? "Recipe",
                                  style: GoogleFonts.raleway(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
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
                                        color: isFavorited
                                            ? Colors.red
                                            : Colors.grey,
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
                                contentPadding: EdgeInsets.zero,
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
        floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (_) => const ChatBox(),
        ),
      ),
    );
  }
}/*  */
