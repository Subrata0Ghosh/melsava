import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/experience_model.dart';

class ExperiencesRepository {
  List<ExperienceModel> _experiences = [
    ExperienceModel(
      id: 'exp-1',
      title: 'Coffee & Conversation: Weekend Musings',
      description:
          'Meet a small group of 4 people, share interesting life stories, discuss favorite books, and enjoy relaxed conversations at a quiet artisan cafe.',
      categoryName: 'Coffee & Conversation',
      categoryIcon: '☕',
      coverImageUrl:
          'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?auto=format&fit=crop&w=800&q=80',
      city: 'Bandra West, Mumbai',
      venueName: 'Subko Coffee Roasters',
      venueAddress: 'Craft Coffee Courtyard, Bandra West',
      startsAt: DateTime.now().add(const Duration(days: 1, hours: 3)),
      durationMinutes: 90,
      maxParticipants: 4,
      currentParticipants: 3,
      hostName: 'Aarav Mehta',
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
      id: 'exp-2',
      title: 'Heritage Photography Walk: Old Fort',
      description:
          'Explore the architectural alleys of South Mumbai, exchange photography tips with fellow creators, and capture authentic city moments.',
      categoryName: 'Photography',
      categoryIcon: '📷',
      coverImageUrl:
          'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?auto=format&fit=crop&w=800&q=80',
      city: 'Fort, Mumbai',
      venueName: 'Kala Ghoda Art Precinct',
      venueAddress: 'Steps of Asiatic Library, Fort',
      startsAt: DateTime.now().add(const Duration(days: 2, hours: 5)),
      durationMinutes: 120,
      maxParticipants: 5,
      currentParticipants: 4,
      hostName: 'Rhea Sen',
      hostAvatar:
          'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=200&q=80',
      attendeeAvatars: [
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=200&q=80',
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=200&q=80',
        'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=200&q=80',
        'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=200&q=80',
      ],
      hasJoined: false,
    ),
    ExperienceModel(
      id: 'exp-3',
      title: 'Board Game Evening: Catan & Strategy',
      description:
          'Unwind on a weekday evening with strategy board games in a cozy tabletop cafe. Friendly matches, good banter, and zero experience required!',
      categoryName: 'Board Games',
      categoryIcon: '🎲',
      coverImageUrl:
          'https://images.unsplash.com/photo-1610890716171-6b1bb98ffd09?auto=format&fit=crop&w=800&q=80',
      city: 'Koramangala, Bengaluru',
      venueName: 'The Board Game Den',
      venueAddress: '5th Block, Koramangala',
      startsAt: DateTime.now().add(const Duration(days: 3, hours: 2)),
      durationMinutes: 120,
      maxParticipants: 4,
      currentParticipants: 2,
      hostName: 'Karan Joshi',
      hostAvatar:
          'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=200&q=80',
      attendeeAvatars: [
        'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=200&q=80',
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=200&q=80',
      ],
      hasJoined: false,
    ),
    ExperienceModel(
      id: 'exp-4',
      title: 'Morning Nature Walk & Bird Watching',
      description:
          'A tranquil sunrise walk through lush trails. Breathe fresh morning air, spot local migratory birds, and enjoy a restorative nature stroll together.',
      categoryName: 'Nature Walks',
      categoryIcon: '🌿',
      coverImageUrl:
          'https://images.unsplash.com/photo-1448375240586-882707db888b?auto=format&fit=crop&w=800&q=80',
      city: 'Sanjay Gandhi National Park, Mumbai',
      venueName: 'Main Forest Trail Gate',
      venueAddress: 'Borivali East',
      startsAt: DateTime.now().add(const Duration(days: 4, hours: 1)),
      durationMinutes: 100,
      maxParticipants: 5,
      currentParticipants: 3,
      hostName: 'Dr. Siddharth Rao',
      hostAvatar:
          'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&w=200&q=80',
      attendeeAvatars: [
        'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=200&q=80',
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=200&q=80',
        'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=200&q=80',
      ],
      hasJoined: false,
    ),
    ExperienceModel(
      id: 'exp-5',
      title: 'Beginner Badminton & Court Rally',
      description:
          'Casual, friendly mixed doubles badminton matches at an indoor wooden court. Focus is strictly on having fun and moving together, not intense competition.',
      categoryName: 'Sports & Fitness',
      categoryIcon: '🏸',
      coverImageUrl:
          'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?auto=format&fit=crop&w=800&q=80',
      city: 'Indiranagar, Bengaluru',
      venueName: 'Smash Sports Arena',
      venueAddress: '100ft Road, Indiranagar',
      startsAt: DateTime.now().add(const Duration(days: 5, hours: 4)),
      durationMinutes: 90,
      maxParticipants: 4,
      currentParticipants: 3,
      hostName: 'Vikram Patel',
      hostAvatar:
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=200&q=80',
      attendeeAvatars: [
        'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?auto=format&fit=crop&w=200&q=80',
        'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=200&q=80',
        'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=200&q=80',
      ],
      hasJoined: false,
    ),
    ExperienceModel(
      id: 'exp-6',
      title: 'Book Lovers Circle: Contemporary Fiction',
      description:
          'Bring a favorite book you read recently. We take turns sharing memorable passages, thematic reflections, and discovering new literary recommendations.',
      categoryName: 'Reading & Book Clubs',
      categoryIcon: '📚',
      coverImageUrl:
          'https://images.unsplash.com/photo-1495446815901-a7297e633e8d?auto=format&fit=crop&w=800&q=80',
      city: 'Churchgate, Mumbai',
      venueName: 'Kitab Khana Bookstore Cafe',
      venueAddress: 'Somaiya Bhavan, Fort',
      startsAt: DateTime.now().subtract(
        const Duration(hours: 4),
      ), // Completed experience for testing!
      durationMinutes: 90,
      maxParticipants: 4,
      currentParticipants: 4,
      hostName: 'Ananya Sharma',
      hostAvatar:
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=200&q=80',
      attendeeAvatars: [
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=200&q=80',
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=200&q=80',
        'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=200&q=80',
        'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=200&q=80',
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
