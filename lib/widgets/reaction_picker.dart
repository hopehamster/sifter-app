import 'package:flutter/material.dart';
import 'package:giphy_get/giphy_get.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ReactionPicker extends StatefulWidget {
  final Function(String) onEmojiSelected;
  final Function(String) onGifSelected;
  final bool showGiphy;

  const ReactionPicker({
    super.key,
    required this.onEmojiSelected,
    required this.onGifSelected,
    this.showGiphy = true,
  });

  @override
  State<ReactionPicker> createState() => _ReactionPickerState();
}

class _ReactionPickerState extends State<ReactionPicker> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _quickEmojis = ['👍', '❤️', '😂', '😮', '😢', '🙏', '👏', '🔥'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.showGiphy ? 2 : 1,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _showGiphyPicker() async {
    final gif = await GiphyGet.getGif(
      context: context,
      apiKey: dotenv.env['GIPHY_API_KEY']!,
      lang: GiphyLanguage.english,
      rating: GiphyRating.g,
      tabColor: Theme.of(context).primaryColor,
    );

    if (gif != null) {
      widget.onGifSelected(gif.url!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          if (widget.showGiphy)
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Quick Reactions'),
                Tab(text: 'Giphy'),
              ],
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Quick Reactions Tab
                GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: _quickEmojis.length,
                  itemBuilder: (context, index) {
                    return InkWell(
                      onTap: () => widget.onEmojiSelected(_quickEmojis[index]),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            _quickEmojis[index],
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                // Giphy Tab
                if (widget.showGiphy)
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _showGiphyPicker,
                      icon: const Icon(Icons.gif),
                      label: const Text('Search Giphy'),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ReactionChip extends StatelessWidget {
  final String reaction;
  final int count;
  final VoidCallback? onTap;
  final bool isGif;

  const ReactionChip({
    super.key,
    required this.reaction,
    required this.count,
    this.onTap,
    this.isGif = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withAlpha(128),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isGif)
              CachedNetworkImage(
                imageUrl: reaction,
                width: 20,
                height: 20,
                memCacheHeight: 20,
                memCacheWidth: 20,
              )
            else
              Text(
                reaction,
                style: const TextStyle(fontSize: 16),
              ),
            const SizedBox(width: 4),
            Text(
              count.toString(),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
} 