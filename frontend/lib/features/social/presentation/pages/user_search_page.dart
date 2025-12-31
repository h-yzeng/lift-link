import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liftlink/core/error/failures.dart';
import 'package:liftlink/features/auth/presentation/providers/auth_providers.dart';
import 'package:liftlink/features/profile/domain/entities/profile.dart';
import 'package:liftlink/features/profile/presentation/providers/profile_providers.dart';
import 'package:liftlink/features/social/presentation/providers/friendship_providers.dart';
import 'package:liftlink/features/social/presentation/widgets/user_list_tile.dart';

/// Page for searching users and sending friend requests
class UserSearchPage extends ConsumerStatefulWidget {
  const UserSearchPage({super.key});

  @override
  ConsumerState<UserSearchPage> createState() => _UserSearchPageState();
}

class _UserSearchPageState extends ConsumerState<UserSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Profile> _searchResults = [];
  bool _isSearching = false;
  String? _errorMessage;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });

    try {
      final searchUsers = ref.read(searchUsersProvider);
      final result = await searchUsers(query: query);

      result.fold(
        (failure) {
          if (mounted) {
            setState(() {
              _errorMessage = failure.userMessage;
              _searchResults = [];
              _isSearching = false;
            });
          }
        },
        (profiles) {
          if (mounted) {
            setState(() {
              _searchResults = profiles;
              _isSearching = false;
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'An error occurred while searching';
          _searchResults = [];
          _isSearching = false;
        });
      }
    }
  }

  Future<void> _sendFriendRequest(Profile profile) async {
    final currentUser = await ref.read(currentUserProvider.future);
    if (currentUser == null) return;

    final sendRequest = ref.read(sendFriendRequestProvider);
    final result = await sendRequest(
      currentUserId: currentUser.id,
      targetUserId: profile.id,
    );

    if (!mounted) return;

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.userMessage),
            backgroundColor: Colors.red,
          ),
        );
      },
      (friendship) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Friend request sent to ${profile.displayNameOrUsername}'),
            backgroundColor: Colors.green,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Friends'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by username or name',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                if (value.length >= 2) {
                  _performSearch(value);
                } else if (value.isEmpty) {
                  _performSearch('');
                }
              },
            ),
          ),
          if (_isSearching)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (_errorMessage != null)
            Expanded(
              child: Center(
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            )
          else if (_searchResults.isEmpty && _searchController.text.isNotEmpty)
            const Expanded(
              child: Center(
                child: Text('No users found'),
              ),
            )
          else if (_searchResults.isEmpty)
            const Expanded(
              child: Center(
                child: Text('Search for users to add as friends'),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final profile = _searchResults[index];
                  return UserListTile(
                    profile: profile,
                    onAddFriend: () => _sendFriendRequest(profile),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
