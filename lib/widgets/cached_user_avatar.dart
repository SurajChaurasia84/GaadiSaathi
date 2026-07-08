import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// A widget that displays a user's profile avatar, caching the photoUrl
/// from Firestore locally in memory to prevent flickering and excessive reads.
class CachedUserAvatar extends StatefulWidget {
  final String email;
  final double radius;
  final TextStyle? textStyle;
  final String fallbackInitial;

  const CachedUserAvatar({
    super.key,
    required this.email,
    this.radius = 10,
    this.textStyle,
    required this.fallbackInitial,
  });

  @override
  State<CachedUserAvatar> createState() => _CachedUserAvatarState();
}

class _CachedUserAvatarState extends State<CachedUserAvatar> {
  // Global memory cache to persist across screen transitions and rebuilds
  static final Map<String, String> _userPhotoCache = {};
  static final Map<String, Future<String?>> _pendingFetches = {};

  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    _loadPhoto();
  }

  @override
  void didUpdateWidget(CachedUserAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.email != widget.email) {
      _loadPhoto();
    }
  }

  void _loadPhoto() {
    if (widget.email.isEmpty) {
      setState(() {
        _photoUrl = null;
      });
      return;
    }

    if (_userPhotoCache.containsKey(widget.email)) {
      setState(() {
        _photoUrl = _userPhotoCache[widget.email];
      });
      return;
    }

    // Check if there is already a fetch in progress for this email
    Future<String?>? fetch = _pendingFetches[widget.email];
    if (fetch == null) {
      fetch = FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: widget.email)
          .limit(1)
          .get()
          .then((snapshot) {
            String? url;
            if (snapshot.docs.isNotEmpty) {
              url = snapshot.docs.first.data()['photoUrl'] as String?;
            }
            // Store empty string if null to mark it as loaded
            _userPhotoCache[widget.email] = url ?? '';
            _pendingFetches.remove(widget.email);
            return url;
          }).catchError((e) {
            _pendingFetches.remove(widget.email);
            return null;
          });
      _pendingFetches[widget.email] = fetch;
    }

    fetch.then((url) {
      if (mounted) {
        setState(() {
          _photoUrl = url;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = _photoUrl != null && _photoUrl!.isNotEmpty;
    
    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: const Color(0xFF536DFE).withValues(alpha: 0.15),
      backgroundImage: hasPhoto ? NetworkImage(_photoUrl!) : null,
      child: hasPhoto
          ? null
          : Text(
              widget.fallbackInitial.isNotEmpty ? widget.fallbackInitial[0].toUpperCase() : '?',
              style: widget.textStyle ?? TextStyle(
                color: const Color(0xFF536DFE),
                fontWeight: FontWeight.bold,
                fontSize: widget.radius * 0.9,
              ),
            ),
    );
  }
}
