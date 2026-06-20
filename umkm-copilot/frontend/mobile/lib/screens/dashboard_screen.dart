import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/dashboard_provider.dart';
import '../providers/auth_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DashboardProvider>(context, listen: false).fetchDashboard();
    });
  }

  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    final dashboardProvider = Provider.of<DashboardProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    
    final data = dashboardProvider.dashboardData;
    final businessName = authProvider.userProfile?['business_name'] ?? 'Warung Anda';

    // Dates & Greetings
    final nowStr = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(DateTime.now());

    // Mock trend points for the custom sparkline chart
    final List<double> mockTrendPoints = [1200000, 1400000, 950000, 1500000, 1100000, 1300000, data?['revenue']?.toDouble() ?? 1250000.0];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: dashboardProvider.isLoading && data == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => dashboardProvider.fetchDashboard(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Premium Gradient Banner Top Section
                    Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF0F172A), Color(0xFF0284C7)], // Deep slate to ocean blue
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(28),
                          bottomRight: Radius.circular(28),
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 56, 20, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.storefront, color: Colors.white, size: 22),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        businessName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                      Text(
                                        'Juragan Kuliner',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.7),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.notifications_none_outlined, color: Colors.white),
                                  onPressed: () {},
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),
                          Text(
                            nowStr,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Selamat Datang Kembali!',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),

                          // 1. Premium Total Omzet Card (Overlap effect)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0F172A).withOpacity(0.03),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                )
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'TOTAL OMZET HARI INI',
                                      style: TextStyle(
                                        color: const Color(0xFF64748B),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        '7 HARI TERAKHIR',
                                        style: TextStyle(
                                          color: Color(0xFF475569),
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            currencyFormatter.format(data?['revenue'] ?? 1250000),
                                            style: const TextStyle(
                                              fontSize: 26,
                                              fontWeight: FontWeight.w900,
                                              color: Color(0xFF0F172A),
                                              letterSpacing: -0.5,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              const Icon(Icons.arrow_upward, size: 14, color: Color(0xFF22C55E)),
                                              const SizedBox(width: 2),
                                              const Text(
                                                '+12%',
                                                style: TextStyle(
                                                  color: Color(0xFF22C55E),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                '•  ${data?['transaction_count'] ?? 42} Transaksi',
                                                style: const TextStyle(
                                                  color: Color(0xFF64748B),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Custom Painted Sparkline Chart
                                    SalesTrendSparkline(dataPoints: mockTrendPoints),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // 2. Quick Actions Grid (Polished, Premium Design)
                          const Text(
                            'Menu Cepat',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildQuickActionItem(
                                context,
                                label: 'Tanya AI',
                                icon: Icons.chat_bubble_outline,
                                route: '/chat',
                                color: const Color(0xFF0284C7), // Sky Blue
                              ),
                              _buildQuickActionItem(
                                context,
                                label: 'Promosi',
                                icon: Icons.campaign_outlined,
                                route: '/marketing',
                                color: const Color(0xFFD97706), // Amber
                              ),
                              _buildQuickActionItem(
                                context,
                                label: 'Laporan',
                                icon: Icons.bar_chart_outlined,
                                route: '/reports',
                                color: const Color(0xFF16A34A), // Green
                              ),
                              _buildQuickActionItem(
                                context,
                                label: 'Produk',
                                icon: Icons.shopping_bag_outlined,
                                route: '/profile',
                                color: const Color(0xFF7C3AED), // Purple
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // 3. Copilot AI Insight Card (Modern Glassmorphic look)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFBFDBFE)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.auto_awesome, color: Color(0xFF0284C7), size: 16),
                                    ),
                                    const SizedBox(width: 10),
                                    const Text(
                                      'Analisis Copilot',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E3A8A)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  data?['ai_insight'] ??
                                      'Stok Ayam Potong Anda menipis (sisa 5 porsi). Penjualan "Ayam Geprek" sedang tinggi hari ini. Saran: Restock segera untuk besok.',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF1E40AF),
                                    height: 1.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () => Navigator.pushNamed(context, '/chat'),
                                  icon: const Icon(Icons.arrow_forward, size: 14),
                                  label: const Text('Konsultasi AI'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFF0056C6),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    side: const BorderSide(color: Color(0xFFBFDBFE)),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  ),
                                )
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // 4. Produk Terlaris
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Produk Terlaris',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pushNamed(context, '/profile'),
                                child: const Text('Kelola', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
                              )
                            ],
                          ),
                          const SizedBox(height: 8),

                          if (data?['top_product'] != null)
                            _buildTopProductItem(
                              data!['top_product']['name'] ?? 'Ayam Geprek',
                              (data['top_product']['price'] ?? 20000).toDouble(),
                              data['top_product']['sales_count'] ?? 25,
                              theme,
                            )
                          else ...[
                            _buildTopProductItem('Ayam Geprek Spesial', 25000, 24, theme),
                            _buildTopProductItem('Es Teh Manis', 6000, 38, theme),
                          ],
                          const SizedBox(height: 24),

                          // 5. Transaksi Terbaru
                          const Text(
                            'Transaksi Terbaru',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                          ),
                          const SizedBox(height: 12),
                          if (data?['recent_transactions'] != null && (data?['recent_transactions'] as List).isNotEmpty)
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: (data?['recent_transactions'] as List).length,
                              itemBuilder: (context, index) {
                                final tx = data!['recent_transactions'][index];
                                return _buildTransactionItem(tx, theme);
                              },
                            )
                          else
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.receipt_long_outlined, color: Colors.grey[300], size: 40),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Belum ada transaksi hari ini',
                                    style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w500),
                                  )
                                ],
                              ),
                            ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Tanya AI'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Laporan'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profil'),
        ],
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          if (index == 1) Navigator.pushNamed(context, '/chat');
          if (index == 2) Navigator.pushNamed(context, '/reports');
          if (index == 3) Navigator.pushNamed(context, '/profile');
        },
      ),
    );
  }

  Widget _buildQuickActionItem(
    BuildContext context, {
    required String label,
    required IconData icon,
    required String route,
    required Color color,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, route),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: Color(0xFF334155),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopProductItem(String name, double price, int salesCount, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.fastfood_outlined, color: Color(0xFF0284C7)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 4),
                Text(
                  currencyFormatter.format(price),
                  style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$salesCount Terjual',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Color(0xFF16A34A)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTransactionItem(dynamic tx, ThemeData theme) {
    final double amt = (tx['amount'] ?? 0).toDouble();
    final bool isIncome = tx['type'] == 'income' || tx['type'] == 'pemasukan';
    final DateTime time = DateTime.tryParse(tx['timestamp'] ?? '') ?? DateTime.now();
    final timeStr = DateFormat('HH:mm').format(time);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isIncome ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isIncome ? Icons.arrow_downward : Icons.arrow_upward,
              color: isIncome ? const Color(0xFF16A34A) : const Color(0xFFEF4444),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx['description'] ?? (isIncome ? 'Penjualan' : 'Pengeluaran'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  timeStr,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
          Text(
            (isIncome ? '+' : '-') + currencyFormatter.format(amt),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: isIncome ? const Color(0xFF16A34A) : const Color(0xFFEF4444),
            ),
          )
        ],
      ),
    );
  }
}

