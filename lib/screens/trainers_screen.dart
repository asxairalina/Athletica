import 'package:flutter/material.dart';
import '../models/supabase_models.dart';
import '../services/app_messenger.dart';
import '../services/supabase_service.dart';
import 'chat_room_screen.dart';

class TrainersScreen extends StatefulWidget {
  const TrainersScreen({super.key});

  @override
  State<TrainersScreen> createState() => _TrainersScreenState();
}

class _TrainersScreenState extends State<TrainersScreen> {
  final SupabaseService _supabase = SupabaseService();
  List<UserProfile> _trainers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTrainers();
  }

  Future<void> _loadTrainers() async {
    print('Loading trainers...');
    setState(() => _isLoading = true);
    try {
      final trainers = await _supabase.getAllTrainers();
      print('Loaded ${trainers.length} trainers');
      setState(() => _trainers = trainers);
    } catch (e) {
      print('Error loading trainers: $e');
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Ошибка загрузки списка тренеров: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _startChat(UserProfile trainer) async {
    print('Starting chat with trainer: ${trainer.name}');
    try {
      print('Creating/getting chat room...');
      final room = await _supabase.getOrCreateChatRoomWithTrainer(trainer.userId);
      print('Chat room created: ${room.id}');
      if (!mounted) return;
      print('Navigating to chat room...');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatRoomScreen(chatRoom: room),
        ),
      );
      print('Navigation completed');
    } catch (e) {
      print('Error starting chat: $e');
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Не удалось начать чат: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Тренеры')),
      body: RefreshIndicator(
        onRefresh: _loadTrainers,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _trainers.isEmpty
                ? ListView(
                    children: const [
                      Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text('Тренеры не найдены'),
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _trainers.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final trainer = _trainers[index];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: trainer.avatarPath != null
                                ? NetworkImage(trainer.avatarPath!) as ImageProvider
                                : null,
                            child: trainer.avatarPath == null ? const Icon(Icons.person) : null,
                          ),
                          title: Text(trainer.name),
                          trailing: ElevatedButton(
                            onPressed: () => _startChat(trainer),
                            child: const Text('Написать'),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
