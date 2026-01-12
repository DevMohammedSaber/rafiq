import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// User profile model for both authenticated and guest users
class UserProfile extends Equatable {
  /// User ID (null for guest)
  final String? uid;

  /// Display name
  final String name;

  /// Email address (null for guest)
  final String? email;

  /// Profile photo URL
  final String? photoUrl;

  /// Whether this is a guest user
  final bool isGuest;

  /// Account creation date (auth users only)
  final DateTime? createdAt;

  /// Last login date (auth users only)
  final DateTime? lastLoginAt;

  /// Auth provider ("google", "apple", or null for guest)
  final String? provider;

  /// Optional bio
  final String? bio;

  /// Country code
  final String? countryCode;

  const UserProfile({
    this.uid,
    required this.name,
    this.email,
    this.photoUrl,
    required this.isGuest,
    this.createdAt,
    this.lastLoginAt,
    this.provider,
    this.bio,
    this.countryCode,
  });

  /// Create a default guest profile
  factory UserProfile.guest({String name = 'Guest'}) {
    return UserProfile(
      uid: null,
      name: name,
      email: null,
      photoUrl: null,
      isGuest: true,
      createdAt: null,
      lastLoginAt: null,
      provider: null,
      bio: null,
      countryCode: null,
    );
  }

  /// Create from Firebase Auth user and optional Firestore data
  factory UserProfile.fromFirebaseUser({
    required String uid,
    required String? displayName,
    required String? email,
    required String? photoUrl,
    required String? provider,
    Map<String, dynamic>? firestoreData,
  }) {
    DateTime? createdAt;
    DateTime? lastLoginAt;
    String? bio;
    String? countryCode;

    if (firestoreData != null) {
      if (firestoreData['createdAt'] is Timestamp) {
        createdAt = (firestoreData['createdAt'] as Timestamp).toDate();
      }
      if (firestoreData['lastLoginAt'] is Timestamp) {
        lastLoginAt = (firestoreData['lastLoginAt'] as Timestamp).toDate();
      }
      bio = firestoreData['profile']?['bio'] as String?;
      countryCode = firestoreData['profile']?['countryCode'] as String?;
    }

    return UserProfile(
      uid: uid,
      name: firestoreData?['name'] as String? ?? displayName ?? 'User',
      email: email,
      photoUrl: firestoreData?['photoUrl'] as String? ?? photoUrl,
      isGuest: false,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt,
      provider: firestoreData?['provider'] as String? ?? provider,
      bio: bio,
      countryCode: countryCode,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      uid: json['uid'] as String?,
      name: json['name'] as String? ?? 'Guest',
      email: json['email'] as String?,
      photoUrl: json['photoUrl'] as String?,
      isGuest: json['isGuest'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.tryParse(json['lastLoginAt'] as String)
          : null,
      provider: json['provider'] as String?,
      bio: json['bio'] as String?,
      countryCode: json['countryCode'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'isGuest': isGuest,
      'createdAt': createdAt?.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'provider': provider,
      'bio': bio,
      'countryCode': countryCode,
    };
  }

  /// Convert to Firestore document data
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'provider': provider,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),
      'profile': {'bio': bio, 'countryCode': countryCode},
    };
  }

  UserProfile copyWith({
    String? uid,
    String? name,
    String? email,
    String? photoUrl,
    bool? isGuest,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    String? provider,
    String? bio,
    String? countryCode,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      isGuest: isGuest ?? this.isGuest,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      provider: provider ?? this.provider,
      bio: bio ?? this.bio,
      countryCode: countryCode ?? this.countryCode,
    );
  }

  /// Get provider display name
  String get providerDisplayName {
    switch (provider) {
      case 'google':
        return 'Google';
      case 'apple':
        return 'Apple';
      default:
        return 'Email';
    }
  }

  /// Get avatar placeholder URL
  String get avatarUrl {
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return photoUrl!;
    }
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'G';
    return 'https://ui-avatars.com/api/?name=$initials&background=006D5B&color=fff&size=200';
  }

  @override
  List<Object?> get props => [
    uid,
    name,
    email,
    photoUrl,
    isGuest,
    createdAt,
    lastLoginAt,
    provider,
    bio,
    countryCode,
  ];
}
