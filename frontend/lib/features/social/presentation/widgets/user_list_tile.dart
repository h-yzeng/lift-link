import 'package:flutter/material.dart';
import 'package:liftlink/features/profile/domain/entities/profile.dart';

/// Widget for displaying a user in a list with an action button
class UserListTile extends StatelessWidget {
  final Profile profile;
  final VoidCallback? onAddFriend;
  final VoidCallback? onViewProfile;
  final Widget? trailing;

  const UserListTile({
    super.key,
    required this.profile,
    this.onAddFriend,
    this.onViewProfile,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        backgroundImage: profile.hasAvatar
            ? NetworkImage(profile.avatarUrl!)
            : null,
        child: profile.hasAvatar
            ? null
            : Text(
                profile.initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
      title: Text(
        profile.displayNameOrUsername,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: profile.hasUsername && profile.hasCustomDisplayName
          ? Text('@${profile.username}')
          : null,
      trailing: trailing ??
          (onAddFriend != null
              ? IconButton(
                  icon: const Icon(Icons.person_add),
                  onPressed: onAddFriend,
                  tooltip: 'Send friend request',
                )
              : null),
      onTap: onViewProfile,
    );
  }
}
