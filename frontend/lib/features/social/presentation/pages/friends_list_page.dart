import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liftlink/core/error/failures.dart';
import 'package:liftlink/features/auth/presentation/providers/auth_providers.dart';
import 'package:liftlink/features/profile/domain/entities/profile.dart';
import 'package:liftlink/features/profile/presentation/providers/profile_providers.dart';
import 'package:liftlink/features/social/domain/entities/friendship.dart';
import 'package:liftlink/features/social/presentation/pages/user_search_page.dart';
import 'package:liftlink/features/social/presentation/providers/friendship_providers.dart';

/// Page for viewing the user's friends list (standalone with AppBar)
class FriendsListPage extends ConsumerWidget {
  const FriendsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const UserSearchPage(),
                ),
              );
            },
            tooltip: 'Add friends',
          ),
        ],
      ),
      body: const FriendsListContent(),
    );
  }
}

/// Reusable friends list content without Scaffold (for embedding)
class FriendsListContent extends ConsumerWidget {
  const FriendsListContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserAsync = ref.watch(currentUserProvider);

    return currentUserAsync.when(
      data: (user) {
        if (user == null) {
          return const Center(child: Text('Please log in'));
        }

        final friendsAsync = ref.watch(friendsListProvider(user.id));

        return friendsAsync.when(
          data: (friends) {
            if (friends.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.people_outline,
                      size: 80,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No friends yet',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Add friends to see their workouts',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const UserSearchPage(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.person_add),
                      label: const Text('Find Friends'),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: friends.length,
              itemBuilder: (context, index) {
                final friendship = friends[index];
                return _FriendListTile(
                  friendship: friendship,
                  currentUserId: user.id,
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 60,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text('Error: $error'),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }
}

class _FriendListTile extends ConsumerWidget {
  final Friendship friendship;
  final String currentUserId;

  const _FriendListTile({
    required this.friendship,
    required this.currentUserId,
  });

  Future<void> _removeFriend(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Friend'),
        content: const Text('Are you sure you want to remove this friend?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final removeUseCase = ref.read(removeFriendshipProvider);
    final result = await removeUseCase(
      currentUserId: currentUserId,
      friendshipId: friendship.id,
    );

    if (!context.mounted) return;

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.userMessage),
            backgroundColor: Colors.red,
          ),
        );
      },
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Friend removed'),
          ),
        );
        ref.invalidate(friendsListProvider);
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendId = friendship.getOtherUserId(currentUserId);
    final profileAsync = ref.watch(getProfileProvider);

    return FutureBuilder<Profile?>(
      future: profileAsync(friendId).then(
        (result) => result.fold((_) => null, (profile) => profile),
      ),
      builder: (context, snapshot) {
        final profile = snapshot.data;

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            backgroundImage: profile?.hasAvatar == true
                ? NetworkImage(profile!.avatarUrl!)
                : null,
            child: profile?.hasAvatar == true
                ? null
                : Text(
                    profile?.initials ?? '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
          title: Text(
            profile?.displayNameOrUsername ?? 'Loading...',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: profile?.hasUsername == true && profile?.hasCustomDisplayName == true
              ? Text('@${profile!.username}')
              : null,
          trailing: PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'remove') {
                _removeFriend(context, ref);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'remove',
                child: Text('Remove Friend'),
              ),
            ],
          ),
          onTap: () {
            // TODO: Navigate to friend's profile page
          },
        );
      },
    );
  }
}
