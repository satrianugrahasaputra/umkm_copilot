import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ChatMessage {
  final String sender;
  final String content;
  final DateTime timestamp;

  ChatMessage({
    required this.sender,
    required this.content,
    required this.timestamp,
  });
}

class ChatProvider with ChangeNotifier {
  List<ChatMessage> _messages = [];
  int? _activeSessionId;
  bool _isLoading = false;
  
  // Staging state for confirmations
  int? _pendingExtractionId;
  Map<String, dynamic>? _pendingTransactionData;

  List<ChatMessage> get messages => _messages;
  int? get activeSessionId => _activeSessionId;
  bool get isLoading => _isLoading;
  int? get pendingExtractionId => _pendingExtractionId;
  Map<String, dynamic>? get pendingTransactionData => _pendingTransactionData;

  Future<void> fetchSessionHistory() async {
    if (_activeSessionId == null) return;
    try {
      final response = await ApiService.get('/api/chat/sessions/$_activeSessionId');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _messages = (data['messages'] as List).map((m) {
          return ChatMessage(
            sender: m['sender'],
            content: m['content'],
            timestamp: DateTime.parse(m['timestamp']),
          );
        }).toList();
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> sendMessage(String text) async {
    _isLoading = true;
    _messages.add(ChatMessage(
      sender: 'user',
      content: text,
      timestamp: DateTime.now(),
    ));
    notifyListeners();

    try {
      final response = await ApiService.post('/api/chat/parse-transaction', {
        'text': text,
        'session_id': _activeSessionId,
      });

      _isLoading = false;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _activeSessionId = data['session_id'];
        _pendingExtractionId = data['extraction_id'];
        _pendingTransactionData = data['extracted_data'];
        
        // Add AI response message to screen
        final extracted = data['extracted_data'];
        final String formattedAmount = (extracted['amount'] ?? 0.0).toStringAsFixed(0);
        final assistantText = 
            'Konfirmasi Transaksi:\n'
            '• Produk: ${extracted['product']}\n'
            '• Jumlah: ${extracted['qty']}\n'
            '• Tipe: ${extracted['type'] == 'income' ? 'Penjualan' : 'Pembelian'}\n'
            '• Total: Rp $formattedAmount\n\n'
            'Apakah data transaksi ini sudah benar?';

        _messages.add(ChatMessage(
          sender: 'assistant',
          content: assistantText,
          timestamp: DateTime.now(),
        ));
        notifyListeners();
      } else {
        _messages.add(ChatMessage(
          sender: 'assistant',
          content: 'Maaf, saya mengalami kendala teknis saat mencoba memproses pesan Anda.',
          timestamp: DateTime.now(),
        ));
        notifyListeners();
      }
    } catch (e) {
      _isLoading = false;
      _messages.add(ChatMessage(
        sender: 'assistant',
        content: 'Gangguan jaringan. Silakan periksa koneksi internet Anda.',
        timestamp: DateTime.now(),
      ));
      notifyListeners();
    }
  }

  Future<bool> confirmTransaction(Map<String, dynamic> confirmedData) async {
    if (_pendingExtractionId == null) return false;
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.post('/api/chat/confirm-transaction', {
        'extraction_id': _pendingExtractionId,
        'confirmed_data': confirmedData,
      });

      _isLoading = false;
      if (response.statusCode == 200) {
        _messages.add(ChatMessage(
          sender: 'assistant',
          content: '✓ Transaksi berhasil dicatat dan dashboard Anda telah diperbarui!',
          timestamp: DateTime.now(),
        ));
        _pendingExtractionId = null;
        _pendingTransactionData = null;
        notifyListeners();
        return true;
      }
    } catch (_) {}
    
    _isLoading = false;
    notifyListeners();
    return false;
  }

  void cancelPendingTransaction() {
    _pendingExtractionId = null;
    _pendingTransactionData = null;
    _messages.add(ChatMessage(
      sender: 'assistant',
      content: 'Pencatatan transaksi dibatalkan. Ada yang bisa saya bantu lagi?',
      timestamp: DateTime.now(),
    ));
    notifyListeners();
  }

  void clearChat() {
    _messages.clear();
    _activeSessionId = null;
    _pendingExtractionId = null;
    _pendingTransactionData = null;
    notifyListeners();
  }
}
