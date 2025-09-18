import 'dart:io';
import 'package:equatable/equatable.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

// Profile loading events
class ProfileLoadRequested extends ProfileEvent {
  final String userId;

  const ProfileLoadRequested({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class ProfileRefreshRequested extends ProfileEvent {
  final String userId;

  const ProfileRefreshRequested({required this.userId});

  @override
  List<Object?> get props => [userId];
}

// Profile posts events
class ProfilePostsLoadRequested extends ProfileEvent {
  final String userId;

  const ProfilePostsLoadRequested({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class ProfilePostsLoadMoreRequested extends ProfileEvent {
  final String userId;

  const ProfilePostsLoadMoreRequested({required this.userId});

  @override
  List<Object?> get props => [userId];
}

// Profile editing events
class ProfileEditRequested extends ProfileEvent {
  final String? displayName;
  final String? bio;
  final File? profileImage;

  const ProfileEditRequested({
    this.displayName,
    this.bio,
    this.profileImage,
  });

  @override
  List<Object?> get props => [displayName, bio, profileImage];
}

// Error handling
class ProfileErrorCleared extends ProfileEvent {
  const ProfileErrorCleared();
}

// Tab switching events
class ProfileTabChanged extends ProfileEvent {
  final int tabIndex;

  const ProfileTabChanged({required this.tabIndex});

  @override
  List<Object?> get props => [tabIndex];
}
