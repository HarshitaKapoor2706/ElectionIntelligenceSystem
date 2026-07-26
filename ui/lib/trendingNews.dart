import 'package:flutter/material.dart';
import '../Appcolors.dart';
import '../state_data.dart';

class TrendingNewsCarousel extends StatelessWidget {
  final List<NewsItem>? items; // null = still loading
  final String? error;
  final VoidCallback? onRetry;
  final VoidCallback? onSeeAll;

  const TrendingNewsCarousel({
    super.key,
    required this.items,
    this.error,
    this.onRetry,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Trending News',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              GestureDetector(
                onTap: onSeeAll,
                child: const Text(
                  'See all',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 170, child: _buildBody()),
      ],
    );
  }

  Widget _buildBody() {
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, color: AppColors.textMuted),
              const SizedBox(height: 6),
              const Text(
                'Could not load news',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
              if (onRetry != null)
                TextButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (items == null) {
      return ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) => Container(
          width: 210,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      );
    }

    if (items!.isEmpty) {
      return const Center(
        child: Text('No news right now', style: TextStyle(color: AppColors.textMuted)),
      );
    }

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: items!.length,
      separatorBuilder: (_, __) => const SizedBox(width: 12),
      itemBuilder: (context, i) => _NewsCard(item: items![i]),
    );
  }
}

class _NewsCard extends StatelessWidget {
  final NewsItem item;
  const _NewsCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final hasImage = item.imageUrl != null && item.imageUrl!.isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 210,
        // Gradient always sits as the base layer, so if there's no image
        // (or it fails to load) this is exactly what shows -- no red
        // "broken image" box, ever.
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Real photo on top of the gradient, only attempted if a URL
            // exists. errorBuilder means a failed/expired NewsAPI image
            // link just silently keeps showing the gradient underneath
            // instead of Flutter's default red error indicator.
            if (hasImage)
              Image.network(
                item.imageUrl!,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const SizedBox.shrink(); // keep gradient while loading
                },
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox.shrink(); // keep gradient, no red box
                },
              ),

            // Darkening + bottom gradient scrim so text stays legible
            // over any photo.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.05),
                    AppColors.primaryDark.withOpacity(0.85),
                  ],
                  stops: const [0.35, 1.0],
                ),
              ),
            ),

            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      item.subtitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}