// lib/pages/item_detail_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/supabase_service.dart';
import '../../models/item.dart';
import '../../widgets/info_chip.dart';
import 'full_screen_image_page.dart';

class ItemDetailPage extends StatelessWidget {
  final int itemId;
  const ItemDetailPage({super.key, required this.itemId});

  @override
  Widget build(BuildContext context) {
    final svc = Provider.of<SupabaseService>(context, listen: false);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF1E3C72),
            Color(0xFF2A5298), // Matches AddItemPage deep blue theme
          ],
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
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Item Details',
            style: GoogleFonts.montserrat(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: FutureBuilder<Item?>(
            future: svc.fetchItemDetail(itemId),
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }

              if (snap.hasError) {
                return Center(
                  child: Text(
                    'Error: ${snap.error}',
                    style: GoogleFonts.poppins(color: Colors.redAccent),
                  ),
                );
              }

              final item = snap.data;
              if (item == null) {
                return Center(
                  child: Text(
                    'Item not found 🤷',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                );
              }

              return Stack(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Hero Image
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FullScreenImagePage(
                                itemId: item.id,
                                imageUrl: item.imageUrl,
                              ),
                            ),
                          ),
                          child: Hero(
                            tag: 'item-image-${item.id}',
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.network(
                                item.imageUrl,
                                height: 280,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Title & Price
                        Text(
                          item.title,
                          style: GoogleFonts.montserrat(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '₱ ${item.price.toStringAsFixed(2)}',
                          style: GoogleFonts.montserrat(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: Colors.cyanAccent,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Description box (glass-like card)
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            border: Border.all(color: Colors.white24),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Description',
                                style: GoogleFonts.montserrat(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.cyanAccent,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item.description,
                                style: GoogleFonts.montserrat(
                                  fontSize: 14,
                                  height: 1.4,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Info Chips
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            InfoChip(icon: Icons.person, text: item.uploadedBy),
                            InfoChip(icon: Icons.contact_mail, text: item.contactInfo),
                            InfoChip(
                              icon: Icons.calendar_today,
                              text:
                              '${item.createdAt.month}/${item.createdAt.day}/${item.createdAt.year}',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Floating Contact Button
                  Positioned(
                    bottom: 24,
                    left: 24,
                    right: 24,
                    child: ElevatedButton(
                      onPressed: () async {
                        final email = item.contactInfo.trim();
                        final subject = Uri.encodeComponent('Inquiry about "${item.title}"');
                        final uri = Uri.parse('mailto:$email?subject=$subject');

                        try {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        } catch (_) {
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              backgroundColor: Colors.white,
                              title: Text(
                                'Contact Owner',
                                style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
                              ),
                              content: SelectableText(
                                email,
                                style: GoogleFonts.montserrat(color: Colors.black87),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('Close',
                                      style: GoogleFonts.montserrat(color: Colors.blueAccent)),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00B4D8), // cyan accent
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 8,
                        shadowColor: Colors.cyanAccent.withOpacity(0.6),
                      ),
                      child: Text(
                        'Contact Owner',
                        style: GoogleFonts.montserrat(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
