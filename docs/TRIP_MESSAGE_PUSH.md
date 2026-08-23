# Trip-message push activation

Phase 5 is additive and remains inactive until the hosted migration, Edge
Function, Vault values, and provider credentials are deployed. Message inserts
continue to work when push is not configured.

## 1. Deploy the database and function

Apply `20260816130000_trip_message_push.sql`, then deploy
`trip-message-push`. The function has JWT verification disabled in
`supabase/config.toml` because requests are authenticated by a separate random
webhook secret. The function itself rejects requests that do not have the
matching `X-Trip-Push-Secret` header.

Set Edge Function secrets (use real values; do not commit them):

```sh
supabase secrets set \
  TRIP_MESSAGE_PUSH_WEBHOOK_SECRET='<long-random-value>' \
  FCM_SERVICE_ACCOUNT_JSON='<complete-service-account-json>'
```

Firebase Cloud Messaging HTTP v1 can deliver to Android, web, and iOS Firebase
registration tokens. Direct APNs tokens are also supported when
`APNS_TEAM_ID`, `APNS_KEY_ID`, `APNS_PRIVATE_KEY`, and `APNS_BUNDLE_ID` are set.

## 2. Configure the database webhook secrets

Run this in the hosted Supabase SQL editor with the same random secret used by
the Edge Function:

```sql
select vault.create_secret(
  'https://<project-ref>.supabase.co/functions/v1/trip-message-push',
  'trip_message_push_url'
);

select vault.create_secret(
  '<long-random-value>',
  'trip_message_push_webhook_secret'
);
```

After these values exist, every new `trip_messages` insert queues one private
delivery per recipient and calls the function asynchronously through `pg_net`.
Only the message UUID is posted by the database trigger.

## 3. Configure the Flutter build

Provide these values as build-time defines. Builds without them remain usable
but do not initialize Firebase or request notification permission.

```text
FIREBASE_API_KEY
FIREBASE_APP_ID
FIREBASE_MESSAGING_SENDER_ID
FIREBASE_PROJECT_ID
FIREBASE_AUTH_DOMAIN          (web, optional)
FIREBASE_STORAGE_BUCKET       (optional)
FIREBASE_WEB_VAPID_KEY        (web, optional)
FIREBASE_IOS_BUNDLE_ID        (iOS; defaults to com.plane.plan_e)
```

The Android/iOS Firebase applications must use the app identifiers in this
repository. iOS also requires Push Notifications and Background Modes/Remote
notifications in the Apple provisioning profile.

## Privacy and failure behavior

- Raw device tokens and delivery rows have no authenticated-client read policy.
- Push payloads contain a generic title, generic body, and booking route only;
  the chat body is never selected by the Edge Function or copied to the queue.
- Provider-invalid tokens are disabled automatically.
- A five-minute processing lease prevents duplicate concurrent delivery.
- Provider or webhook failure updates the delivery status but never rolls back
  the original chat message.
