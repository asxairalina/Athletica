import 'package:flutter/material.dart';
import '../models/supabase_models.dart';
import '../services/app_messenger.dart';
import '../services/supabase_service.dart';
import 'chat_room_screen.dart';
import 'trainers_screen.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  final SupabaseService _supabase = SupabaseService();
  List<ChatRoom> _rooms = [];
  Map<String, UserProfile> _partners = {};
  bool _isLoading = true;
  UserProfile? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    setState(() => _isLoading = true);
    try {
      final currentUser = await _supabase.getCurrentUser();
      if (currentUser == null) throw Exception('Пользователь не авторизован');
      _currentUser = currentUser;

      final rooms = currentUser.role == 'trainer'
          ? await _supabase.getChatRoomsForCurrentTrainer()
          : await _supabase.getChatRoomsForCurrentUser();

          final partnerIds = rooms
            .map((room) => room.userId == currentUser.userId ? room.trainerId : room.userId)
            .toSet()
            .toList();
      final profiles = partnerIds.isEmpty ? <UserProfile>[] : await _supabase.getUsersByIds(partnerIds);
      final partnerMap = {for (var profile in profiles) profile.userId: profile};

      setState(() {
        _rooms = rooms;
        _partners = partnerMap;
      });
    } catch (e) {
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Ошибка загрузки чатов: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _openChat(ChatRoom room) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ChatRoomScreen(chatRoom: room)),
    ).then((_) => _loadChats());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Чаты')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TrainersScreen()),
          );
        },
        tooltip: 'Найти тренера',
        child: const Icon(Icons.person_search),
      ),
      body: RefreshIndicator(
        onRefresh: _loadChats,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _rooms.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 120),
                      Center(
                        child: Text('Чатов пока нет. Найдите тренера, чтобы начать.'),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _rooms.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final room = _rooms[index];
                      final partner = _partners[_currentUser?.role == 'trainer' ? room.userId : room.trainerId];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: partner?.avatarPath != null
                                ? NetworkImage(partner!.avatarPath!) as ImageProvider
                                : null,
                            child: partner?.avatarPath == null ? const Icon(Icons.person) : null,
                          ),
                          title: Text(partner?.name ?? 'Клиент/Тренер'),
                          subtitle: Text(room.lastMessage ?? 'Новая переписка'),
                          trailing: Text(
                            '${room.updatedAt.hour.toString().padLeft(2, '0')}:${room.updatedAt.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          onTap: () => _openChat(room),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
