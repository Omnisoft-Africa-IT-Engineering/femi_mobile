import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../../../models/femi_agent_models.dart';

class ChatMessageBubbleWidget extends StatefulWidget {
  final Map<String, dynamic> message;

  const ChatMessageBubbleWidget({
    super.key,
    required this.message,
  });

  @override
  State<ChatMessageBubbleWidget> createState() =>
      _ChatMessageBubbleWidgetState();
}

class _ChatMessageBubbleWidgetState
    extends State<ChatMessageBubbleWidget> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;

  PlayerState _playerState = PlayerState.stopped;

  Duration _audioDuration = Duration.zero;
  Duration _audioPosition = Duration.zero;

  @override
  void initState() {
    super.initState();

    _playerStateSubscription =
        _audioPlayer.onPlayerStateChanged.listen((state) {
      if (!mounted) return;

      setState(() {
        _playerState = state;
      });
    });

    _positionSubscription =
        _audioPlayer.onPositionChanged.listen((position) {
      if (!mounted) return;

      setState(() {
        _audioPosition = position;
      });
    });

    _durationSubscription =
        _audioPlayer.onDurationChanged.listen((duration) {
      if (!mounted) return;

      setState(() {
        _audioDuration = duration;
      });
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      if (!mounted) return;

      setState(() {
        _playerState = PlayerState.stopped;
        _audioPosition = Duration.zero;
      });
    });
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _audioPlayer.dispose();

    super.dispose();
  }

  Future<void> _toggleAudio() async {
    final File? audioFile =
        widget.message['audioFile'] as File?;

    if (audioFile == null) return;

    try {
      if (_playerState == PlayerState.playing) {
        await _audioPlayer.pause();
        return;
      }

      if (_playerState == PlayerState.paused) {
        await _audioPlayer.resume();
        return;
      }

      await _audioPlayer.stop();

      await _audioPlayer.play(
        DeviceFileSource(audioFile.path),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Impossible de lire le message vocal : $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _openImageFullscreen(
    BuildContext context,
    File imageFile,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) {
          return Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              elevation: 0,
              iconTheme: const IconThemeData(
                color: Colors.white,
              ),
            ),
            body: Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.file(
                  imageFile,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes
        .remainder(60)
        .toString()
        .padLeft(2, '0');

    final seconds = duration.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');

    return '$minutes:$seconds';
  }

  Widget _buildAudioPlayer(
    BuildContext context,
    File audioFile,
    bool isUser,
  ) {
    final Color mainColor =
        isUser ? Colors.white : const Color(0xFF006654);

    final double maxSeconds =
        _audioDuration.inMilliseconds > 0
            ? _audioDuration.inMilliseconds.toDouble()
            : 1.0;

    final double currentSeconds =
        _audioPosition.inMilliseconds
            .clamp(0, _audioDuration.inMilliseconds)
            .toDouble();

    return Container(
      width: 230,
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _toggleAudio,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 40,
              minHeight: 40,
            ),
            icon: Icon(
              _playerState == PlayerState.playing
                  ? Icons.pause_circle_filled_rounded
                  : Icons.play_circle_fill_rounded,
              color: mainColor,
              size: 34,
            ),
          ),

          const SizedBox(width: 4),

          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape:
                        const RoundSliderThumbShape(
                      enabledThumbRadius: 5,
                    ),
                    overlayShape:
                        const RoundSliderOverlayShape(
                      overlayRadius: 10,
                    ),
                    activeTrackColor: mainColor,
                    inactiveTrackColor:
                        mainColor.withOpacity(0.25),
                    thumbColor: mainColor,
                  ),
                  child: Slider(
                    value: currentSeconds,
                    min: 0,
                    max: maxSeconds,
                    onChanged: _audioDuration.inMilliseconds <= 0
                        ? null
                        : (value) async {
                            final position = Duration(
                              milliseconds: value.toInt(),
                            );

                            await _audioPlayer.seek(position);
                          },
                  ),
                ),

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(_audioPosition),
                      style: TextStyle(
                        color: mainColor,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      _audioDuration == Duration.zero
                          ? '--:--'
                          : _formatDuration(_audioDuration),
                      style: TextStyle(
                        color: mainColor,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isUser =
        (widget.message['isUser'] as bool?) ?? false;

    final text =
        widget.message['text'] as String?;

    final time =
        (widget.message['time'] as String?) ?? '';

    final imageFile =
        widget.message['imageFile'] as File?;

    final audioFile =
        widget.message['audioFile'] as File?;

    final transaction =
        widget.message['transaction'] as FemiTransaction?;

    // ---------------------------------------------------------
    // TRANSACTION FEMI
    // ---------------------------------------------------------

    if (transaction != null) {
      return _buildTransactionCard(
        context,
        transaction,
        time,
      );
    }

    // ---------------------------------------------------------
    // MESSAGE NORMAL
    // ---------------------------------------------------------

    return Align(
      alignment: isUser
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        constraints: BoxConstraints(
          maxWidth:
              MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? const Color(0xFF006654)
              : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isUser
                ? const Radius.circular(16)
                : Radius.zero,
            bottomRight: isUser
                ? Radius.zero
                : const Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [

            // -------------------------------------------------
            // IMAGE
            // -------------------------------------------------

            if (imageFile != null) ...[
              GestureDetector(
                onTap: () {
                  _openImageFullscreen(
                    context,
                    imageFile,
                  );
                },
                child: Hero(
                  tag: 'femi-image-${imageFile.path}',
                  child: ClipRRect(
                    borderRadius:
                        BorderRadius.circular(12),
                    child: Image.file(
                      imageFile,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),
            ],

            // -------------------------------------------------
            // MESSAGE VOCAL
            // -------------------------------------------------

            if (audioFile != null) ...[
              _buildAudioPlayer(
                context,
                audioFile,
                isUser,
              ),

              const SizedBox(height: 4),
            ],

            // -------------------------------------------------
            // TEXTE
            // -------------------------------------------------

            if (text != null && text.isNotEmpty)
              Text(
                text,
                style: TextStyle(
                  color: isUser
                      ? Colors.white
                      : Colors.black87,
                  fontSize: 15,
                  height: 1.3,
                ),
              ),

            const SizedBox(height: 4),

            // -------------------------------------------------
            // HEURE
            // -------------------------------------------------

            Text(
              time,
              style: TextStyle(
                color: isUser
                    ? Colors.white70
                    : Colors.grey.shade600,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // CARTE TRANSACTION
  // =========================================================

  Widget _buildTransactionCard(
    BuildContext context,
    FemiTransaction tx,
    String time,
  ) {
    final isRecette =
        tx.transactionType.toUpperCase() == 'RECETTE';

    final accentColor = isRecette
        ? const Color(0xFF16A34A)
        : const Color(0xFFEA580C);

    final double amount =
        double.tryParse(
              tx.amountTtc.toString(),
            ) ??
            0.0;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        width:
            MediaQuery.of(context).size.width * 0.82,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(16),
          border: Border.all(
            color: accentColor.withOpacity(0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [

            // Badge & Montant
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        accentColor.withOpacity(0.12),
                    borderRadius:
                        BorderRadius.circular(8),
                  ),
                  child: Text(
                    tx.transactionType,
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 11,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),

                Text(
                  '${amount.toStringAsFixed(0)} ${tx.currency}',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: accentColor,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Description
            Text(
              tx.description,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 6),

            // Détails
            Row(
              children: [
                Icon(
                  Icons.category_outlined,
                  size: 14,
                  color: Colors.grey.shade600,
                ),

                const SizedBox(width: 4),

                Text(
                  tx.category,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(width: 12),

                Icon(
                  Icons.payment_outlined,
                  size: 14,
                  color: Colors.grey.shade600,
                ),

                const SizedBox(width: 4),

                Text(
                  tx.paymentMethod,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),

            const Padding(
              padding:
                  EdgeInsets.symmetric(vertical: 8),
              child: Divider(
                height: 1,
                thickness: 0.8,
              ),
            ),

            // Footer
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color:
                          Color(0xFF16A34A),
                      size: 14,
                    ),

                    const SizedBox(width: 4),

                    Text(
                      'Enregistrée '
                      '(${(tx.confidenceScore * 100).toInt()}% conf.)',
                      style:
                          const TextStyle(
                        color:
                            Color(0xFF16A34A),
                        fontSize: 11,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                Text(
                  time,
                  style: TextStyle(
                    color:
                        Colors.grey.shade500,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}