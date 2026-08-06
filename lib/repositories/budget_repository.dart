import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/budget_entry.dart';

class BudgetRepository {
  final SupabaseClient _client;

  BudgetRepository(this._client);

  /// Fetch budget expenses for a booking
  Future<List<BudgetEntry>> getBudgetEntries(String bookingId) async {
    final response = await _client
        .from('budget_entries')
        .select()
        .eq('booking_id', bookingId)
        .order('spent_on', ascending: false)
        .order('created_at', ascending: false);

    final List<dynamic> data = response as List<dynamic>;
    return data.map((json) => BudgetEntry.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Add a new expense budget entry
  Future<BudgetEntry> addBudgetEntry({
    required String bookingId,
    required String label,
    required int amountPaisa,
    required String category,
    required DateTime spentOn,
  }) async {
    final response = await _client
        .from('budget_entries')
        .insert({
          'booking_id': bookingId,
          'label': label,
          'amount_paisa': amountPaisa,
          'category': category,
          'spent_on': spentOn.toIso8601String().split('T').first,
        })
        .select()
        .single();

    return BudgetEntry.fromJson(response);
  }

  /// Delete a budget expense entry
  Future<void> deleteBudgetEntry(String entryId) async {
    await _client.from('budget_entries').delete().eq('id', entryId);
  }
}
