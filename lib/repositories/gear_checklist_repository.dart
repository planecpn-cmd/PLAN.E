import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/gear_checklist_item.dart';

class GearChecklistRepository {
  final SupabaseClient _client;

  GearChecklistRepository(this._client);

  static const List<String> defaultTrekGear = [
    'Trekking boots & spare laces',
    'Warm down jacket (-10°C rated)',
    'Waterproof rain jacket & poncho',
    'Thermal base layers (top & bottom)',
    'Water bottle & purification tablets',
    'Headlamp with extra batteries',
    'First aid kit & personal medication',
    'Sun protection (hat, UV sunglasses, SPF50)',
    'Trekking poles',
    'Sleeping bag liner',
  ];

  /// Fetch checklist items from Supabase `gear_checklist_items`.
  /// Auto-seeds default gear if no items exist yet for this booking.
  Future<List<GearChecklistItem>> getItems(String bookingId) async {
    final response = await _client
        .from('gear_checklist_items')
        .select()
        .eq('booking_id', bookingId)
        .order('sort_order', ascending: true)
        .order('created_at', ascending: true);

    final List<dynamic> data = response as List<dynamic>;

    if (data.isEmpty) {
      return await seedDefaultItems(bookingId);
    }

    return data.map((json) => GearChecklistItem.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Seed default gear items into `gear_checklist_items` for a booking
  Future<List<GearChecklistItem>> seedDefaultItems(String bookingId) async {
    final List<Map<String, dynamic>> seeds = [];
    for (int i = 0; i < defaultTrekGear.length; i++) {
      seeds.add({
        'booking_id': bookingId,
        'label': defaultTrekGear[i],
        'is_checked': false,
        'is_custom': false,
        'sort_order': i,
      });
    }

    final response = await _client
        .from('gear_checklist_items')
        .insert(seeds)
        .select()
        .order('sort_order', ascending: true);

    final List<dynamic> data = response as List<dynamic>;
    return data.map((json) => GearChecklistItem.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Toggle item checked state in Supabase
  Future<void> toggleItem(String itemId, bool isChecked) async {
    await _client
        .from('gear_checklist_items')
        .update({'is_checked': isChecked})
        .eq('id', itemId);
  }

  /// Add a custom gear item for a booking
  Future<GearChecklistItem> addItem(String bookingId, String label) async {
    final response = await _client
        .from('gear_checklist_items')
        .insert({
          'booking_id': bookingId,
          'label': label,
          'is_checked': false,
          'is_custom': true,
          'sort_order': 99,
        })
        .select()
        .single();

    return GearChecklistItem.fromJson(response);
  }

  /// Delete a custom checklist item
  Future<void> deleteItem(String itemId) async {
    await _client.from('gear_checklist_items').delete().eq('id', itemId);
  }
}
