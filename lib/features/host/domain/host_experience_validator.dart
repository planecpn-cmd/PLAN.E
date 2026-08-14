import 'host_mode_models.dart';

abstract final class HostExperienceValidator {
  static String? title(String? value) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) return 'Experience title is required';
    if (normalized.length < 5) return 'Use at least 5 characters';
    if (normalized.length > 80) return 'Keep the title under 80 characters';
    return null;
  }

  static String? location(String? value) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) return 'Location is required';
    if (normalized.length > 100) {
      return 'Keep the location under 100 characters';
    }
    return null;
  }

  static String? description(String? value) {
    final normalized = value?.trim() ?? '';
    if (normalized.length < 30) return 'Add at least 30 characters';
    if (normalized.length > 2000) {
      return 'Keep the description under 2,000 characters';
    }
    return null;
  }

  static String? positiveInteger(
    String? value, {
    required String field,
    int max = 1000,
  }) {
    final number = int.tryParse(value?.trim() ?? '');
    if (number == null) return 'Enter a valid $field';
    if (number <= 0) return '$field must be greater than zero';
    if (number > max) return '$field cannot exceed $max';
    return null;
  }

  static Map<String, String> validateDraft(HostExperienceDraft draft) {
    final errors = <String, String>{};
    final titleError = title(draft.title);
    final locationError = location(draft.location);
    final descriptionError = description(draft.description);
    if (titleError != null) errors['title'] = titleError;
    if (locationError != null) errors['location'] = locationError;
    if (descriptionError != null) errors['description'] = descriptionError;
    if (draft.startDate == null) errors['startDate'] = 'Start date is required';
    if (draft.endDate == null) errors['endDate'] = 'End date is required';
    if (draft.startDate != null &&
        draft.endDate != null &&
        draft.endDate!.isBefore(draft.startDate!)) {
      errors['endDate'] = 'End date must be after the start date';
    }
    if (draft.capacity == null ||
        draft.capacity! <= 0 ||
        draft.capacity! > 100) {
      errors['capacity'] = 'Capacity must be between 1 and 100';
    }
    if (draft.priceNpr == null ||
        draft.priceNpr! < 100 ||
        draft.priceNpr! > 10000000) {
      errors['price'] = 'Price must be between NPR 100 and 10,000,000';
    }
    return errors;
  }

  static Map<String, String> validateForSubmission(HostExperienceDraft draft) {
    final errors = validateDraft(draft);
    if (draft.photoAssets.isEmpty) errors['photos'] = 'Add at least one photo';
    if (draft.tripDetails.trim().length < 20) {
      errors['tripDetails'] = 'Complete the trip details';
    }
    if (draft.itinerary.isEmpty) errors['itinerary'] = 'Add an itinerary';
    if (draft.included.isEmpty) errors['included'] = 'Add included items';
    if (draft.bring.isEmpty) errors['bring'] = 'Add what guests should bring';
    if (draft.meetingPoint.trim().length < 5) {
      errors['meetingPoint'] = 'Add a clear meeting point';
    }
    return errors;
  }
}
