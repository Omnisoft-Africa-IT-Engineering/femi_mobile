import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../../services/femi_agent_service.dart';
import 'widgets/chat_date_badge_widget.dart';
import 'widgets/chat_input_bar_widget.dart';
import 'widgets/chat_message_bubble_widget.dart';

class FemiChatScreen extends StatefulWidget {
  const FemiChatScreen({super.key});

  @override
  State<FemiChatScreen> createState() => _FemiChatScreenState();
}

class _FemiChatScreenState extends State<FemiChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FemiAgentService _agentService = FemiAgentService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final ImagePicker _imagePicker = ImagePicker();
  final AudioRecorder _audioRecorder = AudioRecorder();

  bool _isLoading = false;
  bool _isRecording = false;
  File? _selectedImage;

  final List<Map<String, dynamic>> _messages = [
    {
      'text': 'Bonjour ! Je suis Femi. Comment puis-je vous aider aujourd\'hui ?',
      'isUser': false,
      'time': '10:24',
    },
  ];

  @override
  void initState() {
    super.initState();
    _checkAuthenticationStatus();
  }

  /// Vérifie si un token JWT/DRF valide est stocké au chargement de l'écran
  Future<void> _checkAuthenticationStatus() async {
    final token = await _storage.read(key: 'auth_token') ??
        await _storage.read(key: 'access_token') ??
        await _storage.read(key: 'token');

    if (token == null || token.isEmpty) {
      debugPrint('⚠️ Aucune clé d\'authentification trouvée au chargement du chat.');
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  // --- Gestion des images (Caméra / Galerie) ---
  Future<void> _handlePickImage(bool isCamera) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: isCamera ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
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

  // --- Gestion du Micro / Enregistrement Vocal ---
  Future<void> _handleMicToggle() async {
    if (_isRecording) {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
      });
      if (path != null) {
        _sendMessage(audioFile: File(path));
      }
    } else {
      if (await _audioRecorder.hasPermission()) {
        final Directory appDocDir = await getApplicationDocumentsDirectory();
        final String filePath =
            '${appDocDir.path}/vocal_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: filePath,
        );
        setState(() {
          _isRecording = true;
        });
      }
    }
  }

  // --- Envoi du Message ---
  Future<void> _sendMessage({File? audioFile}) async {
    final text = _messageController.text.trim();
    final imageFileToSend = _selectedImage;

    if (text.isEmpty && imageFileToSend == null && audioFile == null) return;

    final now = TimeOfDay.now();
    final timeString =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    // 1. Vérification préalable de la présence du token
    final storedToken = await _storage.read(key: 'auth_token') ??
        await _storage.read(key: 'access_token') ??
        await _storage.read(key: 'token');

    if (storedToken == null || storedToken.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session expirée ou non identifiée. Veuillez vous reconnecter.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // 2. Ajouter immédiatement le message utilisateur dans le chat
    setState(() {
      _messages.add({
        'text': text.isNotEmpty ? text : null,
        'imageFile': imageFileToSend,
        'audioFile': audioFile,
        'isUser': true,
        'time': timeString,
      });
      _isLoading = true;
      _selectedImage = null; // Réinitialiser l'aperçu après envoi
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      // 3. Appel de l'API via le Service HTTP FemiAgentService
      final response = await _agentService.sendMessage(
        text: text.isNotEmpty ? text : null,
        imageFile: imageFileToSend,
        audioFile: audioFile,
      );

      final respTime = TimeOfDay.now();
      final respTimeString =
          '${respTime.hour.toString().padLeft(2, '0')}:${respTime.minute.toString().padLeft(2, '0')}';

      // 4. Traiter la réponse (Chat standard ou carte de Transaction)
      setState(() {
        final bool isTransaction = response['isTransaction'] == true ||
            response['transaction'] != null ||
            response['id'] != null;

        final dynamic transactionData = response['transaction'] ?? response;
        final String? messageText = response['message']?.toString();

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
        // Détection explicite de l'erreur d'authentification 401
        if (errorMessage.contains('Authentication credentials were not provided') ||
            errorMessage.contains('401')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Authentification échouée. Veuillez vous reconnecter à votre compte.'),
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
        setState(() {
          _isLoading = false;
        });
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

  // --- Widget pour afficher l'aperçu de l'image sélectionnée avant envoi ---
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
            onPressed: () {
              setState(() {
                _selectedImage = null;
              });
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const Padding(
          padding: EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundImage: NetworkImage('https://i.pravatar.cc/100?img=5'),
          ),
        ),
        title: const Text(
          'Femi',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_none_outlined,
              color: Colors.black87,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          const ChatDateBadgeWidget(dateText: 'Aujourd\'hui, 10:24'),
          const SizedBox(height: 12),

          // Zone d'affichage des messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return ChatMessageBubbleWidget(message: _messages[index]);
              },
            ),
          ),

          // Indicateur de chargement
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: LinearProgressIndicator(
                backgroundColor: Color(0xFFE2E8F0),
                color: Color(0xFF006654),
              ),
            ),

          // Aperçu de l'image si sélectionnée
          if (_selectedImage != null) _buildSelectedImagePreview(),

          // Barre de saisie
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ChatInputBarWidget(
              controller: _messageController,
              isRecording: _isRecording,
              onSend: () => _sendMessage(),
              onPickImage: _handlePickImage,
              onMicToggle: _handleMicToggle,
            ),
          ),
        ],
      ),
    );
  }
}