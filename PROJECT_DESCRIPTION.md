# 📱 PumpkinSocial - Instagram-Style Social Media App

## 📌 Project Description

PumpkinSocial is a lightweight Instagram-style social media app built with Flutter and Firebase. This project showcases full-stack mobile development with modern app architecture and polished UI/UX.

## 🎯 Core Features

### 🔑 1. Authentication & Onboarding
- **Email/Google sign-in** (Firebase Auth)
- **User profile setup**: username, bio, profile picture
- **Edit profile option**

### 📰 2. Feed System
- **Home feed**: posts from followed users (real-time + pagination)
- **Post detail view** (image, caption, likes, comments, timestamp)
- **Pull-to-refresh** + skeleton loaders

### 📤 3. Post Creation & Management
- **Upload image** from camera/gallery
- **Add caption** (and optional location)
- **Upload progress indicator**
- **Store media** in Firebase Storage + Firestore

### ❤️ 4. Social Interactions
- **Like/unlike posts** (real-time counter update)
- **Add & view comments** (live refresh)
- **Follow/unfollow users**
- **Show follower/following counts**

### 👤 5. Profile
- **Profile page**: picture, username, bio, follower/following counts
- **User's posts** shown in grid layout
- **Tap post** → open post detail

### 🔔 6. Notifications
- **Push notifications** (via FCM) for:
  - New follower
  - Post liked
  - Post commented
- **In-app activity feed** for notifications

### 🎨 7. UI/UX Enhancements
- **Dark/Light theme** toggle
- **Cached images** for smooth scrolling
- **Animations** (like button burst, Hero transitions)
- **Responsive design** for different screen sizes

## 🏗️ Technical Stack

- **Frontend**: Flutter
- **Backend**: Firebase
  - Authentication: Firebase Auth
  - Database: Cloud Firestore
  - Storage: Firebase Storage
  - Notifications: FCM
- **State Management**: BLoC Pattern
- **Routing**: GoRouter
- **Architecture**: Feature-based structure

## 🚀 Development Approach

This project demonstrates:
- **Full-stack mobile development** with Flutter + Firebase
- **Core social media features** (auth, feed, post creation, interactions, notifications)
- **Clean app architecture** (BLoC + feature-based structure)
- **Polished UI/UX** for a real-world portfolio demo

## 📁 Project Structure

```
lib/
├── core/           # Core utilities, constants, themes
├── features/       # Feature-based modules
│   ├── auth/       # Authentication & user management
│   ├── feed/       # Home feed & posts
│   ├── profile/    # User profiles
│   ├── post/       # Post creation & management
│   └── notifications/ # Push notifications
├── shared/         # Shared widgets & services
└── main.dart       # App entry point
```

## 🎯 Current Focus: Authentication & Onboarding

We're starting with implementing the authentication system, including:
- Email and Google sign-in
- User registration and profile creation
- Profile editing capabilities
- Secure session management
