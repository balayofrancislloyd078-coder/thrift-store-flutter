// lib/pages/items_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/supabase_service.dart';
import '../../models/item.dart';

class ItemsPage extends StatefulWidget {
  const ItemsPage({super.key});
  @override
  ItemsPageState createState() => ItemsPageState();
}

class ItemsPageState extends State<ItemsPage> {
  late Future<List<Item>> _fetchFuture;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() {
    final svc = Provider.of<SupabaseService>(context, listen: false);
    _fetchFuture = svc.fetchItems().then((_) => svc.items);
  }

  Future<void> _refresh() async {
    _loadItems();
    await _fetchFuture;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final svc = Provider.of<SupabaseService>(context, listen: false);
    final currentEmail = Supabase.instance.client.auth.currentUser?.email;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E3C72), Color(0xFF2A5298)], // Deep ocean blue gradient
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Francis Lloyd Store🛍️',
            style: GoogleFonts.montserrat(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.1,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: () async {
                await svc.signOut();
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/signin', (_) => false);
              },
            ),
          ],
        ),
        body: SafeArea(
          child: RefreshIndicator(
            color: Colors.cyanAccent,
            onRefresh: _refresh,
            child: FutureBuilder<List<Item>>(
              future: _fetchFuture,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.cyanAccent),
                  );
                }
                if (snap.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snap.error}',
                      style: GoogleFonts.montserrat(
                        color: Colors.redAccent,
                        fontSize: 16,
                      ),
                    ),
                  );
                }

                final items = snap.data!;
                if (items.isEmpty) {
                  return Center(
                    child: Text(
                      'No treasures yet 🧐',
                      style: GoogleFonts.montserrat(
                        color: Colors.white70,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }

                return GridView.builder(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final item = items[i];
                    final isOwner = item.uploaderEmail == currentEmail;

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          // Image
                          Expanded(
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: Hero(
                                    tag: 'item-image-${item.id}',
                                    child: Image.network(
                                      item.imageUrl,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                if (isOwner)
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      child: IconButton(
                                        icon: const Icon(Icons.delete, size: 20),
                                        color: Colors.white,
                                        onPressed: () async {
                                          await svc.deleteItem(item.id);
                                          await _refresh();
                                        },
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // Details
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF1E3C72),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '₱ ${item.price.toStringAsFixed(2)}',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF00B4D8),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'By ${item.uploadedBy}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                      const Color(0xFF00B4D8), // Cyan accent
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 6,
                                      shadowColor:
                                      Colors.cyanAccent.withOpacity(0.4),
                                    ),
                                    onPressed: () {
                                      Navigator.pushNamed(
                                        context,
                                        '/detail',
                                        arguments: item.id,
                                      );
                                    },
                                    child: Text(
                                      'View Details',
                                      style: GoogleFonts.montserrat(
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),

        // Floating add button
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1E3C72),
          icon: const Icon(Icons.add),
          label: Text(
            'Add New',
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.bold,
            ),
          ),
          onPressed: () async {
            await Navigator.pushNamed(context, '/add');
            await _refresh();
          },
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 10,
        ),
      ),
    );
  }
}
