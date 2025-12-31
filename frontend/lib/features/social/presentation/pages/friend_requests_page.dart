import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liftlink/core/error/failures.dart';
import 'package:liftlink/features/auth/presentation/providers/auth_providers.dart';
import 'package:liftlink/features/profile/domain/entities/profile.dart';
import 'package:liftlink/features/profile/presentation/providers/profile_providers.dart';
import 'package:liftlink/features/social/domain/entities/friendship.dart';
import 'package:liftlink/features/social/presentation/providers/friendship_providers.dart';

/// Page for managing friend requests (received and sent)
class FriendRequestsPage extends ConsumerWidget {
  const FriendRequestsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserAsync = ref.watch(currentUserProvider);

    return currentUserAsync.when(
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(child: Text('Please log in')),
          );
        }

        final pendingRequestsAsync = ref.watch(pendingRequestsListProvider(user.id));

        return Scaffold(
          appBar: AppBar(
            title: const Text('Friend Requests'),
          ),
          body: pendingRequestsAsync.when(
            data: (requests) {
              if (requests.isEmpty) {
                return const Center(
                  child: Text('No pending friend requests'),
                );
              }

              final receivedRequests = requests
                  .where((r) => r.addresseeId == user.id)
                  .toList();
              final sentRequests = requests
                  .where((r) => r.requesterId == user.id)
                  .toList();

              return DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    const TabBar(
                      tabs: [
                        Tab(text: 'Received'),
                        Tab(text: 'Sent'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _ReceivedRequestsList(
                            requests: receivedRequests,
                            currentUserId: user.id,
                          ),
                          _SentRequestsList(
                            requests: sentRequests,
                            currentUserId: user.id,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Text('Error: $error'),
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('Error: $error')),
      ),
    );
  }
}

class _ReceivedRequestsList extends ConsumerWidget {
  final List<Friendship> requests;
  final String currentUserId;

  const _ReceivedRequestsList({
    required this.requests,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (requests.isEmpty) {
      return const Center(
        child: Text('No received requests'),
      );
    }

    return ListView.builder(
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        return _ReceivedRequestTile(
          friendship: request,
          currentUserId: currentUserId,
        );
      },
    );
  }
}

class _ReceivedRequestTile extends ConsumerWidget {
  final Friendship friendship;
  final String currentUserId;

  const _ReceivedRequestTile({
    required this.friendship,
    required this.currentUserId,
  });

  Future<void> _acceptRequest(BuildContext context, WidgetRef ref) async {
    final acceptUseCase = ref.read(acceptFriendRequestProvider);
    final result = await acceptUseCase(
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
            content: Text('Friend request accepted'),
            backgroundColor: Colors.green,
          ),
        );
        ref.invalidate(pendingRequestsListProvider);
      },
    );
  }

  Future<void> _rejectRequest(BuildContext context, WidgetRef ref) async {
    final rejectUseCase = ref.read(rejectFriendRequestProvider);
    final result = await rejectUseCase(
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
            content: Text('Friend request rejected'),
          ),
        );
        ref.invalidate(pendingRequestsListProvider);
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(getProfileProvider);

    return FutureBuilder<Profile?>(
      future: profileAsync(friendship.requesterId).then(
        (result) => result.fold((_) => null, (profile) => profile),
      ),
      builder: (context, snapshot) {
        final profile = snapshot.data;

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: profile != null
                ? Text(
                    profile.initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : const Icon(Icons.person, color: Colors.white),
          ),
          title: Text(
            profile?.displayNameOrUsername ?? 'Loading...',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: const Text('wants to be friends'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.check, color: Colors.green),
                onPressed: () => _acceptRequest(context, ref),
                tooltip: 'Accept',
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                onPressed: () => _rejectRequest(context, ref),
                tooltip: 'Reject',
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SentRequestsList extends ConsumerWidget {
  final List<Friendship> requests;
  final String currentUserId;

  const _SentRequestsList({
    required this.requests,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (requests.isEmpty) {
      return const Center(
        child: Text('No sent requests'),
      );
    }

    return ListView.builder(
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        return _SentRequestTile(
          friendship: request,
          currentUserId: currentUserId,
        );
      },
    );
  }
}

class _SentRequestTile extends ConsumerWidget {
  final Friendship friendship;
  final String currentUserId;

  const _SentRequestTile({
    required this.friendship,
    required this.currentUserId,
  });

  Future<void> _cancelRequest(BuildContext context, WidgetRef ref) async {
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
            content: Text('Friend request cancelled'),
          ),
        );
        ref.invalidate(pendingRequestsListProvider);
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(getProfileProvider);

    return FutureBuilder<Profile?>(
      future: profileAsync(friendship.addresseeId).then(
        (result) => result.fold((_) => null, (profile) => profile),
      ),
      builder: (context, snapshot) {
        final profile = snapshot.data;

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: profile != null
                ? Text(
                    profile.initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : const Icon(Icons.person, color: Colors.white),
          ),
          title: Text(
            profile?.displayNameOrUsername ?? 'Loading...',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: const Text('Request pending'),
          trailing: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _cancelRequest(context, ref),
            tooltip: 'Cancel request',
          ),
        );
      },
    );
  }
}
