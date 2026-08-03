import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';

class ComponentsScreen extends StatefulWidget {
  const ComponentsScreen({super.key});

  @override
  State<ComponentsScreen> createState() => _ComponentsScreenState();
}

class _ComponentsScreenState extends State<ComponentsScreen> {
  // State for interactive component demos
  int _selectedTabIndex = 0;
  bool _filter1Selected = true;
  bool _filter2Selected = false;
  int _counterValue = 2;
  double _userRating = 4.0;
  bool _isSaved = false;
  int _currentStep = 1;
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: const Text('PLAN E Design Gallery'),
      ),
      bottomNavigationBar: PriceBottomBar(
        priceText: 'NPR 8,500',
        unitText: '/ person',
        buttonLabel: 'Book Demo',
        onPressed: () {
          AppToast.show(
            context,
            message: 'PriceBottomBar action triggered!',
            variant: AppToastVariant.success,
          );
        },
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Color Palette Tokens Demo
            _buildSection(
              title: '1. Color Palette Tokens',
              child: Wrap(
                spacing: AppSpacing.sm8,
                runSpacing: AppSpacing.sm8,
                children: [
                  _buildColorChip('Forest', AppColors.forest, AppColors.ivory),
                  _buildColorChip('Deep', AppColors.deep, AppColors.ivory),
                  _buildColorChip('Ivory', AppColors.ivory, AppColors.ink),
                  _buildColorChip('Sage', AppColors.sage, AppColors.ink),
                  _buildColorChip('Ink', AppColors.ink, AppColors.ivory),
                  _buildColorChip('Gold', AppColors.gold, AppColors.ivory),
                ],
              ),
            ),

            // 2. Typography Demo
            _buildSection(
              title: '2. Typography Tokens',
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Display Large (32)', style: AppTypography.displayLarge),
                  SizedBox(height: AppSpacing.xs4),
                  Text('Display Medium (28)', style: AppTypography.displayMedium),
                  SizedBox(height: AppSpacing.xs4),
                  Text('Heading Large (24)', style: AppTypography.headingLarge),
                  SizedBox(height: AppSpacing.xs4),
                  Text('Heading Medium (20)', style: AppTypography.headingMedium),
                  SizedBox(height: AppSpacing.xs4),
                  Text('Body Large (16)', style: AppTypography.bodyLarge),
                  SizedBox(height: AppSpacing.xs4),
                  Text('Body Medium (14)', style: AppTypography.bodyMedium),
                  SizedBox(height: AppSpacing.xs4),
                  Text('Caption (12)', style: AppTypography.caption),
                ],
              ),
            ),

            // 3. AppButton Variants & States
            _buildSection(
              title: '3. AppButton States (Min Height >= 48dp)',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: AppSpacing.sm8,
                    runSpacing: AppSpacing.sm8,
                    children: [
                      AppButton(
                        label: 'Primary Button',
                        onPressed: () {},
                      ),
                      AppButton.secondary(
                        label: 'Secondary Button',
                        onPressed: () {},
                      ),
                      AppButton.text(
                        label: 'Text Button',
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md12),
                  Wrap(
                    spacing: AppSpacing.sm8,
                    runSpacing: AppSpacing.sm8,
                    children: [
                      AppButton(
                        label: 'With Icon',
                        icon: Icons.explore_outlined,
                        onPressed: () {},
                      ),
                      AppButton(
                        label: 'Loading',
                        isLoading: true,
                        onPressed: () {},
                      ),
                      const AppButton(
                        label: 'Disabled',
                        variant: AppButtonVariant.disabled,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md12),
                  AppButton(
                    label: 'Full Width Primary Button',
                    isFullWidth: true,
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            // 4. AppCard Demos
            _buildSection(
              title: '4. AppCard',
              child: AppCard(
                onTap: () {
                  AppToast.show(context, message: 'AppCard tapped!');
                },
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tappable AppCard Title', style: AppTypography.headingMedium),
                    SizedBox(height: AppSpacing.xs4),
                    Text(
                      'Cards provide clean containers with 16dp rounded corners and subtle borders.',
                      style: AppTypography.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),

            // 5. ExperienceCard & ContentRail
            _buildSection(
              title: '5. ContentRail & ExperienceCard',
              child: ContentRail(
                title: 'Featured Experiences',
                subtitle: 'Hand-picked Nepal adventures',
                actionLabel: 'See All',
                onActionTap: () {},
                items: [
                  ExperienceCard(
                    title: 'Annapurna Base Camp Trek',
                    location: 'Pokhara, Kaski',
                    rating: 4.9,
                    reviewCount: 128,
                    priceText: 'NPR 24,000',
                    categoryTag: 'Trekking',
                    isSaved: _isSaved,
                    onBookmarkTap: () {
                      setState(() => _isSaved = !_isSaved);
                    },
                    onTap: () {
                      AppToast.show(context, message: 'Opened ABC Trek');
                    },
                  ),
                  ExperienceCard(
                    title: 'Trishuli River Rafting',
                    location: 'Chitwan Highway',
                    rating: 4.7,
                    reviewCount: 84,
                    priceText: 'NPR 4,500',
                    categoryTag: 'Rafting',
                    isSaved: false,
                    onBookmarkTap: () {},
                    onTap: () {},
                  ),
                ],
              ),
            ),

            // 6. FilterChipPill & AppTabs
            _buildSection(
              title: '6. FilterChipPill & AppTabs',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: AppSpacing.sm8,
                    runSpacing: AppSpacing.sm8,
                    children: [
                      FilterChipPill(
                        label: 'All Adventures',
                        isSelected: _filter1Selected,
                        onSelected: (val) => setState(() => _filter1Selected = val),
                      ),
                      FilterChipPill(
                        label: 'Trekking',
                        isSelected: _filter2Selected,
                        icon: Icons.hiking,
                        onSelected: (val) => setState(() => _filter2Selected = val),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg16),
                  AppTabs(
                    tabs: const ['Overview', 'Itinerary', 'Reviews', 'Host'],
                    selectedIndex: _selectedTabIndex,
                    onTabSelected: (idx) => setState(() => _selectedTabIndex = idx),
                  ),
                ],
              ),
            ),

            // 7. Input Fields & CounterField
            _buildSection(
              title: '7. AppTextField & CounterField',
              child: Column(
                children: [
                  AppTextField(
                    label: 'Destination Search',
                    hint: 'Where do you want to travel?',
                    prefixIcon: const Icon(Icons.search, color: AppColors.forest),
                    controller: _textController,
                  ),
                  const SizedBox(height: AppSpacing.md12),
                  const AppTextField(
                    label: 'Error State Demo',
                    hint: 'Enter promo code',
                    errorText: 'Invalid promo code for PLAN E',
                  ),
                  const SizedBox(height: AppSpacing.md12),
                  CounterField(
                    label: 'Number of Guests',
                    value: _counterValue,
                    onChanged: (val) => setState(() => _counterValue = val),
                    min: 1,
                    max: 10,
                  ),
                ],
              ),
            ),

            // 8. RatingStars & ProgressSteps
            _buildSection(
              title: '8. RatingStars & ProgressSteps',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Text('Read-only: ', style: AppTypography.bodyMedium),
                      RatingStars(rating: 4.5, reviewCount: 96),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm8),
                  Row(
                    children: [
                      const Text('Interactive: ', style: AppTypography.bodyMedium),
                      RatingStars(
                        rating: _userRating,
                        onRatingChanged: (newRating) {
                          setState(() => _userRating = newRating);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg16),
                  ProgressSteps(
                    steps: const ['Select', 'Details', 'Payment'],
                    currentStep: _currentStep,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppButton.text(
                        label: 'Prev Step',
                        onPressed: _currentStep > 0
                            ? () => setState(() => _currentStep--)
                            : null,
                      ),
                      AppButton.text(
                        label: 'Next Step',
                        onPressed: _currentStep < 2
                            ? () => setState(() => _currentStep++)
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 9. AppToast Triggers
            _buildSection(
              title: '9. AppToast Notifications',
              child: Wrap(
                spacing: AppSpacing.sm8,
                runSpacing: AppSpacing.sm8,
                children: [
                  AppButton(
                    label: 'Show Success',
                    onPressed: () {
                      AppToast.show(
                        context,
                        message: 'Booking confirmed successfully!',
                        variant: AppToastVariant.success,
                      );
                    },
                  ),
                  AppButton.secondary(
                    label: 'Show Error',
                    onPressed: () {
                      AppToast.show(
                        context,
                        message: 'Network error. Please try again.',
                        variant: AppToastVariant.error,
                      );
                    },
                  ),
                  AppButton.text(
                    label: 'Show Info',
                    onPressed: () {
                      AppToast.show(
                        context,
                        message: 'Welcome to PLAN E Nepal',
                        variant: AppToastVariant.info,
                      );
                    },
                  ),
                ],
              ),
            ),

            // 10. AppSkeleton Loading Demo
            _buildSection(
              title: '10. AppSkeleton Shimmers',
              child: const Row(
                children: [
                  AppSkeleton.circle(size: 48),
                  SizedBox(width: AppSpacing.md12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppSkeleton(height: 16, width: 140),
                        SizedBox(height: AppSpacing.sm8),
                        AppSkeleton(height: 12, width: 220),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 11. AsyncValueView Wrapper Demo
            _buildSection(
              title: '11. AsyncValueView Wrapper',
              child: Column(
                children: [
                  AsyncValueView<String>(
                    value: const AsyncValue.data('Successfully loaded experience data'),
                    data: (dataText) => Container(
                      padding: AppSpacing.paddingMd12,
                      decoration: const BoxDecoration(
                        color: AppColors.sage,
                        borderRadius: AppRadii.borderSm8,
                      ),
                      child: Text('Data loaded: $dataText', style: AppTypography.bodyMedium),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md12),
                  AsyncValueView<String>(
                    value: AsyncValue.error(
                      'Failed to fetch trips from server',
                      StackTrace.current,
                    ),
                    data: (data) => const SizedBox(),
                    onRetry: () {
                      AppToast.show(context, message: 'Retrying async fetch...');
                    },
                  ),
                ],
              ),
            ),

            // 12. EmptyStateView Demo
            _buildSection(
              title: '12. EmptyStateView',
              child: Container(
                padding: AppSpacing.paddingLg16,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: AppRadii.borderMd16,
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: EmptyStateView(
                  title: 'No Saved Trips Yet',
                  description: 'Explore Nepal adventures and tap the bookmark icon to save them.',
                  actionLabel: 'Explore Trips',
                  onActionPressed: () {},
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.huge40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.headingMedium),
          const SizedBox(height: AppSpacing.md12),
          child,
        ],
      ),
    );
  }

  Widget _buildColorChip(String name, Color color, Color textColor) {
    return Container(
      width: 100,
      height: 60,
      decoration: BoxDecoration(
        color: color,
        borderRadius: AppRadii.borderSm8,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      alignment: Alignment.center,
      child: Text(
        name,
        style: AppTypography.caption.copyWith(
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
