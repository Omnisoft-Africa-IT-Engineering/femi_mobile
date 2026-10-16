import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ChatInputBarWidget extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  final Function(bool isCamera)? onPickImage;
  final VoidCallback? onPickPdf;

  final VoidCallback? onStartRecording;
  final VoidCallback? onPauseRecording;
  final VoidCallback? onResumeRecording;
  final VoidCallback? onCancelRecording;
  final VoidCallback? onSendRecording;

  final bool isRecording;
  final bool isPaused;
  final Duration recordingDuration;

  const ChatInputBarWidget({
    super.key,
    required this.controller,
    required this.onSend,
    this.onPickImage,
    this.onPickPdf,
    this.onStartRecording,
    this.onPauseRecording,
    this.onResumeRecording,
    this.onCancelRecording,
    this.onSendRecording,
    this.isRecording = false,
    this.isPaused = false,
    this.recordingDuration = Duration.zero,
  });

  @override
  State<ChatInputBarWidget> createState() => _ChatInputBarWidgetState();
}

class _ChatInputBarWidgetState extends State<ChatInputBarWidget> {
  final FocusNode _focusNode = FocusNode();
  bool _showEmojiPanel = false;

  static const Color _femiGreen = Color(0xFF006654);
  static const Color _femiDark = Color(0xFF0D5C52);
  static const Color _barBg = Color(0xFFF7F9FC);
  static const Color _hint = Color(0xFF667781);

  static const List<String> _emojis = [
    '😀', '😁', '😂', '🤣', '😃', '😄', '😅', '😆',
    '😉', '😊', '😋', '😎', '😍', '😘', '🥰', '😗',
    '😙', '😚', '🙂', '🤗', '🤩', '🤔', '🤨', '😐',
    '😑', '😶', '🙄', '😏', '😣', '😥', '😮', '🤐',
    '😯', '😪', '😫', '🥱', '😴', '😌', '😛', '😜',
    '😝', '🤤', '😒', '😓', '😔', '😕', '🙃', '🤑',
    '😲', '☹️', '🙁', '😖', '😞', '😟', '😤', '😢',
    '😭', '😦', '😧', '😨', '😩', '🤯', '😬', '😰',
    '😱', '🥵', '🥶', '😳', '🤪', '😵', '😡', '😠',
    '🤬', '😷', '🤒', '🤕', '🤢', '🤮', '🥴', '😇',
    '🥳', '🥺', '🤠', '🤡', '🤥', '🤫', '🤭', '🧐',
    '🤓', '😈', '👿', '👹', '👺', '💀', '☠️', '👻',
    '👍', '👎', '👏', '🙌', '👐', '🤝', '🙏', '✌️',
    '🤞', '🤟', '🤘', '👌', '🤌', '🤏', '👈', '👉',
    '👆', '👇', '☝️', '✋', '🤚', '🖐️', '🖖', '👋',
    '💪', '🦾', '❤️', '🧡', '💛', '💚', '💙', '💜',
    '🖤', '🤍', '🤎', '💔', '❣️', '💕', '💞', '💓',
    '💗', '💖', '💘', '💝', '🔥', '⭐', '✨', '💯',
    '✅', '❌', '⚡', '💰', '💵', '📈', '📉', '🧾',
  ];

