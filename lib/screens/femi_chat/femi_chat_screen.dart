import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../services/femi_agent_service.dart';
import '../../services/femi_api_service.dart';
import 'widgets/continuer_sur_whatsapp_banner.dart';
import 'widgets/chat_date_badge_widget.dart';
import 'widgets/chat_input_bar_widget.dart';
import 'widgets/chat_message_bubble_widget.dart';
import 'widgets/chat_history_drawer_widget.dart';

class FemiChatScreen extends StatefulWidget {
  final String? initialPrompt;
  final int promptNonce;
  final VoidCallback? onBack;

  const FemiChatScreen({
    super.key,
    this.initialPrompt,
    this.promptNonce = 0,
    this.onBack,
  });

  @override
  State<FemiChatScreen> createState() => _FemiChatScreenState();
}

class _FemiChatScreenState extends State<FemiChatScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FemiAgentService _agentService = FemiAgentService();
  final FemiApiService _apiService = FemiApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final ImagePicker _imagePicker = ImagePicker();
  final AudioRecorder _audioRecorder = AudioRecorder();

  bool _isLoading = false;
  bool _isRecording = false;
  bool _isPaused = false;
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer;
  String? _recordingPath;

  File? _selectedImage;
  File? _selectedPdf;

  int? _handledPromptNonce;
  String? _conversationIdActive;

  static const int _messagesParPage = 50;
  bool _chargementAnciensMessages = false;
  bool _peutChargerAnciensMessages = true;
  String? _nextBefore;

  final List<Map<String, dynamic>> _messages = [
    {
      'text':
      'Bonjour ! Je suis Femi. Comment puis-je vous aider aujourd\'hui ?',
      'isUser': false,
      'time': '10:24',
    },
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _checkAuthenticationStatus();
    _chargerConversationRecente();
    _maybeSendInitialPrompt();
  }

  @override
  void didUpdateWidget(covariant FemiChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybeSendInitialPrompt();
  }

  void _maybeSendInitialPrompt() {
    final prompt = widget.initialPrompt;
    if (prompt == null || prompt.trim().isEmpty) return;
    if (_handledPromptNonce == widget.promptNonce) return;

    _handledPromptNonce = widget.promptNonce;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _messageController.text = prompt;
      _sendMessage();
    });
  }

  Future<void> _checkAuthenticationStatus() async {
    final token = await _storage.read(key: 'auth_token') ??
        await _storage.read(key: 'access_token') ??
        await _storage.read(key: 'token');

    if (token == null || token.isEmpty) {
      debugPrint('⚠️ Aucun token au chargement du chat.');
    }
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _messageController.dispose();
    _scrollController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  // ============================================================
  // SCROLL + PAGINATION
  // ============================================================

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_conversationIdActive == null) return;
    if (_chargementAnciensMessages || !_peutChargerAnciensMessages) return;

    if (_scrollController.position.pixels <= 80) {
      _chargerAnciensMessages();
    }
  }

  List<Map<String, dynamic>> _mapApiMessages(List results) {
    final mapped = <Map<String, dynamic>>[];

    for (final raw in results) {
      if (raw is! Map) continue;
      final m = Map<String, dynamic>.from(raw);

      final isUser = m['expediteur']?.toString().toUpperCase() == 'USER';
      final type = m['type_message']?.toString().toUpperCase() ?? 'TEXTE';
      var texte = m['contenu_texte']?.toString();
      final created = m['created_at']?.toString();

      if (texte == null || texte.isEmpty) {
        if (type == 'AUDIO') texte = '[Message vocal]';
        if (type == 'IMAGE') texte = '[Image]';
      }

      mapped.add({
        'id': m['id']?.toString(),
        'text': texte,
        'isUser': isUser,
        'time': _timeFromIso(created),
        'created_at': created,
        'type_message': type,
        'operation_id': m['operation_id'],
      });
    }
    return mapped;
  }

  Future<void> _chargerConversationRecente() async {
    setState(() => _isLoading = true);

    final data = await _apiService.getConversations(limit: 1);
    if (!mounted) return;

    final results = (data?['results'] as List?) ?? [];
    if (results.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    final first = results.first;
    if (first is! Map) {
      setState(() => _isLoading = false);
      return;
    }

    final id = first['id']?.toString();
    if (id == null || id.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    await _ouvrirConversationParId(id);
  }

  // ============================================================
  // HISTORIQUE
  // ============================================================

  void _nouvelleConversation() {
    setState(() {
      _conversationIdActive = null;
      _nextBefore = null;
      _peutChargerAnciensMessages = true;
      _chargementAnciensMessages = false;
      _messages
        ..clear()
        ..add({
          'text':
          'Bonjour ! Je suis Femi. Comment puis-je vous aider aujourd\'hui ?',
          'isUser': false,
          'time': _nowTimeString(),
        });
    });
  }

  Future<void> _ouvrirConversation(ChatHistoryItem item) async {
    await _ouvrirConversationParId(item.id);
  }

  Future<void> _ouvrirConversationParId(String conversationId) async {
    setState(() {
      _isLoading = true;
      _messages.clear();
      _conversationIdActive = conversationId;
      _nextBefore = null;
      _peutChargerAnciensMessages = true;
      _chargementAnciensMessages = false;
    });

    final data = await _apiService.getConversationMessages(
      conversationId,
      limit: _messagesParPage,
    );

    if (!mounted) return;

    if (data == null) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de charger cette conversation.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final results = (data['results'] as List?) ?? [];
    final mapped = _mapApiMessages(results);

    setState(() {
      _messages
        ..clear()
        ..addAll(mapped);
      _nextBefore = data['next_before']?.toString();
      _peutChargerAnciensMessages = data['has_more'] == true;
      _isLoading = false;
    });

    _scrollToBottom();
  }

  Future<void> _chargerAnciensMessages() async {
    final conversationId = _conversationIdActive;
    if (conversationId == null) return;
    if (_chargementAnciensMessages || !_peutChargerAnciensMessages) return;

    final before = _nextBefore;
    if (before == null || before.isEmpty) {
      setState(() => _peutChargerAnciensMessages = false);
      return;
    }

    setState(() => _chargementAnciensMessages = true);

    final oldPixels =
    _scrollController.hasClients ? _scrollController.position.pixels : 0.0;
    final oldMax = _scrollController.hasClients
        ? _scrollController.position.maxScrollExtent
        : 0.0;

    try {
      final data = await _apiService.getConversationMessages(
        conversationId,
        limit: _messagesParPage,
        before: before,
      );

      if (!mounted) return;

      if (data == null) {
        setState(() => _chargementAnciensMessages = false);
        return;
      }

      final results = (data['results'] as List?) ?? [];
      final older = _mapApiMessages(results);

      final existingIds = _messages
          .map((m) => m['id']?.toString())
          .whereType<String>()
          .toSet();
      older.removeWhere((m) {
        final id = m['id']?.toString();
        return id != null && existingIds.contains(id);
      });

      if (older.isEmpty) {
        setState(() {
          _chargementAnciensMessages = false;
          _peutChargerAnciensMessages = data['has_more'] == true;
          _nextBefore = data['next_before']?.toString();
        });
        return;
      }

      setState(() {
        _messages.insertAll(0, older);
        _nextBefore = data['next_before']?.toString();
        _peutChargerAnciensMessages = data['has_more'] == true;
        _chargementAnciensMessages = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollController.hasClients) return;
        final newMax = _scrollController.position.maxScrollExtent;
        final delta = newMax - oldMax;
        _scrollController.jumpTo(
          (oldPixels + delta).clamp(0.0, newMax),
        );
      });
    } catch (e) {
      debugPrint('Erreur anciens messages: $e');
      if (mounted) {
        setState(() => _chargementAnciensMessages = false);
      }
    }
  }

  String _nowTimeString() {
    final now = TimeOfDay.now();
    return '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}';
  }

  String _timeFromIso(String? iso) {
    if (iso == null || iso.length < 16) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso.substring(11, 16);
    }
  }

  // ============================================================
  // IMAGE / PDF
  // ============================================================

  Future<void> _handlePickImage(bool isCamera) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: isCamera ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() => _selectedImage = File(pickedFile.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Impossible de récupérer l\'image : $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handlePickPdf() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
      );

      final path = result?.files.single.path;
      if (path != null) {
        setState(() => _selectedPdf = File(path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Impossible de sélectionner le PDF : $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ============================================================
  // MICRO STYLE WHATSAPP → transcription
  // ============================================================

  void _startRecordingTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isPaused && mounted) {
        setState(() {
          _recordingDuration += const Duration(seconds: 1);
        });
      }
    });
  }

  Future<void> _startRecording() async {
    if (!await _audioRecorder.hasPermission()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permission micro refusée.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final appDocDir = await getApplicationDocumentsDirectory();
    final filePath =
        '${appDocDir.path}/vocal_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _audioRecorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: filePath,
    );

    setState(() {
      _isRecording = true;
      _isPaused = false;
      _recordingDuration = Duration.zero;
      _recordingPath = filePath;
    });
    _startRecordingTimer();
  }

  Future<void> _pauseRecording() async {
    try {
      await _audioRecorder.pause();
      if (mounted) setState(() => _isPaused = true);
    } catch (e) {
      debugPrint('Pause vocal: $e');
    }
  }

  Future<void> _resumeRecording() async {
    try {
      await _audioRecorder.resume();
      if (mounted) setState(() => _isPaused = false);
    } catch (e) {
      debugPrint('Resume vocal: $e');
    }
  }

  Future<void> _cancelRecording() async {
    _recordingTimer?.cancel();
    try {
      await _audioRecorder.stop();
    } catch (_) {}

    final path = _recordingPath;
    if (path != null) {
      final f = File(path);
      if (await f.exists()) {
        await f.delete();
      }
    }

    if (!mounted) return;
    setState(() {
      _isRecording = false;
      _isPaused = false;
      _recordingDuration = Duration.zero;
      _recordingPath = null;
    });
  }

  /// Arrête le vocal → transcription → texte dans le champ.
  Future<void> _sendRecording() async {
    _recordingTimer?.cancel();

    String? path;
    try {
      path = await _audioRecorder.stop();
    } catch (e) {
      debugPrint('Stop vocal: $e');
      path = _recordingPath;
    }

    if (!mounted) return;

    setState(() {
      _isRecording = false;
      _isPaused = false;
      _recordingDuration = Duration.zero;
      _recordingPath = null;
      _isLoading = true;
    });

    if (path == null || path.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final transcription =
      await _agentService.transcribeAudio(File(path));

      if (!mounted) return;

      try {
        final f = File(path);
        if (await f.exists()) await f.delete();
      } catch (_) {}

      if (transcription.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aucune parole détectée. Réessayez.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      setState(() {
        _messageController.text = transcription;
        _messageController.selection = TextSelection.fromPosition(
          TextPosition(offset: transcription.length),
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transcription prête. Vérifiez puis envoyez.'),
          backgroundColor: Color(0xFF006654),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de transcription : $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ============================================================
  // ENVOI
  // ============================================================

  Future<void> _sendMessage({File? audioFile}) async {
    final text = _messageController.text.trim();
    final imageFileToSend = _selectedImage;
    final pdfFileToSend = _selectedPdf;

    if (text.isEmpty &&
        imageFileToSend == null &&
        pdfFileToSend == null &&
        audioFile == null) {
      return;
    }

    final timeString = _nowTimeString();

    final storedToken = await _storage.read(key: 'auth_token') ??
        await _storage.read(key: 'access_token') ??
        await _storage.read(key: 'token');

    if (storedToken == null || storedToken.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Session expirée ou non identifiée. Veuillez vous reconnecter.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    setState(() {
      _messages.add({
        'text': text.isNotEmpty ? text : null,
        'imageFile': imageFileToSend,
        'audioFile': audioFile,
        'pdfFile': pdfFileToSend,
        'isUser': true,
        'time': timeString,
      });
      _isLoading = true;
      _selectedImage = null;
      _selectedPdf = null;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      final response = await _agentService.sendMessage(
        text: text.isNotEmpty ? text : null,
        imageFile: imageFileToSend,
        audioFile: audioFile,
        pdfFile: pdfFileToSend,
      );

      final respTimeString = _nowTimeString();

      setState(() {
        final isTransaction = response['isTransaction'] == true ||
            response['transaction'] != null ||
            response['id'] != null;

        final transactionData = response['transaction'] ?? response;
        final messageText = response['message']?.toString();

        if (isTransaction && response['transaction'] != null) {
          _messages.add({
            'transaction': transactionData,
            'isUser': false,
            'time': respTimeString,
          });
        } else {
          _messages.add({
            'text': messageText ?? 'Message traité avec succès.',
            'isUser': false,
            'time': respTimeString,
          });
        }
      });
    } catch (e) {
      final errorMessage = e.toString();
      if (mounted) {
        if (errorMessage.contains(
          'Authentication credentials were not provided',
        ) ||
            errorMessage.contains('401')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Authentification échouée. Veuillez vous reconnecter.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur : $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildSelectedImagePreview() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              _selectedImage!,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Reçu / Image prête à être envoyée',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red, size: 20),
            onPressed: () => setState(() => _selectedImage = null),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedPdfPreview() {
    final fileName = _selectedPdf!.path.split(Platform.pathSeparator).last;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.picture_as_pdf_rounded,
              color: Colors.red,
              size: 30,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              fileName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red, size: 20),
            onPressed: () => setState(() => _selectedPdf = null),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF7F9FC),
      endDrawer: ChatHistoryDrawerWidget(
        onNouvelleConversation: _nouvelleConversation,
        onSelectionnerConversation: _ouvrirConversation,
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            if (widget.onBack != null) {
              widget.onBack!();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: const Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: AssetImage('assets/images/avatar_neutre.jpeg'),
            ),
            SizedBox(width: 10),
            Text(
              'Femi',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.black87),
            tooltip: 'Historique des discussions',
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          ChatDateBadgeWidget(
            dateText: _conversationIdActive != null
                ? 'Conversation chargée'
                : 'Aujourd\'hui',
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount:
              _messages.length + (_chargementAnciensMessages ? 1 : 0),
              itemBuilder: (context, index) {
                if (_chargementAnciensMessages && index == 0) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }

                final msgIndex =
                _chargementAnciensMessages ? index - 1 : index;
                return ChatMessageBubbleWidget(message: _messages[msgIndex]);
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: LinearProgressIndicator(
                backgroundColor: Color(0xFFE2E8F0),
                color: Color(0xFF006654),
              ),
            ),
          if (_selectedImage != null) _buildSelectedImagePreview(),
          if (_selectedPdf != null) _buildSelectedPdfPreview(),
          const ContinuerSurWhatsappBanner(),
          ChatInputBarWidget(
            controller: _messageController,
            isRecording: _isRecording,
            isPaused: _isPaused,
            recordingDuration: _recordingDuration,
            onSend: () => _sendMessage(),
            onPickImage: _handlePickImage,
            onPickPdf: _handlePickPdf,
            onStartRecording: _startRecording,
            onPauseRecording: _pauseRecording,
            onResumeRecording: _resumeRecording,
            onCancelRecording: _cancelRecording,
            onSendRecording: _sendRecording,
          ),
        ],
      ),
    );
  }
}