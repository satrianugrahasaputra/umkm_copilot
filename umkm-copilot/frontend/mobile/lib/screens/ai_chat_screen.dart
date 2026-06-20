import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:async';

import '../providers/chat_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/auth_provider.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> with TickerProviderStateMixin {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  
  // Local edit states
  bool _isEditingTransaction = false;
  final _productEditController = TextEditingController();
  final _qtyEditController = TextEditingController();
  final _amountEditController = TextEditingController();
  String _typeEditValue = 'income';

  // Voice recording mock states
  bool _isRecording = false;
  double _waveformScale = 1.0;
  Timer? _recordingTimer;
  Timer? _waveformTimer;

  @override
  void initState() {
    super.initState();
    // Pre-populate chat with the mockup conversation if empty
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      if (chatProvider.messages.isEmpty) {
        chatProvider.messages.add(ChatMessage(
          sender: 'assistant',
          content: 'Halo! Saya Copilot UMKM Anda. Silakan ketik atau gunakan tombol suara di bawah untuk mencatat penjualan hari ini!',
          timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        ));
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _productEditController.dispose();
    _qtyEditController.dispose();
    _amountEditController.dispose();
    _recordingTimer?.cancel();
    _waveformTimer?.cancel();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();
    FocusScope.of(context).unfocus();
    
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    await chatProvider.sendMessage(text);
    _scrollToBottom();
  }

  void _startEditing(Map<String, dynamic> data) {
    setState(() {
      _isEditingTransaction = true;
      _productEditController.text = data['product'] ?? '';
      _qtyEditController.text = (data['qty'] ?? 1).toString();
      _amountEditController.text = (data['amount'] ?? 0.0).toStringAsFixed(0);
      _typeEditValue = data['type'] ?? 'income';
    });
  }

  void _submitConfirmation() async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final qty = int.tryParse(_qtyEditController.text) ?? 1;
    final amount = double.tryParse(_amountEditController.text) ?? 0.0;

    final Map<String, dynamic> dataToConfirm = {
      'product': _productEditController.text.trim(),
      'qty': qty,
      'type': _typeEditValue,
      'amount': amount,
      'description': 'Pencatatan $qty ${_productEditController.text} via AI Chat'
    };

    final success = await chatProvider.confirmTransaction(dataToConfirm);
    if (success && mounted) {
      setState(() {
        _isEditingTransaction = false;
      });
      Provider.of<DashboardProvider>(context, listen: false).fetchDashboard();
      _scrollToBottom();
    }
  }

  // Simulate Mic Voice input recording with micro-animations
  void _startVoiceRecording() {
    setState(() {
      _isRecording = true;
      _waveformScale = 1.0;
    });

    // Animate wave lines
    _waveformTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (mounted) {
        setState(() {
          _waveformScale = 0.6 + (timer.tick % 4) * 0.15;
        });
      }
    });

    // Auto-generate text after listening
    _recordingTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() {
          _isRecording = false;
          _messageController.text = 'Jual 10 Kopi Susu Aren dan 2 Roti Bakar';
        });
        _waveformTimer?.cancel();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Suara berhasil direkam! Klik kirim untuk mencatat.'),
            duration: Duration(seconds: 2),
            backgroundColor: Color(0xFF16A34A),
          ),
        );
      }
    });
  }

  void _cancelVoiceRecording() {
    _recordingTimer?.cancel();
    _waveformTimer?.cancel();
    setState(() {
      _isRecording = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    final businessName = authProvider.userProfile?['business_name'] ?? 'Warung Anda';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Row(
          children: [
            CircleAvatar(
              backgroundColor: Color(0xFFEFF6FF),
              child: Icon(Icons.auto_awesome, color: Color(0xFF0284C7), size: 20),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tanya Copilot AI',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                Text(
                  'Asisten Keuangan Online',
                  style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Color(0xFF64748B)),
            onPressed: () {
              chatProvider.clearChat();
            },
            tooltip: 'Hapus Chat',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Chat message stream
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  itemCount: chatProvider.messages.length,
                  itemBuilder: (context, index) {
                    final msg = chatProvider.messages[index];
                    final isUser = msg.sender == 'user';
                    return _buildMessageBubble(msg, isUser, theme);
                  },
                ),
              ),

              // Suggestion Quick Pills (visible when no pending extraction)
              if (chatProvider.pendingTransactionData == null && !_isRecording)
                _buildSuggestionPills(theme),

              // Virtual Receipt Card (Invoking structural "Struk" pattern)
              if (chatProvider.pendingTransactionData != null && !_isRecording)
                _buildVirtualReceiptCard(chatProvider, businessName, theme),

              // Loader
              if (chatProvider.isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  ),
                ),

              // Chat Input Row
              if (!_isRecording) _buildInputRow(theme),
            ],
          ),

          // Glow Recording Overlay screen
          if (_isRecording) _buildRecordingOverlay(theme),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, bool isUser, ThemeData theme) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        decoration: BoxDecoration(
          gradient: isUser
              ? const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF0284C7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isUser ? null : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: isUser ? null : Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 6,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Text(
          msg.content,
          style: TextStyle(
            color: isUser ? Colors.white : const Color(0xFF334155),
            fontSize: 13.5,
            height: 1.45,
            fontWeight: isUser ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionPills(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _buildPillButton('Catat: "Es Teh 10 cup"', () {
              _messageController.text = 'Saya menjual 10 cup es teh manis seharga 60.000 rupiah';
            }, theme),
            const SizedBox(width: 8),
            _buildPillButton('Beli Gas: "Habis Rp22.000"', () {
              _messageController.text = 'Beli gas elpiji 3kg seharga 22.000 untuk modal dapur';
            }, theme),
            const SizedBox(width: 8),
            _buildPillButton('Stok Produk', () {
              _messageController.text = 'Bagaimana status stok produk saya saat ini?';
            }, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildPillButton(String label, VoidCallback onTap, ThemeData theme) {
    return ActionChip(
      onPressed: onTap,
      backgroundColor: Colors.white,
      label: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
      ),
      side: const BorderSide(color: Color(0xFFE2E8F0)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  // Virtual Receipt Visual Component matching standard "Struk" specs
  Widget _buildVirtualReceiptCard(ChatProvider chatProvider, String businessName, ThemeData theme) {
    final data = chatProvider.pendingTransactionData!;
    final price = (data['amount'] ?? 0.0).toDouble();
    final qty = data['qty'] ?? 1;
    final isIncome = data['type'] == 'income' || data['type'] == 'pemasukan';

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFCBD5E1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Receipt Top Banner Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isIncome ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(19),
                topRight: Radius.circular(19),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isIncome ? Icons.check_circle_outline : Icons.shopping_basket_outlined,
                      color: isIncome ? const Color(0xFF16A34A) : const Color(0xFFEF4444),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isIncome ? 'Draf Penjualan' : 'Draf Pengeluaran',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        color: isIncome ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                      ),
                    ),
                  ],
                ),
                Text(
                  'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isIncome ? const Color(0xFF15803D).withOpacity(0.6) : const Color(0xFFB91C1C).withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!_isEditingTransaction) ...[
                  // Business Detail name
                  Center(
                    child: Text(
                      businessName.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF475569)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Item Table header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${qty}x ${data['product']}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                      ),
                      Text(
                        'Rp ${NumberFormat('#,###').format(price)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 12),
                  
                  // Total row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Transaksi',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF64748B)),
                      ),
                      Text(
                        'Rp ${NumberFormat('#,###').format(price)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Actions Buttons row
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _startEditing(data),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                          child: const Text('Ubah Data', style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _submitConfirmation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isIncome ? const Color(0xFF16A34A) : const Color(0xFF0056C6),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Simpan & Catat', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: () => chatProvider.cancelPendingTransaction(),
                      child: const Text(
                        'Batalkan Catatan',
                        style: TextStyle(color: Color(0xFFEF4444), fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ] else ...[
                  // Receipt interactive Form editor
                  const Text('UBAH DATA TRANSAKSI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF64748B))),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _productEditController,
                    decoration: const InputDecoration(labelText: 'Nama Produk / Keterangan', isDense: true),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _qtyEditController,
                          decoration: const InputDecoration(labelText: 'Jumlah', isDense: true),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _amountEditController,
                          decoration: const InputDecoration(labelText: 'Total Harga (Rp)', isDense: true),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setState(() => _isEditingTransaction = false),
                          style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                          child: const Text('Kembali', style: TextStyle(color: Color(0xFF475569))),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _submitConfirmation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0056C6),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Konfirmasi'),
                        ),
                      )
                    ],
                  )
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputRow(ThemeData theme) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Voice Dictate Microphone button
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: IconButton(
                icon: const Icon(Icons.mic, color: Color(0xFF0284C7)),
                onPressed: _startVoiceRecording,
                tooltip: 'Gunakan Suara',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Tanya atau catat penjualan...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: const Color(0xFF0F172A),
              child: IconButton(
                icon: const Icon(Icons.arrow_upward, color: Colors.white, size: 18),
                onPressed: _send,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Voice recording layout overlay (Micro-animations)
  Widget _buildRecordingOverlay(ThemeData theme) {
    return Positioned.fill(
      child: Container(
        color: const Color(0xFF0F172A).withOpacity(0.95), // Premium dark translucent overlay
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_awesome, color: Color(0xFF0284C7), size: 36),
            const SizedBox(height: 24),
            const Text(
              'Menyimak Suara Anda...',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Dekatkan ponsel dan bicaralah secara natural.',
              style: TextStyle(color: Colors.white60, fontSize: 13),
            ),
            const SizedBox(height: 56),

            // Pulsing Audio Wave Visualizer representation
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                double height = 24.0 + (index % 3 == 0 ? 32.0 : 12.0);
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 6,
                  height: height * _waveformScale,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),

            const SizedBox(height: 56),
            ElevatedButton.icon(
              onPressed: _cancelVoiceRecording,
              icon: const Icon(Icons.close, size: 16),
              label: const Text('Batal'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
