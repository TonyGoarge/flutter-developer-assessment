// =============================================================================
// EXERCISE 1: UI & Layout — "Room Card Widget" (FIXED & IMPROVED)
// =============================================================================

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

// ---------------------------------------------------------------------------
// DATA MODEL (unchanged)
// ---------------------------------------------------------------------------

class RoomEntity {
  final int id;
  final String roomName;
  final String? roomIntro;
  final String? coverUrl;
  final int visitorsCount;
  final String? countryFlag;
  final bool isLive;
  final bool hasPassword;
  final String? ownerName;
  final String? ownerAvatarUrl;

  const RoomEntity({
    required this.id,
    required this.roomName,
    this.roomIntro,
    this.coverUrl,
    this.visitorsCount = 0,
    this.countryFlag,
    this.isLive = false,
    this.hasPassword = false,
    this.ownerName,
    this.ownerAvatarUrl,
  });
}

// ---------------------------------------------------------------------------
// SAMPLE DATA (unchanged)
// ---------------------------------------------------------------------------

final sampleRooms = [
  RoomEntity(
    id: 1,
    roomName: 'Welcome to the Super Amazing Party Room 🎉🎉🎉',
    roomIntro: 'Join us for music and fun! Everyone is welcome.',
    coverUrl: 'https://picsum.photos/200/200',
    visitorsCount: 1234,
    countryFlag: '🇺🇸',
    isLive: true,
    hasPassword: false,
    ownerName: 'DJ_Master',
    ownerAvatarUrl: 'https://picsum.photos/50/50',
  ),
  RoomEntity(
    id: 2,
    roomName: 'Chill Zone',
    roomIntro: null,
    coverUrl: null,
    visitorsCount: 0,
    countryFlag: '🇹🇷',
    isLive: false,
    hasPassword: true,
    ownerName: 'Relaxer',
  ),
  RoomEntity(
    id: 3,
    roomName: 'Gaming Arena - Competitive Matches Every Hour - Join Now!',
    roomIntro: 'Competitive gaming room with hourly tournaments and prizes for top players',
    coverUrl: 'https://picsum.photos/200/201',
    visitorsCount: 56789,
    countryFlag: null,
    isLive: true,
    hasPassword: false,
  ),
];

// ---------------------------------------------------------------------------
// FIXED & IMPROVED IMPLEMENTATION
// ---------------------------------------------------------------------------

class RoomCardList extends StatelessWidget {
  const RoomCardList({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rooms')), // FIX: const Text
      body: ListView.builder( // FIX: Use builder for performance/lazy loading
        itemCount: sampleRooms.length,
        itemBuilder: (context, index) => RoomCard(room: sampleRooms[index]),
      ),
    );
  }
}

class RoomCard extends StatelessWidget {
  final RoomEntity room;

  const RoomCard({super.key, required this.room}); // FIX: const constructor + key

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width; // FIX: responsive
    final imageSize = screenWidth * 0.22; // ~22% of screen width, responsive

