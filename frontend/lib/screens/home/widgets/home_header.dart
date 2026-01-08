import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/neumorphic_button.dart';
import '../../../widgets/neumorphic_container.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);

    return SliverAppBar(
      expandedHeight: 160,
      floating: false,
      pinned: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  children: [
                    // Neumorphic Profile Picture Container
                    NeumorphicContainer(
                      width: 64,
                      height: 64,
                      shape: BoxShape.circle,
                      padding: const EdgeInsets.all(4),
                      child: CircleAvatar(
                        backgroundColor: const Color(
                          0xFF6C63FF,
                        ).withOpacity(0.1),
                        child: Text(
                          (auth.userName ?? 'U')[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6C63FF),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello,',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                          Text(
                            auth.userName?.split(' ').first ?? "there",
                            style: theme.textTheme.displayLarge?.copyWith(
                              fontSize: 32,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: NeumorphicButton(
            width: 48,
            height: 48,
            padding: EdgeInsets.zero,
            onTap: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
            },
            child: Icon(
              Icons.logout_rounded,
              color: theme.colorScheme.secondary,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }
}
