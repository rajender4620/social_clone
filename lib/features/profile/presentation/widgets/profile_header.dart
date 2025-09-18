import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfileHeader extends StatelessWidget {
  final String? profileImageUrl;
  final String displayName;
  final String username;
  final String bio;
  final bool isOwnProfile;
  final VoidCallback? onEditPressed;
  final VoidCallback? onFollowPressed;
  final VoidCallback? onMessagePressed;

  const ProfileHeader({
    super.key,
    this.profileImageUrl,
    required this.displayName,
    required this.username,
    required this.bio,
    required this.isOwnProfile,
    this.onEditPressed,
    this.onFollowPressed,
    this.onMessagePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile picture and basic info
          Row(
            children: [
              // Profile picture
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[300],
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                    width: 0.5,
                  ),
                ),
                child: ClipOval(
                  child: profileImageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: profileImageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[300],
                            child: Icon(
                              Icons.person,
                              size: 54,
                              color: Colors.grey[600],
                            ),
                          ),
                        )
                      : Icon(
                          Icons.person,
                          size: 54,
                          color: Colors.grey[600],
                        ),
                ),
              ),
              
              const SizedBox(width: 20),
              
              // Basic info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName.isNotEmpty ? displayName : username,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (displayName.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        '@$username',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          
          // Bio
          if (bio.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              bio,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          
          const SizedBox(height: 16),
          
          // Action buttons
          if (isOwnProfile)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onEditPressed,
                child: const Text('Edit Profile'),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onFollowPressed,
                    child: const Text('Follow'),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: onMessagePressed,
                  child: const Icon(Icons.message),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
