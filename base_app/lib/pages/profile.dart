import 'package:base_app/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:base_app/pages/home.dart';
import 'package:base_app/pages/history.dart';
import 'package:base_app/pages/favorites.dart';
import 'package:base_app/pages/grocery_list.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const Color background = Color.fromARGB(255, 222, 209, 182);
  static const Color softMaroon = Color.fromARGB(255, 117, 52, 61);
  static const Color sage = Color.fromARGB(255, 126, 153, 120);

  final List<String> _allRestrictions = [
    'Vegetarian',
    'Vegan',
    'Gluten-Free',
    'Dairy-Free',
    'Nut-Free',
    'Halal',
    'Kosher',
    'Low-Carb',
    'Keto',
    'Paleo',
    'Low-Sodium',
    'Egg-Free',
    'Soy-Free',
    'Shellfish-Free',
  ];

  Set<String> _selectedRestrictions = {};
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadRestrictions();
  }

  Future<void> _loadRestrictions() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (doc.exists) {
      final data = doc.data();
      final saved = List<String>.from(data?['dietaryRestrictions'] ?? []);
      setState(() {
        _selectedRestrictions = saved.toSet();
      });
    }

    setState(() => _isLoading = false);
  }

  Future<void> _saveRestrictions() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'dietaryRestrictions': _selectedRestrictions.toList(),
    }, SetOptions(merge: true));

    setState(() => _isSaving = false);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Dietary preferences saved!")));
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: background,
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [softMaroon, softMaroon],
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
                      color: softMaroon,
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                    ),
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home_outlined, color: softMaroon),
              title: Text(
                'Home',
                style: GoogleFonts.raleway(
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => Home()),
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.favorite_outline_rounded,
                color: softMaroon,
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
              leading: const Icon(Icons.history_outlined, color: softMaroon),
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
                color: softMaroon,
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
              leading: const Icon(Icons.person_outline, color: softMaroon),
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
      appBar: AppBar(
        leadingWidth: 120, // give it more horizontal space
          leading: Builder(
          builder: (context) => GestureDetector(
            onTap: () => Scaffold.of(context).openDrawer(),
            child: Transform.translate(
              offset: const Offset(-22, 0), 
              child: Image.asset(
                'lib/assets/images/replateLogo1.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        title: Text(
          "My Profile",
          style: GoogleFonts.raleway(
            textStyle: const TextStyle(
              color: softMaroon,
              fontWeight: FontWeight.bold,
              fontSize: 34,
            ),
          ),
        ),
        backgroundColor: background,
        elevation: 0,
        iconTheme: const IconThemeData(color: softMaroon),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: softMaroon))
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        child: Text(
                          user?.displayName?.substring(0, 1).toUpperCase() ??
                              'U',
                          style: GoogleFonts.raleway(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: softMaroon,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.displayName ?? 'Chef',
                            style: GoogleFonts.raleway(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: softMaroon,
                            ),
                          ),
                          Text(
                            user?.email ?? '',
                            style: GoogleFonts.raleway(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: sage.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  Text(
                    'Dietary Restrictions',
                    style: GoogleFonts.raleway(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: softMaroon,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Select all that apply to you',
                    style: GoogleFonts.raleway(
                      fontSize: 18,
                      color: softMaroon.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Expanded(
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _allRestrictions.map((restriction) {
                          final isSelected = _selectedRestrictions.contains(
                            restriction,
                          );
                          return FilterChip(
                            label: Text(
                              restriction,
                              style: GoogleFonts.raleway(
                                color: isSelected ? Colors.white : softMaroon,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedRestrictions.add(restriction);
                                } else {
                                  _selectedRestrictions.remove(restriction);
                                }
                              });
                            },
                            backgroundColor: background,
                            selectedColor: sage,
                            checkmarkColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(color: softMaroon),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: 200,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveRestrictions,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: softMaroon,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              "Save Preferences",
                              style: GoogleFonts.raleway(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