  bool get _hasText => widget.controller.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(covariant ChatInputBarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTextChanged);
      widget.controller.addListener(_onTextChanged);
    }
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _focusNode.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString();
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _toggleEmojiPanel() {
    setState(() {
      _showEmojiPanel = !_showEmojiPanel;
    });
    if (_showEmojiPanel) {
      _focusNode.unfocus();
    } else {
      _focusNode.requestFocus();
    }
  }

  void _insertEmoji(String emoji) {
    final text = widget.controller.text;
    final selection = widget.controller.selection;

    final start = selection.start >= 0 ? selection.start : text.length;
    final end = selection.end >= 0 ? selection.end : text.length;

    final newText = text.replaceRange(start, end, emoji);
    final newOffset = start + emoji.length;

    widget.controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newOffset),
    );
  }

  void _showAttachmentOptions(BuildContext context) {
    if (widget.onPickImage == null && widget.onPickPdf == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            child: Wrap(
              alignment: WrapAlignment.spaceEvenly,
              spacing: 20,
              runSpacing: 20,
              children: [
                if (widget.onPickImage != null)
                  _option(
                    Icons.camera_alt_rounded,
                    'Appareil photo',
                    _femiGreen,
                    () {
                      Navigator.pop(context);
                      widget.onPickImage!(true);
                    },
                  ),
                if (widget.onPickImage != null)
                  _option(
                    Icons.photo_library_rounded,
                    'Galerie',
                    const Color(0xFF005AC1),
                    () {
                      Navigator.pop(context);
                      widget.onPickImage!(false);
                    },
                  ),
                if (widget.onPickPdf != null)
                  _option(
                    Icons.picture_as_pdf_rounded,
                    'Document PDF',
                    Colors.red,
                    () {
                      Navigator.pop(context);
                      widget.onPickPdf!();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _option(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildEmojiPanel() {
    return Container(
      height: 260,
      color: Colors.white,
      child: Column(
        children: [
          Container(
            height: 4,
            width: 40,
            margin: const EdgeInsets.only(top: 8, bottom: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemCount: _emojis.length,
              itemBuilder: (context, index) {
                final emoji = _emojis[index];
                return InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _insertEmoji(emoji),
                  child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 24)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingBar() {
    return Container(
      color: _barBg,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: widget.onCancelRecording,
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(Icons.delete_outline, color: Colors.red, size: 28),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  if (!widget.isPaused)
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    )
                  else
                    const Icon(Icons.pause, color: Colors.red, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    _formatDuration(widget.recordingDuration),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    widget.isPaused ? 'En pause' : 'Enregistrement…',
                    style: const TextStyle(fontSize: 13, color: _hint),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          Material(
            color: const Color(0xFFE8F5F2),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: widget.isPaused
                  ? widget.onResumeRecording
                  : widget.onPauseRecording,
              child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  widget.isPaused
                      ? Icons.play_arrow_rounded
                      : Icons.pause_rounded,
                  color: _femiDark,
                  size: 28,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Material(
            color: _femiGreen,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: widget.onSendRecording,
              child: const SizedBox(
                width: 48,
                height: 48,
                child: Icon(Icons.send_rounded, color: Colors.white, size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNormalBar() {
    final showSend = _hasText;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          color: _barBg,
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Pastille unique style WhatsApp (sans bordure autour du champ)
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(minHeight: 48),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Emoji → ouvre le panneau
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                          _showEmojiPanel
                              ? Icons.keyboard_outlined
                              : Icons.emoji_emotions_outlined,
                          color: _femiDark,
                          size: 26,
                        ),
                        onPressed: _toggleEmojiPanel,
                      ),

                      // Texte — pas de bordure, pas de cadre
                      Expanded(
                        child: Focus(
                          onKeyEvent: (node, event) {
                            if (event is! KeyDownEvent) {
                              return KeyEventResult.ignored;
                            }
                            final isEnter = event.logicalKey ==
                                    LogicalKeyboardKey.enter ||
                                event.logicalKey ==
                                    LogicalKeyboardKey.numpadEnter;
                            if (!isEnter) return KeyEventResult.ignored;
                            if (HardwareKeyboard.instance.isShiftPressed) {
                              return KeyEventResult.ignored;
                            }
                            if (_hasText) {
                              widget.onSend();
                              return KeyEventResult.handled;
                            }
                            return KeyEventResult.ignored;
                          },
                          child: TextField(
                            controller: widget.controller,
                            focusNode: _focusNode,
                            minLines: 1,
                            maxLines: 6,
                            keyboardType: TextInputType.multiline,
                            textInputAction: TextInputAction.newline,
                            textCapitalization: TextCapitalization.sentences,
                            onTap: () {
                              if (_showEmojiPanel) {
                                setState(() => _showEmojiPanel = false);
                              }
                            },
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.35,
                              color: Color(0xFF0F172A),
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Message',
                              hintStyle: TextStyle(
                                color: _hint,
                                fontSize: 16,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                      ),

                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(
                          Icons.attach_file,
                          color: _femiDark,
                          size: 24,
                        ),
                        onPressed: () => _showAttachmentOptions(context),
                      ),
                      if (!showSend)
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(
                            Icons.camera_alt_outlined,
                            color: _femiDark,
                            size: 24,
                          ),
                          onPressed: widget.onPickImage == null
                              ? null
                              : () => widget.onPickImage!(true),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 6),

              Material(
                color: _femiGreen,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: showSend ? widget.onSend : widget.onStartRecording,
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Icon(
                      showSend ? Icons.send_rounded : Icons.mic,
                      color: Colors.white,
                      size: showSend ? 22 : 26,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        if (_showEmojiPanel) _buildEmojiPanel(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isRecording) return _buildRecordingBar();
    return _buildNormalBar();
  }
}