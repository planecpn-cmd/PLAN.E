# Host application contract v1

Both clients store questionnaire answers in `host_applications.application_data` and mirror searchable legacy fields (`title`, `description`, `location`, `photos`, `verification_doc_path`). Dates are ISO `YYYY-MM-DD`; money is integer NPR paisa; enum values below are canonical.

| Questionnaire | Canonical JSON field | Existing mirror |
|---|---|---|
| Hosting type | `hosting_type` | `category_id` when a matching category exists |
| Host type | `host_type` | — |
| Name | `full_name` | `profiles.full_name` on submission |
| Organisation | `organization_name` | — |
| Email / phone | `email`, `phone` | `profiles.phone` on submission |
| Province / district / locality | `province`, `district`, `locality` | `location` |
| Capacity | `min_guests`, `max_guests` | — |
| Availability | `availability_type`, `available_days`, `start_date`, `end_date`, `availability_note` | — |
| Pricing | `pricing_model`, `price_paisa` | — |
| Inclusions | `included_items`, `inclusion_details` | — |
| Cancellation | `cancellation_policy`, `cancellation_details` | — |
| Identity | `identity_type`, `identity_number`, `identity_front_path`, `identity_back_path` | `verification_doc_path` (front) |
| Conditional documents | `business_document_paths`, `safety_document_paths` | — |
| Photos/content | `host_photo_path`, `photo_paths`, `business_logo_path`, `description` | `photos`, `description`, `title` |
| Terms | `terms_accepted` | — |

Canonical values:

- `hosting_type`: `adventure`, `experience`, `stay`, `tour_package`, `community_activity`, `other`
- `host_type`: `individual`, `registered_business`, `community_group`, `hotel_homestay`, `tour_operator`, `experience_provider`, `other`
- `availability_type`: `regular`, `specific_dates`, `seasonal`, `flexible`
- `pricing_model`: `per_person`, `per_group`, `starting_price`, `custom_quote`
- `cancellation_policy`: `flexible`, `moderate`, `strict`, `custom`
- status: `draft`, `submitted`, `under_review`, `action_required`, `approved`, `rejected` (`verification` remains readable for legacy rows)

Conditional rules: organisation name is required except for individuals; business documents apply to registered businesses/operators/hotels; safety documents apply to adventures and tour packages. Identity front, description, host type, hosting type, location, valid capacity, availability, cancellation policy, and accepted terms are required to submit. A positive price is required unless pricing is `custom_quote`.
