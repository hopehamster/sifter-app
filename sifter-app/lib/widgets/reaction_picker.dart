import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/giphy_service.dart' as sifter_giphy;

/// Widget for picking reactions (emoji, lottie, giphy)
class ReactionPicker extends ConsumerStatefulWidget {
  final Function(String emoji) onEmojiSelected;
  final Function(String giphyUrl, String giphyId) onGiphySelected;
  final Function(String lottieAsset) onLottieSelected;
  final String? giphyApiKey;

  const ReactionPicker({
    super.key,
    required this.onEmojiSelected,
    required this.onGiphySelected,
    required this.onLottieSelected,
    this.giphyApiKey,
  });

  @override
  ConsumerState<ReactionPicker> createState() => _ReactionPickerState();
}

class _ReactionPickerState extends ConsumerState<ReactionPicker>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<sifter_giphy.GiphyGif> _reactionGifs = [];
  bool _isLoadingGifs = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadReactionGifs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReactionGifs() async {
    if (widget.giphyApiKey == null || widget.giphyApiKey!.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoadingGifs = false;
        });
      }
      return;
    }

    try {
      final giphyService = ref.read(sifter_giphy.giphyServiceProvider);
      final gifs = await giphyService.getReactionGifs();

      if (mounted) {
        setState(() {
          _reactionGifs = gifs;
          _isLoadingGifs = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingGifs = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Tab bar
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.emoji_emotions), text: 'Emoji'),
              Tab(icon: Icon(Icons.animation), text: 'Animated'),
              Tab(icon: Icon(Icons.gif), text: 'GIFs'),
            ],
          ),

          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildEmojiPicker(),
                _buildLottiePicker(),
                _buildGiphyPicker(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmojiPicker() {
    return EmojiPicker(
      onEmojiSelected: (category, emoji) {
        widget.onEmojiSelected(emoji.emoji);
        Navigator.of(context).pop();
      },
      config: Config(
        height: 256,
        checkPlatformCompatibility: true,
        emojiViewConfig: EmojiViewConfig(
          emojiSizeMax: 28,
          verticalSpacing: 0,
          horizontalSpacing: 0,
          gridPadding: EdgeInsets.zero,
          backgroundColor: Theme.of(context).colorScheme.surface,
          recentsLimit: 28,
          replaceEmojiOnLimitExceed: false,
        ),
        searchViewConfig: SearchViewConfig(
          backgroundColor: Theme.of(context).colorScheme.surface,
          hintText: 'Search emoji...',
        ),
        categoryViewConfig: CategoryViewConfig(
          backgroundColor: Theme.of(context).colorScheme.surface,
        ),
      ),
    );
  }

  Widget _buildLottiePicker() {
    final lottieAssets = [
      'assets/reactions/like.json',
      'assets/reactions/love.json',
      'assets/reactions/laugh.json',
      'assets/reactions/wow.json',
      'assets/reactions/sad.json',
      'assets/reactions/angry.json',
      'assets/reactions/celebrate.json',
      'assets/reactions/applause.json',
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: lottieAssets.length,
      itemBuilder: (context, index) {
        final asset = lottieAssets[index];
        return GestureDetector(
          onTap: () {
            widget.onLottieSelected(asset);
            Navigator.of(context).pop();
          },
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Lottie.asset(
                asset,
                fit: BoxFit.cover,
                repeat: true,
                animate: true,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.animation,
                    size: 32,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGiphyPicker() {
    if (widget.giphyApiKey == null || widget.giphyApiKey!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.gif,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Giphy API key not configured',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Configure GIPHY_API_KEY to enable GIF reactions',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_isLoadingGifs) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_reactionGifs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No GIFs available',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check your internet connection',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _reactionGifs.length,
      itemBuilder: (context, index) {
        final giphy = _reactionGifs[index];
        return GestureDetector(
          onTap: () {
            widget.onGiphySelected(giphy.url, giphy.id);
            Navigator.of(context).pop();
          },
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl:
                    giphy.previewUrl.isNotEmpty ? giphy.previewUrl : giphy.url,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.gif,
                    size: 32,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                errorWidget: (context, url, error) => Icon(
                  Icons.error,
                  size: 32,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
