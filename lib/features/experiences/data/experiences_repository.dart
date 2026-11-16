import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/experience_model.dart';

class ExperiencesRepository {
  List<ExperienceModel> _experiences = [
    ExperienceModel(
      id: 'exp-1',
      title: 'Trekking to Mukutmanipur',
      description:
          'Explore nature, meet new people, and create unforgettable memories. A refreshing trekking experience with like-minded people. Perfect for nature lovers and weekend explorers!',
      categoryName: 'Outdoors',
      categoryIcon: '🥾',
      coverImageUrl:
          'https://images.unsplash.com/photo-1551632811-561732d1e306?auto=format&fit=crop&w=800&q=80',
      city: 'Mukutmanipur, Bankura',
      venueName: 'Mukutmanipur Lake Ridge',
      venueAddress: 'Bankura District, West Bengal',
      startsAt: DateTime.now().add(const Duration(days: 1, hours: 2)),
      durationMinutes: 180,
      maxParticipants: 20,
      currentParticipants: 18,
      hostName: 'Rohan Sen',
      hostAvatar:
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=200&q=80',
      attendeeAvatars: [
        'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=200&q=80',
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=200&q=80',
        'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=200&q=80',
        'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?auto=format&fit=crop&w=200&q=80',
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
      coverImageUrl:
          'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?auto=format&fit=crop&w=800&q=80',
      city: 'Park Street, Kolkata',
      venueName: 'Subko & Flurys Heritage Courtyard',
      venueAddress: '18 Park Street, Kolkata',
      startsAt: DateTime.now().add(const Duration(days: 1, hours: 4)),
      durationMinutes: 90,
      maxParticipants: 6,
      currentParticipants: 4,
      hostName: 'Sneha Roy',
      hostAvatar:
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=200&q=80',
      attendeeAvatars: [
        'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=200&q=80',
        'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?auto=format&fit=crop&w=200&q=80',
        'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=200&q=80',
      ],
      hasJoined: false,
    ),
    ExperienceModel(
      id: 'exp-3',
      title: 'Cooking Class & Culinary Tasting',
      description:
          'Hands-on artisan cooking session. Learn authentic techniques, whip up savory dishes together with new friends, and dine together at a shared table.',
      categoryName: 'Food & Drink',
      categoryIcon: '👨‍🍳',
      coverImageUrl:
          'https://images.unsplash.com/photo-1556910103-1c02745aae4d?auto=format&fit=crop&w=800&q=80',
      city: 'Ballygunge, Kolkata',
      venueName: 'The Artisan Kitchen Studio',
      venueAddress: 'Ballygunge Circular Road, Kolkata',
      startsAt: DateTime.now().add(const Duration(days: 2, hours: 3)),
      durationMinutes: 120,
      maxParticipants: 12,
      currentParticipants: 10,
      hostName: 'Chef Ananya Roy',
      hostAvatar:
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=200&q=80',
      attendeeAvatars: [
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=200&q=80',
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=200&q=80',
        'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=200&q=80',
      ],
      hasJoined: false,
    ),
    ExperienceModel(
      id: 'exp-4',
      title: 'Cycling Club Ride',
      description:
          'Scenic evening ride around the lakes and tree-lined boulevards. Steady social pace with refreshment stops and open conversations.',
      categoryName: 'Sports',
      categoryIcon: '🚴',
      coverImageUrl:
          'https://images.unsplash.com/photo-1517649763962-0c623266ddc0?auto=format&fit=crop&w=800&q=80',
      city: 'Salt Lake, Kolkata',
      venueName: 'Central Park Cycling Trail',
      venueAddress: 'Sector II, Salt Lake, Kolkata',
      startsAt: DateTime.now().add(const Duration(days: 2, hours: 6)),
      durationMinutes: 90,
      maxParticipants: 16,
      currentParticipants: 14,
      hostName: 'Vikram Sen',
      hostAvatar:
          'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=200&q=80',
      attendeeAvatars: [
        'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=200&q=80',
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=200&q=80',
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
      coverImageUrl:
          'https://images.unsplash.com/photo-1506126613408-eca07ce68773?auto=format&fit=crop&w=800&q=80',
      city: 'Eco Park, Kolkata',
      venueName: 'Lakeside Pavilion, Eco Park',
      venueAddress: 'Major Arterial Road, New Town, Kolkata',
      startsAt: DateTime.now().add(const Duration(days: 3, hours: 1)),
      durationMinutes: 75,
      maxParticipants: 15,
      currentParticipants: 12,
      hostName: 'Priya Sharma',
      hostAvatar:
          'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=200&q=80',
      attendeeAvatars: [
        'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=200&q=80',
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=200&q=80',
      ],
      hasJoined: false,
    ),
    ExperienceModel(
      id: 'exp-6',
      title: 'Board Game & Strategy Evening',
      description:
          'Unwind on a weekday evening with strategy board games in a cozy tabletop lounge. Friendly matches, good banter, and zero experience required!',
      categoryName: 'Arts & Culture',
      categoryIcon: '🎲',
      coverImageUrl:
          'https://images.unsplash.com/photo-1610890716171-6b1bb98ffd09?auto=format&fit=crop&w=800&q=80',
      city: 'Indiranagar, Bengaluru',
      venueName: 'The Board Game Den',
      venueAddress: '100ft Road, Indiranagar, Bengaluru',
      startsAt: DateTime.now().add(const Duration(days: 4, hours: 2)),
      durationMinutes: 120,
      maxParticipants: 8,
      currentParticipants: 6,
      hostName: 'Karan Joshi',
      hostAvatar:
          'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&w=200&q=80',
      attendeeAvatars: [
        'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=200&q=80',
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=200&q=80',
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
      coverImageUrl:
          'https://images.unsplash.com/photo-1478131143081-80f7f84ca84d?auto=format&fit=crop&w=800&q=80',
      city: 'Mukutmanipur, Bankura',
      venueName: 'Lakeside Camp Gazebo',
      venueAddress: 'Kangsabati Dam, Bankura',
      startsAt: DateTime.now().subtract(const Duration(hours: 3)),
      durationMinutes: 120,
      maxParticipants: 6,
      currentParticipants: 6,
      hostName: 'Rohan Sen',
      hostAvatar:
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=200&q=80',
      attendeeAvatars: [
        'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=200&q=80',
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=200&q=80',
        'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=200&q=80',
      ],
      hasJoined: true,
      isCompleted: true,
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
