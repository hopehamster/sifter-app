import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:link_preview_generator/link_preview_generator.dart';
import 'package:sifter/widgets/audio_message.dart';

// class ChatBubble extends StatelessWidget {
//   final Map<String, dynamic> message;
//   final VoidCallback onLongPress;

//   const ChatBubble({required this.message, required this.onLongPress});

//   @override
//   Widget build(BuildContext context) {
//     final content = message['content'] ?? '';
//     final gifUrl = message['gifUrl'];
//     final audioUrl = message['audioUrl'];
//     final youtubeId = _extractYoutubeId(content);
//     final url = _extractUrl(content);
//     final isUnsupportedPlatform = _isUnsupportedPlatform(url);

//     Widget body;
//     if (gifUrl != null) {
//       body = Image.network(gifUrl, width: 100, height: 100);
//     } else if (audioUrl != null) {
//       body = AudioMessage(audioUrl: audioUrl);
//     } else if (youtubeId != null) {
//       body = Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           YoutubePlayer(
//             controller: YoutubePlayerController(
//               initialVideoId: youtubeId,
//               flags: YoutubePlayerFlags(autoPlay: false, mute: false),
//             ),
//             width: 300,
//           ),
//           SizedBox(height: 8),
//           LinkPreviewGenerator(
//             borderRadius: 12,
//             boxShadow: [
//               BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 4)
//             ],
//             titleStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//             link: content,
//           ),
//         ],
//       );
//     } else if (url != null && !isUnsupportedPlatform) {
//       body = LinkPreviewGenerator(
//         borderRadius: 12,
//         boxShadow: [
//           BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 4)
//         ],
//         titleStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//         link: content,
//       );
//     } else if (url != null && isUnsupportedPlatform) {
//       body = VisibilityDetector(
//         key: Key(message['id']),
//         onVisibilityChanged: (info) {
//           if (info.visibleFraction > 0) {}
//         },
//         child: Container(
//           height: 200,
//           margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
//           child: InAppWebView(
//             initialUrlRequest: URLRequest(url: WebUri(url)),
//             initialOptions: InAppWebViewGroupOptions(
//               crossPlatform: InAppWebViewOptions(
//                 javaScriptEnabled: true,
//                 useShouldOverrideUrlLoading: true,
//               ),
//             ),
//             onWebViewCreated: (controller) {},
//           ),
//         ),
//       );
//     } else {
//       body = Text(content);
//     }

//     return GestureDetector(
//       onLongPress: onLongPress,
//       child: Container(
//         margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
//         padding: EdgeInsets.all(10),
//         decoration: BoxDecoration(
//           color: Colors.grey[200],
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: body,
//       ),
//     );
//   }

//   String? _extractYoutubeId(String text) {
//     final regex = RegExp(r'(?:youtube\.com\/watch\?v=|youtu\.be\/)([\w-]+)');
//     final match = regex.firstMatch(text);
//     return match?.group(1);
//   }

//   String? _extractUrl(String text) {
//     final regex = RegExp(r'(https?://[^\s]+)');
//     final match = regex.firstMatch(text);
//     return match?.group(0);
//   }

//   bool _isUnsupportedPlatform(String? url) {
//     if (url == null) return false;
//     return url.contains('twitch.tv') || url.contains('tiktok.com');
//   }
// }
class ChatBubble extends StatelessWidget {
  final String message;
  final bool isSender;

  ChatBubble({required this.message, required this.isSender});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isSender ? Colors.grey[200] : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Color(0xFF2196F3)),
      ),
      child: Text(message),
    );
  }
}
