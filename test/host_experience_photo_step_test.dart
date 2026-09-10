// H1 photo slice: the wizard photo step uploads on pick, and a failed upload
// must not lose the wizard's local state (same principle as H0).

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:plan_e/features/host/data/host_mode_repository.dart';
import 'package:plan_e/features/host/data/mock_host_mode_repository.dart';
import 'package:plan_e/features/host/presentation/create_host_experience_screen.dart';
import 'package:plan_e/features/host/presentation/host_mode_providers.dart';

class _FakePicker extends ImagePickerPlatform with MockPlatformInterfaceMixin {
  _FakePicker(this.files);
  final List<XFile> files;
  @override
  Future<List<XFile>> getMultiImageWithOptions({
    MultiImagePickerOptions options = const MultiImagePickerOptions(),
  }) async => files;
}

class _UploadFailsRepo extends MockHostModeRepository {
  @override
  Future<String> uploadExperiencePhoto({
    required Uint8List bytes,
    required String fileName,
    required String experienceKey,
  }) async => throw StateError('upload failed (test)');
}

Widget _host(Widget child, HostModeRepository repo) => ProviderScope(
  overrides: [hostModeRepositoryProvider.overrideWithValue(repo)],
  child: MaterialApp(home: child),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    ImagePickerPlatform.instance = _FakePicker([
      XFile.fromData(
        Uint8List.fromList(List<int>.filled(32, 7)),
        path: 'shot.jpg',
        name: 'shot.jpg',
        mimeType: 'image/jpeg',
      ),
    ]);
  });

  testWidgets('a failed photo upload shows an error and keeps wizard state', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _host(const CreateHostExperienceScreen(), _UploadFailsRepo()),
    );
    await tester.pumpAndSettle();

    // Step 0 — type a title, advance to the Photos step.
    await tester.enterText(find.byType(TextField).first, 'Mardi Ridge Sunrise');
    await tester.enterText(
      find.byType(TextField).at(1),
      'Pokhara, Nepal',
    );
    await tester.enterText(
      find.byType(TextField).at(2),
      'A short guided sunrise hike above Pokhara with tea at the top.',
    );
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Photos'), findsWidgets);

    // Pick photos -> upload throws.
    await tester.tap(find.text('Add photos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose from library'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Could not upload shot.jpg'), findsOneWidget);
    // Upload count settled back; no photo was added.
    expect(find.text('Add photos'), findsOneWidget);
    expect(find.text('No photos yet.'), findsOneWidget);

    // Wizard state intact — the title survives.
    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Mardi Ridge Sunrise'), findsOneWidget);
  });
}
