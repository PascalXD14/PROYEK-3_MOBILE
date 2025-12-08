import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/api_config.dart';
import '../chat/chat.dart';
import '../chat/notifikasi.dart';

class CustomHeader extends StatelessWidget {
  const CustomHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () async {
                  final auth = AuthService();

                  final token = await auth.getToken();
                  final myUserId = await auth.getUserId();

                  if (token == null || myUserId == null) {
                    if (!context.mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Silakan login terlebih dahulu'),
                      ),
                    );
                    return;
                  }

                  if (!context.mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ChatPage()),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.chat_bubble_outline, size: 30),
                ),
              ),

              // 🔔 Notifikasi (Baru ditambah)
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationPage()),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.notifications_none, size: 30),
                ),
              ),
            ],
          ),

          // Logo
          RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: "Arif",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.lightGreen,
                  ),
                ),
                TextSpan(
                  text: "Motor",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),

          // Avatar
          ValueListenableBuilder<String?>(
            valueListenable: AuthService.avatarNotifier,
            builder: (context, avatarUrl, _) {
              final resolved = ApiConfig.toAbsolute(avatarUrl ?? '');

              if (resolved.isEmpty) {
                return const CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, color: Colors.white),
                );
              }

              return CircleAvatar(
                radius: 22,
                backgroundImage: NetworkImage(resolved),
                backgroundColor: Colors.transparent,
              );
            },
          ),
        ],
      ),
    );
  }
}
