import 'package:base_app/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:base_app/pages/favorites.dart';
import 'package:base_app/pages/history.dart';


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
  void _showRecipeDetails(Map<String, dynamic> recipe) {
    /// find the recipe directions, checking for both "directions" and "preparation_steps" fields to accommodate different recipe formats
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

    /// Show the bottom sheet with recipe details, including title, ingredients, and preparation steps
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

  /// Searches Firestore for recipes that contain all the ingredients in the pantry list
  Future<void> _search() async {
    if (_pantryList.isEmpty) return;
    setState(() => _isSearching = true);

    /// Fetch a batch of recipes from Firestore (you may want to implement pagination for larger datasets)
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('recipes')
          .limit(100)
          .get();

      List<Map<String, dynamic>> tempResults = [];

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data();
        List recipeIngredients = data['ingredients'] ?? [];

        bool hasAllIngredients = true;

        /// For every ingredient in the pantry
        for (String pantryItem in _pantryList) {
          bool foundThisItem = false;

          /// Check if it exists anywhere in the recipe ingredients list
          for (var ingredientLine in recipeIngredients) {
            if (ingredientLine.toString().toLowerCase().contains(
              pantryItem.toLowerCase(),
            )) {
              foundThisItem = true;
              break; // Stop looking for this specific item once found
            }
          }

          /// If we didn't find even one of our items, the whole recipe fails
          if (foundThisItem == false) {
            hasAllIngredients = false;
            break;
          }
        }

        /// if we made it through the whole pantry list and found every item, this recipe is a match and we can add it to our results
        if (hasAllIngredients == true) {
          data['id'] = doc.id;
          tempResults.add(data);
        }
      }

      /// Update the state with the found recipes and stop the loading indicator
      setState(() {
        _foundRecipes = tempResults;
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
      debugPrint("Search Error: $e");
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
                'Pantry Search',
                style: GoogleFonts.raleway(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
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
                                onTap: (){
                                _logHistory(recipe);
                                _showRecipeDetails(recipe);
                                },
                                leading: const Icon(
                                  Icons.restaurant_menu,
                                  color: Colors.green,
                                ),
                                title: Text(
                                  recipe['recipe_title'] ??
                                      "Recipe ID: ${recipe['id']}",
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
    );
  }
}
