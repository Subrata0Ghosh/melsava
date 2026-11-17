import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/experience_model.dart';

class ExperiencesRepository {
  List<ExperienceModel> _experiences = [
    ExperienceModel(
      id: 'exp-1',
      title: 'Weekend Trek to Mukutmanipur',
      description:
          'Explore nature, meet new people, and create unforgettable memories. A refreshing trekking experience with like-minded people. Perfect for nature lovers and weekend explorers!',
      categoryName: 'Outdoors',
      categoryIcon: '🥾',
      coverImageUrl: 'assets/images/hikers_mountain_trek.png',
      city: 'Mukutmanipur, Bankura',
      venueName: 'Mukutmanipur Lake Ridge',
      venueAddress: 'Bankura District, West Bengal',
      startsAt: DateTime.now().add(const Duration(days: 1, hours: 2)),
      durationMinutes: 180,
      maxParticipants: 20,
      currentParticipants: 18,
      hostName: 'Rohan Sen',
      hostAvatar: 'assets/images/rohan_avatar.png',
      attendeeAvatars: [
        'assets/images/sneha_avatar.png',
        'assets/images/aditi_avatar.png',
        'assets/images/priya_avatar.png',
        'assets/images/vikram_avatar.png',
      ],
      hasJoined: false,
    ),
    ExperienceModel(
      id: 'exp-2',
      title: 'Coffee & Conversation',
      description:
          'Meet a warm micro-group of 4-6 people, share interesting life stories, discuss favorite books, and enjoy relaxed conversations at a quiet artisan cafe.',
      categoryName: 'Social',
      categoryIcon: '☕',
      coverImageUrl: 'assets/images/coffee_latte_art.png',
      city: 'Park Street, Kolkata',
      venueName: 'Subko & Flurys Heritage Courtyard',
      venueAddress: '18 Park Street, Kolkata',
      startsAt: DateTime.now().add(const Duration(days: 1, hours: 4)),
      durationMinutes: 90,
      maxParticipants: 6,
      currentParticipants: 4,
      hostName: 'Sneha Roy',
      hostAvatar: 'assets/images/sneha_avatar.png',
      attendeeAvatars: [
        'assets/images/rohan_avatar.png',
        'assets/images/aditi_avatar.png',
        'assets/images/priya_avatar.png',
      ],
      hasJoined: false,
    ),
    ExperienceModel(
      id: 'exp-3',
      title: 'Artisan Baking & Culinary Tasting',
      description:
          'Hands-on artisan cooking session. Learn authentic techniques, whip up savory dishes together with new friends, and dine together at a shared table.',
      categoryName: 'Food & Drink',
      categoryIcon: '👨‍🍳',
      coverImageUrl: 'assets/images/sourdough_bread_art.png',
      city: 'Ballygunge, Kolkata',
      venueName: 'The Artisan Kitchen Studio',
      venueAddress: 'Ballygunge Circular Road, Kolkata',
      startsAt: DateTime.now().add(const Duration(days: 2, hours: 3)),
      durationMinutes: 120,
      maxParticipants: 12,
      currentParticipants: 10,
      hostName: 'Chef Ananya Roy',
      hostAvatar: 'assets/images/aditi_avatar.png',
      attendeeAvatars: [
        'assets/images/vikram_avatar.png',
        'assets/images/priya_avatar.png',
        'assets/images/sneha_avatar.png',
      ],
      hasJoined: false,
    ),
    ExperienceModel(
      id: 'exp-4',
      title: 'Badminton Doubles League',
      description:
          'Fast-paced social badminton doubles matches on a professional indoor court. Friendly rallies, great cardio, and rotating pairs.',
      categoryName: 'Sports',
      categoryIcon: '🏸',
      coverImageUrl: 'assets/images/badminton_court_play.png',
      city: 'Salt Lake, Kolkata',
      venueName: 'Central Park Sports Complex',
      venueAddress: 'Sector II, Salt Lake, Kolkata',
      startsAt: DateTime.now().add(const Duration(days: 2, hours: 6)),
      durationMinutes: 90,
      maxParticipants: 16,
      currentParticipants: 14,
      hostName: 'Vikram Sen',
      hostAvatar: 'assets/images/vikram_avatar.png',
      attendeeAvatars: [
        'assets/images/rohan_avatar.png',
        'assets/images/aditi_avatar.png',
        'assets/images/sneha_avatar.png',
      ],
      hasJoined: false,
    ),
    ExperienceModel(
      id: 'exp-5',
      title: 'Morning Yoga & Wellness',
      description:
          'Start your morning with restorative outdoor Vinyasa flow by the waterfront, gentle guided mindfulness, and herbal tea with like-minded individuals.',
      categoryName: 'Wellness',
      categoryIcon: '🧘‍♀️',
      coverImageUrl: 'assets/images/morning_yoga_zen.png',
      city: 'Eco Park, Kolkata',
      venueName: 'Lakeside Pavilion, Eco Park',
      venueAddress: 'Major Arterial Road, New Town, Kolkata',
      startsAt: DateTime.now().add(const Duration(days: 3, hours: 1)),
      durationMinutes: 75,
      maxParticipants: 15,
      currentParticipants: 12,
      hostName: 'Priya Sharma',
      hostAvatar: 'assets/images/priya_avatar.png',
      attendeeAvatars: [
        'assets/images/aditi_avatar.png',
        'assets/images/sneha_avatar.png',
      ],
      hasJoined: false,
    ),
    ExperienceModel(
      id: 'exp-6',
      title: 'Sunset Acoustic Jam & Open Mic',
      description:
          'Unwind with live acoustic music, friendly banter, and creative storytelling in an intimate lounge setting. Open to all music lovers!',
      categoryName: 'Arts & Culture',
      categoryIcon: '🎸',
      coverImageUrl: 'assets/images/concert_party_crowd.png',
      city: 'Indiranagar, Bengaluru',
      venueName: 'The Acoustic Den',
      venueAddress: '100ft Road, Indiranagar, Bengaluru',
      startsAt: DateTime.now().add(const Duration(days: 4, hours: 2)),
      durationMinutes: 120,
      maxParticipants: 8,
      currentParticipants: 6,
      hostName: 'Karan Joshi',
      hostAvatar: 'assets/images/vikram_avatar.png',
      attendeeAvatars: [
        'assets/images/aditi_avatar.png',
        'assets/images/rohan_avatar.png',
      ],
      hasJoined: false,
    ),
    ExperienceModel(
      id: 'exp-7',
      title: 'Mukutmanipur Weekend Nature Camp',
      description:
          'A weekend group getaway around Mukutmanipur confluence. Lakeside evening acoustic music, campfire storytelling, and starlit conversation.',
      categoryName: 'Outdoors',
      categoryIcon: '🏕️',
      coverImageUrl: 'assets/images/splash_scenic_backdrop.png',
      city: 'Mukutmanipur, Bankura',
      venueName: 'Lakeside Camp Gazebo',
      venueAddress: 'Kangsabati Dam, Bankura',
      startsAt: DateTime.now().subtract(const Duration(hours: 3)),
      durationMinutes: 120,
      maxParticipants: 6,
      currentParticipants: 6,
      hostName: 'Rohan Sen',
      hostAvatar: 'assets/images/rohan_avatar.png',
      attendeeAvatars: [
        'assets/images/sneha_avatar.png',
        'assets/images/priya_avatar.png',
        'assets/images/aditi_avatar.png',
      ],
      hasJoined: true,
      isCompleted: true,
    ),
    ExperienceModel(
      id: 'exp-8',
      title: 'Cycling Club Ride',
      description:
          'Scenic morning community bike ride through picturesque tree-lined boulevards and waterfront paths. Catch the fresh morning breeze, stay active, and connect with fellow cycling lovers over post-ride artisan breakfast!',
      categoryName: 'Sports',
      categoryIcon: '🚴',
      coverImageUrl: 'assets/images/badminton_court_play.png',
      city: 'Salt Lake, Kolkata',
      venueName: 'Central Park Greenways',
      venueAddress: 'Sector III, Salt Lake, Kolkata',
      startsAt: DateTime.now().add(const Duration(days: 2, hours: 2)),
      durationMinutes: 120,
      maxParticipants: 12,
      currentParticipants: 10,
      hostName: 'Rohan Sen',
      hostAvatar: 'assets/images/rohan_avatar.png',
      attendeeAvatars: [
        'assets/images/rohan_avatar.png',
        'assets/images/sneha_avatar.png',
        'assets/images/vikram_avatar.png',
        'assets/images/priya_avatar.png',
      ],
      hasJoined: false,
    ),
  ];

  List<ExperienceModel> getExperiences() => List.unmodifiable(_experiences);

  ExperienceModel? getById(String id) {
    return _experiences.firstWhere(
      (e) => e.id == id,
      orElse: () => _experiences.first,
    );
  }

  void toggleJoin(String id) {
    _experiences = _experiences.map((exp) {
      if (exp.id == id) {
        final newJoined = !exp.hasJoined;
        final newCount = newJoined
            ? exp.currentParticipants + 1
            : exp.currentParticipants - 1;
        return exp.copyWith(
          hasJoined: newJoined,
          currentParticipants: newCount.clamp(0, exp.maxParticipants),
        );
      }
      return exp;
    }).toList();
  }
}

final experiencesRepositoryProvider = Provider<ExperiencesRepository>((ref) {
  return ExperiencesRepository();
});

final experiencesListProvider = StateProvider<List<ExperienceModel>>((ref) {
  return ref.watch(experiencesRepositoryProvider).getExperiences();
});
