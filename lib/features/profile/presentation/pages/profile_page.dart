import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pumpkinsocial/features/follow/presentation/widgets/follow_button.dart';
import 'package:pumpkinsocial/features/follow/presentation/widgets/user_stats_widget.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';
import '../widgets/profile_posts_grid.dart';
import '../widgets/profile_edit_button.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';

class ProfilePage extends StatelessWidget {
  final String userId;

  const ProfilePage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (context) => ProfileBloc(
            profileRepository: context.read(),
            authBloc: context.read(),
          )..add(ProfileLoadRequested(userId: userId)),
      child: ProfileView(userId: userId),
    );
  }
}

class ProfileView extends StatefulWidget {
  final String userId;

  const ProfileView({super.key, required this.userId});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state.hasError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'An error occurred'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: () async {
              context.read<ProfileBloc>().add(
                ProfileRefreshRequested(userId: widget.userId),
              );
            },
            child: CustomScrollView(
              slivers: [
                // App bar
                SliverAppBar(
                  title: Text(
                    state.username.isNotEmpty
                        ? '@${state.username}'
                        : 'Profile',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  floating: true,
                  snap: true,
                  actions: [
                    if (state.isOwnProfile)
                      IconButton(
                        icon: const Icon(Icons.menu),
                        onPressed: () => _showProfileMenu(context),
                      ),
                  ],
                ),

                // Profile content
                if (state.isLoading)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (state.isLoaded) ...[
                  // Profile header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Profile info and stats
                          Row(
                            children: [
                              // Profile picture
                              ProfilePicture(
                                imageUrl: state.profileImageUrl,
                                size: 90,
                              ),
                              const SizedBox(width: 20),

                              // Stats
                              Expanded(
                                child: UserStatsWidget(
                                  userId: widget.userId,
                                  onFollowersTapped: () {
                                    // TODO: Navigate to followers list
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Followers list coming soon!',
                                        ),
                                      ),
                                    );
                                  },
                                  onFollowingTapped: () {
                                    // TODO: Navigate to following list
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Following list coming soon!',
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Display name and bio
                          if (state.displayName.isNotEmpty) ...[
                            Text(
                              state.displayName,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                          ],

                          if (state.bio.isNotEmpty) ...[
                            Text(
                              state.bio,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Action buttons
                          if (state.isOwnProfile)
                            ProfileEditButton(
                              onPressed: () => _showEditProfile(context),
                            )
                          else
                            Row(
                              children: [
                                Expanded(
                                  child: FollowButton(
                                    targetUserId: widget.userId,
                                    height: 36,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  height: 36,
                                  child: OutlinedButton(
                                    onPressed: () {
                                      // TODO: Implement message functionality
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Messages coming soon!',
                                          ),
                                        ),
                                      );
                                    },
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(
                                        color: Theme.of(context).dividerColor,
                                      ),
                                    ),
                                    child: const Icon(Icons.message),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Tab bar
                  SliverToBoxAdapter(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: Theme.of(context).dividerColor,
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        tabs: const [
                          Tab(icon: Icon(Icons.grid_on)),
                          Tab(icon: Icon(Icons.bookmark_border)),
                        ],
                        onTap: (index) {
                          context.read<ProfileBloc>().add(
                            ProfileTabChanged(tabIndex: index),
                          );
                        },
                      ),
                    ),
                  ),

                  // Posts grid
                  if (state.selectedTabIndex == 0)
                    ProfilePostsGrid(
                      posts: state.posts,
                      isLoading: state.arePostsLoading,
                      hasError: state.havePostsError,
                      errorMessage: state.postsErrorMessage,
                      hasMorePosts: state.hasMorePosts,
                      onLoadMore: () {
                        context.read<ProfileBloc>().add(
                          ProfilePostsLoadMoreRequested(userId: widget.userId),
                        );
                      },
                    )
                  else
                    // Bookmarks tab (placeholder)
                    const SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.bookmark_border,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Bookmarks',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Coming soon...',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                ] else
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            state.errorMessage ?? 'Something went wrong',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              context.read<ProfileBloc>().add(
                                ProfileLoadRequested(userId: widget.userId),
                              );
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showProfileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Edit Profile'),
                  onTap: () {
                    Navigator.pop(context);
                    _showEditProfile(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Settings'),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Navigate to settings
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Log Out'),
                  onTap: () {
                    Navigator.pop(context);
                    _showLogoutConfirmation(context);
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _showEditProfile(BuildContext context) {
    // TODO: Navigate to edit profile page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit profile coming soon...')),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    // Capture the AuthBloc reference before opening dialog
    final authBloc = context.read<AuthBloc>();
    
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Log Out'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                // Trigger logout using captured reference
                authBloc.add(const SignOutRequested());
              },
              child: const Text('Log Out'),
            ),
          ],
        );
      },
    );
  }
}

class ProfilePicture extends StatelessWidget {
  final String? imageUrl;
  final double size;

  const ProfilePicture({super.key, this.imageUrl, this.size = 90});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey[300],
        border: Border.all(color: Theme.of(context).dividerColor, width: 0.5),
      ),
      child: ClipOval(
        child:
            imageUrl != null
                ? CachedNetworkImage(
                  imageUrl: imageUrl!,
                  fit: BoxFit.cover,
                  placeholder:
                      (context, url) => Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                  errorWidget:
                      (context, url, error) => Container(
                        color: Colors.grey[300],
                        child: Icon(
                          Icons.person,
                          size: size * 0.6,
                          color: Colors.grey[600],
                        ),
                      ),
                )
                : Icon(Icons.person, size: size * 0.6, color: Colors.grey[600]),
      ),
    );
  }
}
