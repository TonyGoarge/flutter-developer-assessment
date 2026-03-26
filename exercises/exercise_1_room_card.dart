// =============================================================================
// EXERCISE 1: UI & Layout — "Room Card Widget"
// Time: 30 minutes
// =============================================================================
//
// SCENARIO:
// You're building a social/live-streaming app. The home screen shows a list
// of active rooms. Each room is displayed as a card with the room's cover image,
// name, intro text, visitor count, country flag, and status icons.
//
// The previous developer left a broken implementation. Your job is to fix it
// and improve it.
//
// TASKS:
// 1. [All Levels] Fix the layout bugs (overflow, alignment, null handling)
// 2. [Mid+] Add a shimmer loading state for the image
// 3. [Mid+] Make the card responsive (don't use hardcoded pixel values)
// 4. [Senior] Add const constructors throughout where possible
// 5. [Senior] Create a reusable CachedImage widget with loading/error/success states
// 6. [Senior] Add RepaintBoundary where appropriate
//
// RULES:
// - You may add any Flutter/Dart packages you need (shimmer, cached_network_image, etc.)
// - Focus on code quality, not just making it "work"
// - Consider edge cases (null data, long text, missing images)
// =============================================================================

import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// DATA MODEL (do not modify)
// ---------------------------------------------------------------------------

class RoomEntity {
  final int id;
  final String roomName;
  final String? roomIntro;
  final String? coverUrl;
  final int visitorsCount;
  final String? countryFlag; // emoji flag like "🇺🇸"
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
// SAMPLE DATA (do not modify)
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
    roomIntro: null, // No intro set
    coverUrl: null, // No cover image
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
    countryFlag: null, // No country
    isLive: true,
    hasPassword: false,
  ),
];

// ---------------------------------------------------------------------------
// BROKEN IMPLEMENTATION (fix this)
// ---------------------------------------------------------------------------

class RoomCardList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Rooms')),
      body: ListView(
        // BUG: Should use ListView.builder for performance
        children: sampleRooms.map((room) => RoomCard(room: room)).toList(),
      ),
    );
  }
}

class RoomCard extends StatelessWidget {
  final RoomEntity room;

  // BUG: Missing const constructor
  RoomCard({required this.room});

  @override
  Widget build(BuildContext context) {
    return Container(
      // BUG: Hardcoded margin and dimensions
      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      padding: EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        boxShadow: [
          BoxShadow(
            color: Colors.grey,
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // --- Cover Image ---
          // BUG: No loading state, no error handling, no placeholder
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                // BUG: Will crash if coverUrl is null
                image: NetworkImage(room.coverUrl!),
                fit: BoxFit.cover,
              ),
            ),
            child: room.isLive
                ? Positioned(
                    // BUG: Positioned outside of Stack
                    top: 0,
                    left: 0,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'LIVE',
                        style: TextStyle(color: Colors.white, fontSize: 8),
                      ),
                    ),
                  )
                : null,
          ),
          // BUG: No spacing between image and text
          // --- Room Info ---
          Column(
            // BUG: Column not wrapped in Expanded, will overflow
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Room Name + Visitor Count
              Row(
                children: [
                  // BUG: Text will overflow on long names
                  Text(
                    room.roomName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  // BUG: No spacing
                  _VisitorCount(count: room.visitorsCount),
                ],
              ),
              // Row 2: Room Intro
              Text(
                // BUG: Will show "null" if roomIntro is null
                room.roomIntro.toString(),
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFFa5a7a4),
                ),
                // BUG: No maxLines or overflow handling
              ),
              // Row 3: Country + Lock icon
              Row(
                children: [
                  // BUG: Will show "null" text if no country flag
                  Text(room.countryFlag.toString(), style: TextStyle(fontSize: 16)),
                  // BUG: No spacing
                  if (room.hasPassword)
                    Icon(Icons.lock, size: 14, color: Color(0xFF32e5ac)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VisitorCount extends StatelessWidget {
  final int count;

  // BUG: Missing const, missing key
  _VisitorCount({required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.visibility, size: 12, color: Colors.grey),
        SizedBox(width: 2),
        Text(
          // BUG: Should format large numbers (1234 → 1.2K)
          count.toString(),
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// BONUS: Color constants (for reference)
// ---------------------------------------------------------------------------

class AppColors {
  static const white = Color(0xFFFFFFFF);
  static const black = Color(0xFF000000);
  static const greyText = Color(0xFFa5a7a4);
  static const primary = Color(0xFF32e5ac);
  static const shimmerBase = Color(0xFFE0E0E0);
  static const shimmerHighlight = Color(0xFFF5F5F5);
}
