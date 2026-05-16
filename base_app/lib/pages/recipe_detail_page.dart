import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:collection/collection.dart';


class RecipeDetailPage extends StatefulWidget {
  @override
  State<RecipeDetailPage> createState() => _RecipeDetailPageState();
  final Map<String, dynamic> recipe;
  final Future<void> Function(Map<String, dynamic>)? onLogHistory;
   final Set<String> excludedIngredients; 

  const RecipeDetailPage({
    super.key,
    required this.recipe,
    this.onLogHistory,
    this.excludedIngredients = const {},
  });

  /// Call this static method from anywhere to show the bottom sheet
  static Future<void> show(
  BuildContext context,
  Map<String, dynamic> recipe, {
  Future<void> Function(Map<String, dynamic>)? onLogHistory,
  Set<String> excludedIngredients = const {}, // ADD THIS
}) async {
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

    Navigator.of(context, rootNavigator: true).pop();

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
      'clean_ingredients': _ensureList(fullData['clean_ingredients']),
    };

    await onLogHistory?.call(fullRecipe);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RecipeDetailPage(
        recipe: fullRecipe,
        onLogHistory: onLogHistory,
        excludedIngredients: excludedIngredients,
      ),
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
class _RecipeDetailPageState extends State<RecipeDetailPage> {
  // true = user HAS it, false = missing (crossed off)
  late Map<String, bool> _have;
  bool _isSearching = false;

  @override
  @override
void initState() {
  super.initState();
  final cleanIngredients = RecipeDetailPage._ensureList(
    widget.recipe['clean_ingredients'],
  ).map((e) => e.toString()).toList();

  _have = {
    for (final ing in cleanIngredients)
      // pre-cross-off anything excluded from a previous search
      ing: !widget.excludedIngredients.any(
        (ex) => ex.toLowerCase() == ing.toLowerCase(),
      ),
  };
}

  String _toIndexKey(String ingredient) =>
      ingredient.trim().toLowerCase().replaceAll(' ', '_');

 Future<void> _searchWithAvailable() async {
  final available = _have.entries.where((e) => e.value).map((e) => e.key).toList();

  // Combine previously excluded + newly crossed off
  final nowExcluded = _have.entries
      .where((e) => !e.value)
      .map((e) => e.key)
      .toSet()
    ..addAll(widget.excludedIngredients);

  if (available.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("You need at least one ingredient.")),
    );
    return;
  }

  setState(() => _isSearching = true);

