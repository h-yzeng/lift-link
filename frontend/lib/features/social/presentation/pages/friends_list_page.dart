import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liftlink/core/error/failures.dart';
import 'package:liftlink/features/auth/presentation/providers/auth_providers.dart';
import 'package:liftlink/features/profile/domain/entities/profile.dart';
import 'package:liftlink/features/profile/presentation/providers/profile_providers.dart';
import 'package:liftlink/features/social/domain/entities/friendship.dart';
import 'package:liftlink/features/social/presentation/pages/friend_profile_page.dart';
import 'package:liftlink/features/social/presentation/pages/user_search_page.dart';
import 'package:liftlink/features/social/presentation/providers/friendship_providers.dart';
import 'package:liftlink/features/social/presentation/providers/paginated_friends_provider.dart';
import 'package:liftlink/shared/widgets/shimmer_loading.dart';

/// Page for viewing the user's friends list (standalone with AppBar)
class FriendsListPage extends ConsumerWidget {
  const FriendsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
        actions: [
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
              tooltip: 'Add friends',
            ),
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

        final paginatedState = ref.watch(paginatedFriendsProvider(user.id));

        if (paginatedState.friendships.isEmpty && paginatedState.isLoading) {
          return const FriendsListSkeleton();
        }

        if (paginatedState.friendships.isEmpty &&
            paginatedState.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 60,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text('Error: ${paginatedState.errorMessage}'),
              ],
            ),
          );
        }

        if (paginatedState.friendships.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.group,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Connect with Your Crew',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Add friends to share your fitness journey, motivate each other, and track your collective progress.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
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
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.read(paginatedFriendsProvider(user.id).notifier).refresh();
          },
          child: ListView.builder(
            itemCount: paginatedState.friendships.length +
                (paginatedState.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              // Load more button at the end
              if (index == paginatedState.friendships.length) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: paginatedState.isLoading
                        ? const CircularProgressIndicator()
                        : FilledButton.tonalIcon(
                            onPressed: () {
                              ref
                                  .read(
                                    paginatedFriendsProvider(user.id).notifier,
                                  )
                                  .loadNextPage();
                            },
                            icon: const Icon(Icons.expand_more),
                            label: const Text('Load More'),
                          ),
                  ),
                );
              }

              final friendship = paginatedState.friendships[index];
              return _FriendListTile(
                friendship: friendship,
                currentUserId: user.id,
              );
            },
          ),
        );
      },
      loading: () => const FriendsListSkeleton(),
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
        ref.invalidate(paginatedFriendsProvider);
      },
    );
  }

  Future<void> _setNickname(BuildContext context, WidgetRef ref) async {
    final currentNickname = friendship.getNicknameForOther(currentUserId);
    final controller = TextEditingController(text: currentNickname);

    final nickname = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Nickname'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 50,
          decoration: const InputDecoration(
            labelText: 'Nickname',
            hintText: 'Enter a nickname for your friend',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (nickname == null || !context.mounted) return;

    final updateUseCase = ref.read(updateFriendNicknameProvider);
    final result = await updateUseCase(
      currentUserId: currentUserId,
      friendshipId: friendship.id,
      nickname: nickname,
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
          SnackBar(
            content: Text(
              nickname.isEmpty ? 'Nickname removed' : 'Nickname updated',
            ),
          ),
        );
        ref.invalidate(paginatedFriendsProvider);
      },
    );
  }

  void _navigateToFriendProfile(
    BuildContext context,
    String friendId,
    String? nickname,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FriendProfilePage(
          friendId: friendId,
          nickname: nickname,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendId = friendship.getOtherUserId(currentUserId);
    final nickname = friendship.getNicknameForOther(currentUserId);
    final profileAsync = ref.watch(getProfileProvider);

    return FutureBuilder<Profile?>(
      future: profileAsync(friendId).then(
        (result) => result.fold((_) => null, (profile) => profile),
      ),
      builder: (context, snapshot) {
        final profile = snapshot.data;
        final displayName =
            nickname ?? profile?.displayNameOrUsername ?? 'Loading...';

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
            displayName,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: profile?.hasUsername == true &&
                  (profile?.hasCustomDisplayName == true || nickname != null)
              ? Text('@${profile!.username}')
              : null,
          trailing: PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'view_workouts') {
                _navigateToFriendProfile(context, friendId, nickname);
              } else if (value == 'set_nickname') {
                _setNickname(context, ref);
              } else if (value == 'remove') {
                _removeFriend(context, ref);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'view_workouts',
                child: Row(
                  children: [
                    Icon(Icons.fitness_center, size: 20),
                    SizedBox(width: 12),
                    Text('View Workouts'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'set_nickname',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20),
                    SizedBox(width: 12),
                    Text('Set Nickname'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'remove',
                child: Row(
                  children: [
                    Icon(Icons.person_remove, size: 20, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Remove Friend', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
          onTap: () => _navigateToFriendProfile(context, friendId, nickname),
        );
      },
    );
  }
}