// Custom Sparkline Painter Widget
class SalesTrendSparkline extends StatelessWidget {
  final List<double> dataPoints;
  const SalesTrendSparkline({super.key, required this.dataPoints});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(100, 36),
      painter: _SparklinePainter(dataPoints),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> dataPoints;
  _SparklinePainter(this.dataPoints);

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.length < 2) return;
    
    final paintLine = Paint()
      ..color = const Color(0xFF16A34A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final paintArea = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF16A34A).withOpacity(0.18),
          const Color(0xFF16A34A).withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final pathLine = Path();
    final pathArea = Path();

    final maxVal = dataPoints.reduce((a, b) => a > b ? a : b);
    final minVal = dataPoints.reduce((a, b) => a < b ? a : b);
    final range = maxVal - minVal == 0 ? 1.0 : maxVal - minVal;

    final double widthStep = size.width / (dataPoints.length - 1);

    for (int i = 0; i < dataPoints.length; i++) {
      final double x = i * widthStep;
      final double normalizedY = (dataPoints[i] - minVal) / range;
      final double y = size.height - (normalizedY * size.height * 0.7) - (size.height * 0.15);

      if (i == 0) {
        pathLine.moveTo(x, y);
        pathArea.moveTo(x, size.height);
        pathArea.lineTo(x, y);
      } else {
        pathLine.lineTo(x, y);
        pathArea.lineTo(x, y);
      }
      
      if (i == dataPoints.length - 1) {
        pathArea.lineTo(x, size.height);
        pathArea.close();
      }
    }

    canvas.drawPath(pathArea, paintArea);
    canvas.drawPath(pathLine, paintLine);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