  try {
    final List<Future<Set<String>?>> fetchTasks = available.map((ing) async {
      final doc = await FirebaseFirestore.instance
          .collection('IngredientIndex')
          .doc(_toIndexKey(ing))
          .get();
      if (!doc.exists) return null;
      final recipes = List<String>.from(doc.data()?['recipes'] ?? []);
      return recipes.toSet();
    }).toList();

    final results = await Future.wait(fetchTasks);
    final recipeSets = results.whereType<Set<String>>().toList();

    final Map<String, int> recipeScores = {};
    for (final recipeSet in recipeSets) {
      for (final recipeTitle in recipeSet) {
        recipeScores[recipeTitle] = (recipeScores[recipeTitle] ?? 0) + 1;
      }
    }

    final currentTitle = widget.recipe['title'] ?? '';

    // Fetch IngredientIndex docs for ALL excluded ingredients
    // so we can filter out any recipe that contains them
    final Set<String> recipesContainingExcluded = {};
    for (final excluded in nowExcluded) {
      final doc = await FirebaseFirestore.instance
          .collection('IngredientIndex')
          .doc(_toIndexKey(excluded))
          .get();
      if (doc.exists) {
        final recipes = List<String>.from(doc.data()?['recipes'] ?? []);
        recipesContainingExcluded.addAll(recipes);
      }
    }

    final rankedTitles = recipeScores.entries
        .sorted((a, b) => b.value.compareTo(a.value))
        .map((e) => e.key)
        .where((title) =>
            title.toLowerCase() != currentTitle.toLowerCase() &&
            !recipesContainingExcluded.contains(title)) // FILTER OUT excluded
        .take(30)
        .toList();

    if (!mounted) return;
    Navigator.pop(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RecipeResultsSheet(
        recipeTitles: rankedTitles,
        usedIngredients: available,
        excludedIngredients: nowExcluded, // pass accumulated set forward
      ),
    );
  } catch (e) {
    debugPrint("Ingredient search error: $e");
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Search failed: $e")),
      );
    }
  } finally {
    if (mounted) setState(() => _isSearching = false);
  }
}

  @override
  Widget build(BuildContext context) {
    final ingredients = RecipeDetailPage._ensureList(widget.recipe['ingredients']);
    final directions  = RecipeDetailPage._ensureList(widget.recipe['directions']);
    final cleanIngredients = RecipeDetailPage._ensureList(
      widget.recipe['clean_ingredients'],
    ).map((e) => e.toString()).toList();

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
                width: 40, height: 4,
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
                    widget.recipe['title'] ?? 'Recipe',
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

            // ── Ingredients ──────────────────────────────────────
            Text('Ingredients',
                style: GoogleFonts.raleway(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),

            // Only show the checkbox UI when we have clean_ingredients to map against
            if (cleanIngredients.isNotEmpty) ...[
              Text(
                "Tap an ingredient to cross off what you don't have.",
                style: GoogleFonts.raleway(
                    fontSize: 12, color: Colors.grey[500]),
              ),
              const SizedBox(height: 8),
              ...List.generate(cleanIngredients.length, (i) {
  final cleanIng = cleanIngredients[i];
  // full measured ingredient at same index, fallback to clean if missing
  final displayIng = i < ingredients.length
      ? ingredients[i].toString()
      : cleanIng;
  final haveIt = _have[cleanIng] ?? true;

  return InkWell(
    onTap: () => setState(() => _have[cleanIng] = !haveIt),
    borderRadius: BorderRadius.circular(8),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 22, height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: haveIt ? Colors.green[700] : Colors.transparent,
              border: Border.all(
                color: haveIt ? Colors.green[700]! : Colors.grey[400]!,
                width: 2,
              ),
            ),
            child: haveIt
                ? const Icon(Icons.check, size: 13, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              displayIng, // <-- shows "1 cup chicken broth" etc.
              style: GoogleFonts.raleway(
                fontSize: 14,
                color: haveIt ? Colors.black87 : Colors.grey[400],
                decoration: haveIt
                    ? TextDecoration.none
                    : TextDecoration.lineThrough,
              ),
            ),
          ),
          if (!haveIt)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text("missing",
                  style: GoogleFonts.raleway(
                      fontSize: 10,
                      color: Colors.red[400],
                      fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    ),
  );
}),

              const SizedBox(height: 12),

              // "Find recipes" button — only shows if something is crossed off
              if (_have.values.any((v) => !v))
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSearching ? null : _searchWithAvailable,
                    icon: _isSearching
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.search, color: Colors.white, size: 18),
                    label: Text(
                      _isSearching
                          ? "Searching..."
                          : "Search again",
                      style: GoogleFonts.raleway(
                          fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color.fromARGB(255, 195, 88, 17),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
            ] else ...[
              // Fallback: plain bullet list when no clean_ingredients field
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
            ],

            const SizedBox(height: 20),

            // ── Directions ───────────────────────────────────────
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
                      child: Text('${entry.key + 1}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 11)),
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
// ---------------------------------------------------------------------------
// Results sheet — shows recipe titles that matched the ingredient intersection
// ---------------------------------------------------------------------------
 
class _RecipeResultsSheet extends StatelessWidget {
  final List<String> recipeTitles;
  final List<String> usedIngredients;
  final Set<String> excludedIngredients;
 
  const _RecipeResultsSheet({
    required this.recipeTitles,
    required this.usedIngredients,
    required this.excludedIngredients,
  });
  String recipeIdFromTitle(String title) {
  return title.toLowerCase().trim()
      .replaceAll(RegExp(r'''[*"'()]'''), '')
      .replaceAll(' ', '_');
}
 
  // Converts a recipe title back to a display-friendly form
  String _formatTitle(String raw) {
    return raw.replaceAll('_', ' ');
  }
 
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                Row(
            children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios,
                color: Color.fromARGB(255, 195, 88, 17)),
            onPressed: () => Navigator.of(context).popUntil(
              (route) => route.isFirst,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          Text(
            recipeTitles.isEmpty ? "No matches found" : "Recipes Found",
            style: GoogleFonts.raleway(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color.fromARGB(255, 154, 67, 208),
            ),
          ),
        ],
      ),
            const SizedBox(height: 12),
            const Divider(),
 
            if (recipeTitles.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off,
                          size: 48, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      Text(
                        "No recipes match all\nyour available ingredients.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.raleway(
                          color: Colors.grey[500],
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Try unchecking a few more ingredients.",
                        style: GoogleFonts.raleway(
                          color: Colors.grey[400],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: recipeTitles.length,
                  itemBuilder: (context, index) {
                    final title = recipeTitles[index];
                    return ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 4),
                      leading: const CircleAvatar(
                        backgroundColor:
                            Color.fromARGB(255, 195, 88, 17),
                        radius: 14,
                        child: Icon(Icons.restaurant_menu,
                            size: 14, color: Colors.white),
                      ),
                      title: Text(
                        _formatTitle(title),
                        style: GoogleFonts.raleway(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onTap: () {
                        final recipeId = recipeIdFromTitle(title);
                        RecipeDetailPage.show(
                        context,
                        {'id': recipeId, 'title': _formatTitle(title)},
                        excludedIngredients: excludedIngredients,
                      );
                    },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
 
