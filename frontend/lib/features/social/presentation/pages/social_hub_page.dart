import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liftlink/features/auth/presentation/providers/auth_providers.dart';
import 'package:liftlink/features/social/presentation/pages/activity_feed_page.dart';
import 'package:liftlink/features/social/presentation/pages/friend_requests_page.dart';
import 'package:liftlink/features/social/presentation/pages/friends_list_page.dart';
import 'package:liftlink/features/social/presentation/pages/user_search_page.dart';
import 'package:liftlink/features/social/presentation/providers/friendship_providers.dart';

/// Main social hub page with friends list and quick access to requests
class SocialHubPage extends ConsumerWidget {
  const SocialHubPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserAsync = ref.watch(currentUserProvider);

    return currentUserAsync.when(
      data: (user) {
        if (user == null) {
          return const Scaffold(body: Center(child: Text('Please log in')));
        }

        final pendingRequestsAsync = ref.watch(
          pendingRequestsListProvider(user.id),
        );

        return Scaffold(
          appBar: AppBar(
            title: const Text('Social'),
            actions: [
              Semantics(
                label: 'View activity feed',
                button: true,
                child: IconButton(
                  icon: const Icon(Icons.feed),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ActivityFeedPage(),
                      ),
                    );
                  },
                  tooltip: 'Activity feed',
                ),
              ),
              Stack(
                children: [
                  Semantics(
                    label: 'View friend requests',
                    button: true,
                    child: IconButton(
                      icon: const Icon(Icons.notifications),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const FriendRequestsPage(),
                          ),
                        );
                      },
                      tooltip: 'Friend requests',
                    ),
                  ),
                  pendingRequestsAsync.when(
                    data: (requests) {
                      final receivedCount = requests
                          .where((r) => r.addresseeId == user.id)
                          .length;

                      if (receivedCount == 0) {
                        return const SizedBox.shrink();
                      }

                      return Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '$receivedCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                ],
              ),
              Semantics(
                label: 'Search and add friends',
                button: true,
                child: IconButton(
                  icon: const Icon(Icons.person_add),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const UserSearchPage(),
                      ),
                    );
                  },
                  tooltip: 'Find friends',
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              pendingRequestsAsync.when(
                data: (requests) {
                  final receivedCount = requests
                      .where((r) => r.addresseeId == user.id)
                      .length;

                  if (receivedCount == 0) {
                    return const SizedBox.shrink();
                  }

                  return Card(
                    margin: const EdgeInsets.all(16),
                    child: ListTile(
                      leading: const Icon(Icons.person_add, color: Colors.blue),
                      title: Text(
                        '$receivedCount new friend ${receivedCount == 1 ? 'request' : 'requests'}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const FriendRequestsPage(),
                          ),
                        );
                      },
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),
              const Expanded(child: FriendsListContent()),
            ],
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) =>
          Scaffold(body: Center(child: Text('Error: $error'))),
    );
  }
}
