import 'package:base_app/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:base_app/pages/home.dart';
import 'package:base_app/pages/history.dart';
import 'package:base_app/pages/favorites.dart';
import 'package:base_app/pages/profile.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
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

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set({
          'dietaryRestrictions': _selectedRestrictions.toList(),
        }, SetOptions(merge: true));

    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Dietary preferences saved!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Color.fromARGB(255, 245, 218, 122),
      drawer: Drawer(
        backgroundColor:Color.fromARGB(255, 248, 247, 245),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [ Color.fromARGB(255, 245, 218, 122), Color.fromARGB(255, 226, 195, 110)],
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
              leading: const Icon(Icons.home_outlined, color:  Color.fromARGB(255, 109, 83, 194)),
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
                MaterialPageRoute(builder: (context) => Home()), // replace HomePage with your actual class name
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.favorite_outline_rounded,
                color:  Color.fromARGB(255, 120, 69, 182),
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
              leading: const Icon(Icons.history_outlined, color:  Color.fromARGB(255, 130, 72, 183)),
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
              leading: const Icon(Icons.person_outline, color:  Color.fromARGB(255, 97, 57, 163)),
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
        title: Text(
          "My Profile",
          style: GoogleFonts.raleway(
            textStyle: const TextStyle(
              color:  Color.fromARGB(255, 236, 110, 31),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        backgroundColor: Color.fromARGB(255, 245, 218, 122),
        elevation: 0,
        iconTheme: const IconThemeData(color:  Color.fromARGB(255, 236, 110, 31)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color:  Color.fromARGB(255, 236, 110, 31)))
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User info header
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: const Color.fromARGB(255, 237, 242, 237),
                        child: Text(
                          user?.displayName?.substring(0, 1).toUpperCase() ?? 'U',
                          style: GoogleFonts.raleway(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: const Color.fromARGB(255, 82, 40, 173),
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
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            user?.email ?? '',
                            style: GoogleFonts.raleway(
                              fontSize: 13,
                              color: Colors.grey,
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
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 236, 110, 31),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Select all that apply to you',
                    style: GoogleFonts.raleway(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Restriction chips
                  Expanded(
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _allRestrictions.map((restriction) {
                          final isSelected = _selectedRestrictions.contains(restriction);
                          return FilterChip(
                            label: Text(
                              restriction,
                              style: GoogleFonts.raleway(
                                color: isSelected ? Colors.white : Color.fromARGB(255, 236, 110, 31),
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
                            backgroundColor: Color.fromARGB(255, 245, 218, 122),
                            selectedColor:  Color.fromARGB(255, 236, 110, 31),
                            checkmarkColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(color:  Color.fromARGB(255, 236, 110, 31)),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveRestrictions,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:  Color.fromARGB(255, 236, 110, 31),
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