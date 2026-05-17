import 'dart:convert'; // Required for json.decode
import 'package:base_app/pages/grocery_list.dart';
import 'package:base_app/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:base_app/pages/favorites.dart';
import 'package:base_app/pages/history.dart';
import 'package:base_app/pages/chat_box.dart';
import 'package:base_app/pages/profile.dart';
import 'package:base_app/pages/home_recipe.dart';
import 'package:base_app/pages/recipe_detail_page.dart';
import 'package:collection/collection.dart';
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

  String _ingredientNameToDocId(String ingredient) {
    return ingredient.toLowerCase().trim().replaceAll(' ', '_');
  }

  // Thanks to Gemini for parallelizing the fetch requests for each ingredient,
  // which significantly improved performance by allowing multiple Firestore reads to happen simultaneously instead of sequentially. This is especially beneficial when the pantry list contains many ingredients, as it reduces the overall waiting time for all recipe sets to be retrieved.
  /// Fetches recipe sets for all ingredients in the pantry list in parallel.
  Future<List<Set<String>>> fetchRecipeSetsFromIngredientIndexInParallel(
    List<String> pantryList,
  ) async {
    // Create a list of Futures. Note that we do NOT use 'await' inside the map.
    // This starts all the asynchronous operations immediately.
    final List<Future<Set<String>?>> fetchTasks = pantryList.map((
      ingredient,
    ) async {
      try {
        // Logic for formatting the document ID
        final String ingredientID = _ingredientNameToDocId(ingredient);

        // Initiating the Firestore request
        final DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('IngredientIndex')
            .doc(ingredientID)
            .get();

        if (doc.exists && doc.data() != null) {
          final data = doc.data() as Map<String, dynamic>;
          final List<dynamic> recipes = data['recipes'] ?? [];

          // Convert the dynamic list to a Set of Strings
          return recipes.map((recipe) => recipe.toString()).toSet();
        }
      } catch (e) {
        // Error handling for individual requests
        print('Error fetching ingredient $ingredient: $e');
      }

      // Return null or an empty set if the document doesn't exist or fails
      return null;
    }).toList();

    // Future.wait executes all futures in the list in parallel and waits for all to complete.
    final List<Set<String>?> results = await Future.wait(fetchTasks);

    // Remove null results (where docs didn't exist) and return the final list
    return results.whereType<Set<String>>().toList();
  }

  String recipeIdFromTitle(String title) {
    return title
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'''[*"'()]'''), '')
        .replaceAll(' ', '_');
  }

  Future<List<Map<String, dynamic>>> _fetchFullRecipesInParallel(
    List<String> recipeIds,
  ) async {
    // 2. Split the list of IDs into chunks of 30
    List<List<String>> chunks = [];
    const int chunkSize = 30;

    for (int i = 0; i < recipeIds.length; i += chunkSize) {
      int end = (i + chunkSize < recipeIds.length)
          ? i + chunkSize
          : recipeIds.length;
      chunks.add(recipeIds.sublist(i, end));
    }

    // 3. Create a list of Futures to fetch all chunks in parallel
    List<Future<QuerySnapshot<Map<String, dynamic>>>> futures = chunks.map((
      chunk,
    ) {
      debugPrint("Fetching chunk of recipes: $chunk");

      return FirebaseFirestore.instance
          .collection('Recipes')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
    }).toList();

    // 4. Execute all queries concurrently
    List<QuerySnapshot<Map<String, dynamic>>> snapshots = await Future.wait(
      futures,
    );

    // 5. Flatten the list of snapshots into a single list of document snapshots
    List<QueryDocumentSnapshot<Map<String, dynamic>>> unorderedDocs = snapshots
        .expand((snapshot) => snapshot.docs)
        .toList();

    // 6. Crucial: Restore the original order so it matches the order of the recipe titles that came in
    // Create a map for O(1) lookups of the fetched documents
    Map<String, QueryDocumentSnapshot<Map<String, dynamic>>> docMap = {
      for (var doc in unorderedDocs) doc.id: doc,
    };

    // Rebuild the list matching the original rankedRecipeIds order
    List<Map<String, dynamic>> rankedRecipes = [];
    for (String id in recipeIds) {
      if (docMap.containsKey(id)) {
        if (docMap[id]!.exists) {
          //debugPrint("Recipe exists: ${docMap[id]!.id}");
          rankedRecipes.add(docMap[id]!.data());
        } else {
          debugPrint("Document with ID $id does not exist.");
        }
      }
    }
    return rankedRecipes;
  }

  Future<void> _search() async {
    if (_pantryList.isEmpty) return;
    setState(() {
      _isSearching = true;
      _foundRecipes = [];
    });

    try {
      List<String> userRestrictions = await _getUserRestrictions();
      List<Set<String>> recipeSets =
          await fetchRecipeSetsFromIngredientIndexInParallel(_pantryList);

      if (recipeSets.isEmpty) {
        setState(() => _foundRecipes = []);
        return;
      }

      // Scoring — replaces intersection
      Map<String, int> recipeScores = {}; //map
      for (Set<String> setOfRecipesThatIncludeSomeIngredient in recipeSets) {
        for (String recipeTitle in setOfRecipesThatIncludeSomeIngredient) {
          recipeScores[recipeTitle] = (recipeScores[recipeTitle] ?? 0) + 1;
        }
      }

      List<String> rankedRecipeIds = recipeScores.entries
          .sorted((a, b) => b.value.compareTo(a.value))
          .map((e) => recipeIdFromTitle(e.key))
          .toList();

      // truncate list if it's too large
      final int MAX_RECIPES_TO_FETCH_FOR_ONE_QUERY = 180;
      if (rankedRecipeIds.length > MAX_RECIPES_TO_FETCH_FOR_ONE_QUERY) {
        rankedRecipeIds = rankedRecipeIds.sublist(
          0,
          MAX_RECIPES_TO_FETCH_FOR_ONE_QUERY,
        );
      }

      debugPrint("Ranked recipes: ${rankedRecipeIds.length}");

      List<Map<String, dynamic>> rankedRecipes =
          await _fetchFullRecipesInParallel(rankedRecipeIds);

      List<Map<String, dynamic>> filteredRecipes = [];

      for (Map<String, dynamic> recipeData in rankedRecipes) {
        bool matchesPreferences = true;

        for (String restriction in userRestrictions) {
          if (recipeData[restriction] == "False") {
            matchesPreferences = false;
            break;
          }
        }

        if (matchesPreferences) {
          filteredRecipes.add({
            'id': recipeIdFromTitle(recipeData['title']),
            'title': recipeData['title'] ?? recipeData['recipe_title'],
            'ingredients': recipeData['ingredients'] ?? [],
            'directions': recipeData['directions'] ?? [],
            'num_pantry_ingredients_used':
                recipeScores[recipeData['title']] ?? -1,
          });
        }
      }

      setState(() {
        final int MAX_RECIPES_TO_DISPLAY = 50;
        _foundRecipes = filteredRecipes.take(MAX_RECIPES_TO_DISPLAY).toList();
      });
    } catch (e) {
      debugPrint("Search Error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error fetching recipes: $e")));
    } finally {
      setState(() => _isSearching = false);
    }
  }

  Future<List<String>> _getUserRestrictions() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    if (doc.exists) {
      return List<String>.from(doc.data()?['dietaryRestrictions'] ?? []);
    }
    return [];
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
      final recipeDoc = await FirebaseFirestore.instance
          .collection('Recipes')
          .doc(recipeId)
          .get();

      Map<String, dynamic> fullData = {};
      if (recipeDoc.exists) {
        fullData = recipeDoc.data() ?? {};
      }
      var recipeTitle =
          fullData['title'] ?? recipe['title'] ?? 'Unnamed Recipe';
      debugPrint(recipeTitle);
      await favoriteRef.set({
        'recipe_title':
            fullData['title'] ?? recipe['title'] ?? 'Unnamed Recipe',
        'id': recipeId,
        'ingredients': recipe['ingredients'],
        'directions': recipe['directions'],
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
          'recipe_title':
              recipe['title'] ?? recipe['recipe_title'] ?? 'Unnamed Recipe',
          'id': recipeId,
          'directions': recipe['directions'],
          'ingredients': recipe['ingredients'],
          'viewed_at': FieldValue.serverTimestamp(),
        });
  }

  /// The main build method that constructs the UI of the home screen, including the search input, ingredient chips, search button, and results list
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Color.fromARGB(255, 245, 218, 122),
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 245, 218, 122),
        elevation: 0,
        title: Text(
          'Lets RE-Plate!',
          style: GoogleFonts.raleway(
            textStyle: const TextStyle(
              color: Color.fromARGB(255, 195, 88, 17),
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
        ),
        iconTheme: const IconThemeData(
          color: Color.fromARGB(255, 236, 110, 31),
        ),
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
                      color: Color.fromARGB(255, 111, 87, 192),
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
                color: Color.fromARGB(255, 109, 83, 194),
              ),
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
                color: Color.fromARGB(255, 120, 69, 182),
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
                color: Color.fromARGB(255, 130, 72, 183),
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
                color: Color.fromARGB(255, 97, 57, 163),
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
                  color: Color.fromARGB(255, 195, 88, 17),
                ),
              ),

              // search the input field for adding ingredients to the pantry list, with an add button and submit on enter functionality
              TextField(
                controller: _controller,
                onSubmitted: (_) => _addIngredient(),
                decoration: InputDecoration(
                  hintText: "Add ingredient...",
                  suffixIcon: IconButton(
                    icon: const Icon(
                      Icons.add_circle,
                      color: Color.fromARGB(255, 159, 77, 207),
                    ),
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
                    onPressed: () => _search(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromARGB(255, 245, 218, 122),
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
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search results appear FIRST when searching
                      if (_isSearching)
                        const Center(
                          child: CircularProgressIndicator(
                            color: Color.fromARGB(255, 205, 180, 91),
                          ),
                        )
                      else if (_foundRecipes.isNotEmpty) ...[
                        Text(
                          'Search Results',
                          style: GoogleFonts.raleway(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: const Color.fromARGB(255, 195, 88, 17),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _foundRecipes.length,
                          itemBuilder: (context, index) {
                            final recipe = _foundRecipes[index];
                            return FutureBuilder<bool>(
                              future: _isFavorited(recipe['id']),
                              builder: (context, snapshot) {
                                final isFavorited = snapshot.data ?? false;
                                return ListTile(
                                  onTap: () => RecipeDetailPage.show(
                                    context,
                                    recipe,
                                    onLogHistory: _logHistory,
                                  ),
                                  leading: const Icon(
                                    Icons.restaurant_menu,
                                    color: Colors.green,
                                  ),
                                  title: Text(
                                    (recipe['title'] ??
                                            recipe['recipe_title'] ??
                                            "Recipe") +
                                        " (${recipe['num_pantry_ingredients_used']} ingredients)",
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
                                        onPressed: () =>
                                            _toggleFavorite(recipe),
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
                        const SizedBox(height: 24),
                      ],
                      FeaturedRecipesSection(
                        onRecipeTap: (recipe) => RecipeDetailPage.show(
                          context,
                          recipe,
                          onLogHistory: _logHistory,
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color.fromARGB(255, 209, 138, 37),
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
} /*  */