    return RepaintBoundary( // SENIOR: isolate repaints per card
      child: Container(
        margin: const EdgeInsets.symmetric( // FIX: const
          horizontal: 12,
          vertical: 6,
        ),
        padding: const EdgeInsets.all(8), 
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000), // FIX: const + proper shadow opacity
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Cover Image (FIX: wrapped in Stack, null-safe, with shimmer) ---
            _CoverImage(
              coverUrl: room.coverUrl,
              isLive: room.isLive,
              size: imageSize,
            ),

            const SizedBox(width: 10), // FIX: spacing between image and text

            // FIX: Expanded so the column doesn't overflow
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: Room Name + Visitor Count
                  Row(
                    children: [
                      Expanded( // FIX: Expanded to prevent text overflow
                        child: Text(
                          room.roomName,
                          style: const TextStyle( // FIX: const
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis, // FIX: ellipsis
                        ),
                      ),
                      const SizedBox(width: 6), // FIX: spacing
                      _VisitorCount(count: room.visitorsCount),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Row 2: Room Intro (FIX: null-safe, maxLines, overflow)
                  if (room.roomIntro != null) // FIX: only show if non-null
                    Text(
                      room.roomIntro!, // safe after null check
                      style: const TextStyle( // FIX: const
                        fontSize: 12,
                        color: AppColors.greyText,
                      ),
                      maxLines: 2, // FIX: limit lines
                      overflow: TextOverflow.ellipsis, // FIX: handle overflow
                    ),

                  const SizedBox(height: 4),

                  // Row 3: Country + Lock icon (FIX: null-safe flag)
                  Row(
                    children: [
                      if (room.countryFlag != null) // FIX: null check
                        Text(
                          room.countryFlag!,
                          style: const TextStyle(fontSize: 16), // FIX: const
                        ),
                      if (room.countryFlag != null && room.hasPassword)
                        const SizedBox(width: 4), // spacing only when both present
                      if (room.hasPassword)
                        const Icon( // FIX: const
                          Icons.lock,
                          size: 14,
                          color: AppColors.primary,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SENIOR: Reusable CachedImage widget with loading/error/success states
// ---------------------------------------------------------------------------

class CachedImage extends StatelessWidget {
  final String? url;
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const CachedImage({
    super.key,
    required this.url,
    required this.width,
    required this.height,
    this.borderRadius,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    final Widget imageWidget = _buildImage();

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }
    return imageWidget;
  }

  Widget _buildImage() {
    if (url == null || url!.isEmpty) {
      return _buildErrorState();
    }

    return CachedNetworkImage(
      imageUrl: url!,
      width: width,
      height: height,
      fit: fit,
      placeholder: (_, __) => placeholder ?? _buildShimmer(),
      errorWidget: (_, __, ___) => errorWidget ?? _buildErrorState(),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: Container(
        width: width,
        height: height,
        color: AppColors.shimmerBase,
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      width: width,
      height: height,
      color: AppColors.shimmerBase,
      child: const Icon(Icons.image_not_supported_outlined, color: AppColors.greyText),
    );
  }
}

// ---------------------------------------------------------------------------
// Cover image with LIVE badge (using Stack correctly)
// ---------------------------------------------------------------------------

class _CoverImage extends StatelessWidget {
  final String? coverUrl;
  final bool isLive;
  final double size;

  const _CoverImage({
    required this.coverUrl,
    required this.isLive,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Stack( // FIX: Positioned must be inside Stack
      children: [
        CachedImage(
          url: coverUrl,
          width: size,
          height: size,
          borderRadius: BorderRadius.circular(8),
        ),
        if (isLive)
          Positioned(
            top: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2), // FIX: const
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text( // FIX: const
                'LIVE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Visitor count with number formatting
// ---------------------------------------------------------------------------

class _VisitorCount extends StatelessWidget {
  final int count;

  const _VisitorCount({required this.count}); // FIX: const constructor

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.visibility, size: 12, color: AppColors.greyText), // FIX: const
        const SizedBox(width: 2), // FIX: const
        Text(
          _formatCount(count), // FIX: formatted number (e.g. 1.2K, 56.8K)
          style: const TextStyle( // FIX: const
            fontSize: 10,
            color: AppColors.greyText,
          ),
        ),
      ],
    );
  }

  /// Formats large counts: 1234 → "1.2K", 56789 → "56.8K", 1200000 → "1.2M"
  String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

// ---------------------------------------------------------------------------
// Color constants
// ---------------------------------------------------------------------------

class AppColors {
  static const white = Color(0xFFFFFFFF);
  static const black = Color(0xFF000000);
  static const greyText = Color(0xFFa5a7a4);
  static const primary = Color(0xFF32e5ac);
  static const shimmerBase = Color(0xFFE0E0E0);
  static const shimmerHighlight = Color(0xFFF5F5F5);
}