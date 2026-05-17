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
  static const Color background = Color.fromARGB(255, 222, 209, 182);
  static const Color softMaroon = Color.fromARGB(255, 117, 52, 61);
  static const Color sage = Color.fromARGB(255, 126, 153, 120);
  static const Color inputFill = Color.fromARGB(255, 247, 245, 241);
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

  Widget _drawerTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color.fromARGB(255, 117, 52, 61)),
      title: Text(
        label,
        style: GoogleFonts.raleway(
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      onTap: onTap,
    );
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
      backgroundColor: const Color.fromARGB(255, 222, 209, 182),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 222, 209, 182),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color.fromARGB(255, 117, 52, 61)),
        title: Image.asset('lib/assets/images/replateLogo1.png', height: 100),
      ),
      // --- DRAWER ---
      drawer: Drawer(
        backgroundColor: const Color.fromARGB(
          255,
          247,
          245,
          241,
        ), // ← inputFill
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color.fromARGB(255, 117, 52, 61), // ← maroon
                    Color.fromARGB(255, 145, 70, 80),
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
                    color: Colors.white,
                  ),
                ),
              ),
              accountEmail: Text(
                user?.email ?? '',
                style: GoogleFonts.raleway(
                  textStyle: const TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  user?.displayName?.substring(0, 1).toUpperCase() ?? 'U',
                  style: GoogleFonts.raleway(
                    textStyle: const TextStyle(
                      color: Color.fromARGB(255, 117, 52, 61),
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                    ),
                  ),
                ),
              ),
            ),
            _drawerTile(
              icon: Icons.home_outlined,
              label: 'Home',
              onTap: () => Navigator.pop(context),
            ),
            _drawerTile(
              icon: Icons.favorite_outline_rounded,
              label: 'My Plates',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FavoritesPage()),
                );
              },
            ),
            _drawerTile(
              icon: Icons.history_outlined,
              label: 'History',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HistoryPage()),
                );
              },
            ),
            _drawerTile(
              icon: Icons.shopping_cart_outlined,
              label: 'Grocery List',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GroceryListPage()),
                );
              },
            ),
            _drawerTile(
              icon: Icons.person_outline,
              label: 'My Profile',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfilePage()),
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

      // --- BODY ---
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getGreeting(user?.displayName ?? 'Chef'),
                style: GoogleFonts.raleway(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Home.sage,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "What's in your pantry?",
                style: GoogleFonts.raleway(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: const Color.fromARGB(255, 117, 52, 61),
                ),
              ),

              const SizedBox(height: 16),

              // --- INPUT FIELD ---
              TextField(
                controller: _controller,
                onSubmitted: (_) => _addIngredient(),
                style: GoogleFonts.raleway(
                  color: Colors.black87,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'Add ingredient...',
                  hintStyle: GoogleFonts.raleway(
                    color: const Color(0xff9A9A9A),
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color.fromARGB(255, 126, 153, 120), // sage
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(
                      Icons.add_circle,
                      color: Color.fromARGB(255, 126, 153, 120),
                    ),
                    onPressed: _addIngredient,
                  ),
                  filled: true,
                  fillColor: const Color.fromARGB(255, 247, 245, 241),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 16,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(
                      color: Color(0xffEFE7DD),
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(
                      color: Color.fromARGB(255, 126, 153, 120),
                      width: 1.6,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // --- INGREDIENT CHIPS ---
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: [
                  for (int i = 0; i < _pantryList.length; i++)
                    InputChip(
                      label: Text(
                        _pantryList[i],
                        style: GoogleFonts.raleway(
                          color: const Color.fromARGB(255, 117, 52, 61),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      onDeleted: () => _removeIngredient(i),
                      deleteIconColor: const Color.fromARGB(255, 117, 52, 61),
                      backgroundColor: const Color.fromARGB(255, 247, 245, 241),
                      side: const BorderSide(color: Color(0xffEFE7DD)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                ],
              ),

              // --- SEARCH BUTTON ---
              if (_pantryList.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: _clearAll,
                      child: Text(
                        'Clear All',
                        style: GoogleFonts.raleway(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 160,
                      height: 40,
                      child: ElevatedButton.icon(
                        onPressed: _search,
                        icon: const Icon(
                          Icons.search,
                          size: 16,
                          color: Colors.white,
                        ),
                        label: Text(
                          'Search',
                          style: GoogleFonts.raleway(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(
                            255,
                            126,
                            153,
                            120,
                          ),
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 20),

              // --- RESULTS ---
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isSearching)
                        const Center(
                          child: CircularProgressIndicator(
                            color: Color.fromARGB(255, 126, 153, 120),
                          ),
                        )
                      else if (_foundRecipes.isNotEmpty) ...[
                        Text(
                          'Search Results',
                          style: GoogleFonts.raleway(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: const Color.fromARGB(255, 117, 52, 61),
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
                                    color: Color.fromARGB(255, 126, 153, 120),
                                  ),
                                  title: Text(
                                    (recipe['title'] ??
                                            recipe['recipe_title'] ??
                                            'Recipe') +
                                        ' (${recipe['num_pantry_ingredients_used']} ingredients)',
                                    style: GoogleFonts.raleway(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: const Color.fromARGB(
                                        255,
                                        117,
                                        52,
                                        61,
                                      ),
                                    ),
                                  ), // ← closes Text()
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
                                ); // ← closes ListTile()
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

      // --- FAB ---
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color.fromARGB(255, 126, 153, 120), // sage
        child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: const Color.fromARGB(255, 247, 245, 241),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (_) => const ChatBox(),
        ),
      ),
    );
  }
}
