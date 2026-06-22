import 'package:flutter/material.dart';
import '../models/supabase_models.dart';
import '../services/app_messenger.dart';
import '../services/supabase_service.dart';

class ChatRoomScreen extends StatefulWidget {
  final ChatRoom chatRoom;

  const ChatRoomScreen({super.key, required this.chatRoom});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final SupabaseService _supabase = SupabaseService();
  final TextEditingController _messageController = TextEditingController();
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  UserProfile? _currentUser;
  UserProfile? _partner;

  @override
  void initState() {
    super.initState();
    _loadRoomData();
  }

  Future<void> _loadRoomData() async {
    print('Loading chat room data...');
    setState(() => _isLoading = true);
    try {
      print('Getting current user...');
      final currentUser = await _supabase.getCurrentUser();
      print('Current user: ${currentUser?.userId}, role: ${currentUser?.role}');
      if (currentUser == null) throw Exception('Пользователь не авторизован');
      
      print('ChatRoom: userId=${widget.chatRoom.userId}, trainerId=${widget.chatRoom.trainerId}');
      final partnerId = widget.chatRoom.userId == currentUser.userId ? widget.chatRoom.trainerId : widget.chatRoom.userId;
      print('Partner ID: $partnerId');
      
      var partner = await _supabase.getUserById(partnerId);
      if (partner == null) {
        print('Partner not found in public.users, trying auth fallback...');
        partner = await _supabase.getUserProfileFromAuth(partnerId);
      }
      print('Partner: ${partner?.name}');
      
      final messages = await _supabase.getChatMessages(widget.chatRoom.id);
      print('Loaded ${messages.length} messages');
      
      if (mounted) {
        setState(() {
          _currentUser = currentUser;
          _partner = partner;
          _messages = messages;
        });
      }
    } catch (e) {
      print('Error loading room data: $e');
      if (mounted) {
        appScaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(content: Text('Ошибка загрузки чата: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    try {
      await _supabase.sendChatMessage(widget.chatRoom.id, text);
      _messageController.clear();
      await _loadRoomData();
    } catch (e) {
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Ошибка отправки сообщения: $e')),
      );
    }
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isMine = message.senderId == _currentUser?.userId;
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: isMine ? Theme.of(context).colorScheme.primary : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          message.messageText,
          style: TextStyle(
            color: isMine ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _partner?.name ?? 'Чат';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(child: Text('Сообщений пока нет'))
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 12, bottom: 12),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          return _buildMessageBubble(_messages[index]);
                        },
                      ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Написать сообщение',
                        border: OutlineInputBorder(),
                      ),
                      minLines: 1,
                      maxLines: 4,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _sendMessage,
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
