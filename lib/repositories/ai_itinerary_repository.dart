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
    bool confirmed = false,
  }) {
    return _invoke({
      'trip_type': tripType,
      'duration_days': durationDays,
      if (pace != null) 'pace': pace,
      if (budgetNpr != null) 'budget_npr': budgetNpr,
      if (interests != null && interests.isNotEmpty) 'interests': interests,
      if (groupType != null) 'group_type': groupType,
      if (confirmed) 'confirmed': true,
    });
  }

  Future<GeneratedItinerary> generateFromPrompt(String prompt, {bool confirmed = false}) {
    return _invoke({'prompt': prompt, if (confirmed) 'confirmed': true});
  }

  Future<GeneratedItinerary> _invoke(Map<String, dynamic> body) async {
    try {
      final response = await _client.functions.invoke('generate-itinerary', body: body);
      final data = Map<String, dynamic>.from(response.data as Map);
      return GeneratedItinerary.fromJson(data);
    } on FunctionException catch (e) {
      // invoke() throws (not returns) on any non-2xx status, so the status
      // check has to live here, not on a response object.
      if (e.status == 401) {
        throw Exception('Please sign in to use AI trip planning.');
      }
      if (e.status == 429) {
        throw Exception("You've reached your planning limit for this hour. Try again later.");
      }
      if (e.status == 503) {
        throw Exception("Couldn't reach the AI right now, try again in a moment.");
      }
      final errorMsg = e.details is Map
          ? (e.details['error'] ?? 'Failed to generate itinerary')
          : 'Failed to generate itinerary';
      throw Exception(errorMsg.toString());
    }
  }
}
