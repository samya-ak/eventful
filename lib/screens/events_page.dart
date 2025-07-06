import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../l10n/app_strings.dart';
import '../models/event.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/section_header.dart';
import '../widgets/event_card.dart';
import '../services/supabase_service.dart';
import 'create_event_page.dart';
import 'event_detail_page.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  List<Event> _events = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final eventsData = await SupabaseService.getEventsWithImages();
      final events = eventsData.map((data) => Event.fromJson(data)).toList();

      setState(() {
        _events = events;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      print('Error loading events: $e');
    }
  }

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
            Expanded(child: _buildEventsList()),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsList() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_events.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadEvents,
      child: ListView.builder(
        itemCount: _events.length,
        itemBuilder: (context, index) {
          final event = _events[index];
          return EventCard(event: event, onTap: () => _handleEventTap(event));
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.button),
          SizedBox(height: 16),
          Text(
            'Loading events...',
            style: TextStyle(color: AppColors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.white),
          const SizedBox(height: 16),
          const Text(
            'Error loading events',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Unknown error occurred',
            style: const TextStyle(color: AppColors.white, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadEvents,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.button,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.event_busy, size: 64, color: AppColors.white),
          const SizedBox(height: 16),
          const Text(
            'No events found',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Be the first to create an event!',
            style: TextStyle(color: AppColors.white, fontSize: 14),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _handleCreateEvent(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.button,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Create Event'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCreateEvent(BuildContext context) async {
    final result = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const CreateEventPage()));

    // If an event was created successfully, refresh the list
    if (result == true) {
      _loadEvents();
    }
  }

  void _handleEventTap(Event event) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EventDetailPage(
          eventId: event.eventId ?? 'unknown',
          eventName: event.name,
          eventDescription: event.description,
          eventImageUrl: (event.images?.isNotEmpty == true)
              ? event.images!.first
              : null,
        ),
      ),
    );
  }
}
