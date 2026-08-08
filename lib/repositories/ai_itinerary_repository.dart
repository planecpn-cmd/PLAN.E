import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/generated_itinerary.dart';

class AiItineraryRepository {
  final SupabaseClient _client;

  AiItineraryRepository(this._client);

  Future<GeneratedItinerary> generate({
    required String tripType,
    required int durationDays,
    String? pace,
    int? budgetNpr,
    String? interests,
    String? groupType,
  }) async {
    final response = await _client.functions.invoke(
      'generate-itinerary',
      body: {
        'trip_type': tripType,
        'duration_days': durationDays,
        if (pace != null) 'pace': pace,
        if (budgetNpr != null) 'budget_npr': budgetNpr,
        if (interests != null && interests.isNotEmpty) 'interests': interests,
        if (groupType != null) 'group_type': groupType,
      },
    );

    if (response.status == 200 && response.data != null) {
      final Map<String, dynamic> data = Map<String, dynamic>.from(response.data as Map);
      return GeneratedItinerary.fromJson(data);
    }

    final errorMsg = response.data is Map
        ? (response.data['error'] ?? 'Failed to generate itinerary')
        : 'Failed to generate itinerary';
    throw Exception(errorMsg.toString());
  }
}
