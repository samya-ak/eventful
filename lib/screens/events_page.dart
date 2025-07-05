import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../l10n/app_strings.dart';
import '../models/event.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/section_header.dart';
import '../widgets/event_card.dart';
import 'create_event_page.dart';

class EventsPage extends StatelessWidget {
  const EventsPage({super.key});

  // Sample events data - In a real app, this would come from a service/repository
  static const List<Event> _sampleEvents = [
    Event(
      name: 'Summer Music Festival',
      description:
          'Join us for an amazing outdoor music festival featuring local and international artists. Experience great music, delicious food, and unforgettable memories under the stars.',
    ),
    Event(
      name: 'Tech Conference 2025',
      description:
          'Discover the latest in technology and innovation. Network with industry leaders and learn about cutting-edge developments in AI, blockchain, and more.',
    ),
    Event(
      name: 'Art Gallery Opening',
      description:
          'Explore contemporary art from emerging local artists. Wine and appetizers will be served.',
    ),
    Event(
      name: 'Cooking Workshop',
      description:
          'Learn to cook authentic Italian cuisine with professional chef Marco Rossi. All ingredients and equipment provided. Perfect for beginners and experienced cooks alike.',
    ),
    Event(
      name: 'Marathon Run',
      description:
          'Annual city marathon supporting local charities. Register now for early bird pricing.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: const CustomAppBar(),
      body: Padding(
        padding: EdgeInsets.all(AppConstants.x4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: AppStrings.eventsNearYouTitle,
              onCreatePressed: () => _handleCreateEvent(context),
            ),
            SizedBox(height: AppConstants.x4),
            Expanded(
              child: ListView.builder(
                itemCount: _sampleEvents.length,
                itemBuilder: (context, index) {
                  final event = _sampleEvents[index];
                  return EventCard(
                    event: event,
                    onTap: () => _handleEventTap(event),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleCreateEvent(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const CreateEventPage()));
  }

  void _handleEventTap(Event event) {
    // TODO: Navigate to event details page
    print('Event tapped: ${event.name}');
  }
}
