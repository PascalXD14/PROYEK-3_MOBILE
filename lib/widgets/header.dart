import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/api_config.dart';

class CustomHeader extends StatelessWidget {
  const CustomHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(6),
              child: const Icon(
                Icons.chat_bubble_outline,
                size: 30,
                color: Colors.black87,
              ),
            ),
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
