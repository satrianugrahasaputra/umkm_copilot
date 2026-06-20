import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';

class MarketingScreen extends StatefulWidget {
  const MarketingScreen({super.key});

  @override
  State<MarketingScreen> createState() => _MarketingScreenState();
}

class _MarketingScreenState extends State<MarketingScreen> {
  final _topicController = TextEditingController();
  final _productController = TextEditingController();
  String _selectedPlatform = 'instagram';
  String _selectedTone = 'friendly';

  bool _isLoading = false;
  String? _generatedResult;
  List<dynamic> _pastContents = [];

  @override
  void initState() {
    super.initState();
    _fetchPastContents();
    _topicController.text = 'Promo Kopi Gayo Beli 2 Gratis 1 di sore hari';
    _productController.text = 'Kopi Susu Aren';
  }

  @override
  void dispose() {
    _topicController.dispose();
    _productController.dispose();
    super.dispose();
  }

  Future<void> _fetchPastContents() async {
    try {
      final response = await ApiService.get('/api/marketing');
      if (response.statusCode == 200) {
        setState(() {
          _pastContents = jsonDecode(response.body);
        });
      }
    } catch (_) {}
  }

  void _generate() async {
    setState(() {
      _isLoading = true;
      _generatedResult = null;
    });

    try {
      final response = await ApiService.post('/api/marketing/generate', {
        'platform': _selectedPlatform,
        'topic': _topicController.text.trim(),
        'product_name': _productController.text.trim().isEmpty ? null : _productController.text.trim(),
        'tone': _selectedTone,
      });

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        setState(() {
          _generatedResult = data['generated_content'];
        });
        _fetchPastContents();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal membuat konten pemasaran. Coba lagi.')),
        );
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masalah jaringan. Gagal menghubungi server.')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Row(
          children: [
            CircleAvatar(
              backgroundColor: Color(0xFFFEF3C7),
              child: Icon(Icons.campaign_outlined, color: Color(0xFFD97706), size: 20),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Buat Promosi AI',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                Text(
                  'Karya Tulis Otomatis',
                  style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Configurations Form Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.015),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nama Produk',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _productController,
                    decoration: const InputDecoration(
                      hintText: 'Contoh: Kopi Susu Aren / Nasi Goreng',
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 18),

                  const Text(
                    'Pilih Platform Sosmed',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildPlatformCard('instagram', Icons.camera_alt_outlined, 'Instagram', const Color(0xFFDB2777)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildPlatformCard('whatsapp', Icons.chat_bubble_outline_outlined, 'WhatsApp', const Color(0xFF16A34A)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildPlatformCard('marketplace', Icons.storefront_outlined, 'Marketplace', const Color(0xFFEA580C)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  const Text(
                    'Gaya Bahasa (Tone)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildTonePill('friendly', 'Santai & Akrab'),
                        const SizedBox(width: 8),
                        _buildTonePill('formal', 'Profesional'),
                        const SizedBox(width: 8),
                        _buildTonePill('funny', 'Humor / Lucu'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  const Text(
                    'Detail Penawaran / Promo',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _topicController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'Tuliskan detail diskon atau promosi...',
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 24),

                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _generate,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F172A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Buat Caption AI', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Generation Output Display
            if (_generatedResult != null) ...[
              const Text(
                'Konten Siap Pakai',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(
                      _generatedResult!,
                      style: const TextStyle(fontSize: 13.5, height: 1.5, color: Color(0xFF334155)),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _generatedResult!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Konten berhasil disalin!')),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEFF6FF),
                          foregroundColor: const Color(0xFF0056C6),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('Salin Teks Caption', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Past contents log history list
            if (_pastContents.isNotEmpty) ...[
              const Text(
                'Riwayat Konten Promosi',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _pastContents.length,
                itemBuilder: (context, index) {
                  final log = _pastContents[index];
                  final String platform = log['platform'] ?? 'Instagram';
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                platform.toUpperCase(),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Color(0xFF475569)),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy, size: 16, color: Colors.grey),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: log['generated_content'] ?? ''));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Konten berhasil disalin!')),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          log['topic'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          log['generated_content'] ?? '',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformCard(String id, IconData icon, String label, Color color) {
    final isSelected = _selectedPlatform == id;
    return InkWell(
      onTap: () => setState(() => _selectedPlatform = id),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : Colors.grey[400], size: 22),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isSelected ? color : const Color(0xFF475569),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTonePill(String id, String label) {
    final isSelected = _selectedTone == id;
    return InkWell(
      onTap: () => setState(() => _selectedTone = id),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}
