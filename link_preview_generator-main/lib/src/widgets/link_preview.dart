import 'dart:async';

import 'package:flutter/material.dart';
import 'package:link_preview_generator/src/models/types.dart';
import 'package:link_preview_generator/src/utils/analyzer.dart';
import 'package:link_preview_generator/src/widgets/link_view_large.dart';
import 'package:link_preview_generator/src/widgets/link_view_small.dart';
import 'package:url_launcher/url_launcher.dart';

/// A widget to convert your links into beautiful previews.
class LinkPreviewGenerator extends StatefulWidget {
  /// Customize the background colour.
  /// Deaults to `Color.fromRGBO(248, 248, 248, 1.0)`.
  final Color backgroundColor;

  /// Give the limit to body text (Description).
  /// If not provided, it will be calculated automatically.
  final int? bodyMaxLines;

  /// Customize `body` [TextStyle].
  final TextStyle? bodyStyle;

  /// Give the overflow type for body text (Description).
  /// Deaults to `TextOverflow.ellipsis`.
  final TextOverflow bodyTextOverflow;

  /// BorderRadius for the card.
  /// Deafults to `12.0`.
  final double borderRadius;

  /// Box shadow for the card.
  ///  Deafults to `[BoxShadow(
  ///               spreadRadius: 1,
  ///               blurRadius: 5,
  ///               color: Colors.grey.withAlpha(128),
  ///               offset: Offset(0, 3),)]`.
  final List<BoxShadow>? boxShadow;

  /// Cache result time, default cache `7 days`.
  final Duration cacheDuration;

  /// Body that need to be shown if parsing fails.
  /// Deaults to `Oops! Unable to parse the url.`
  final String errorBody;

  /// Image URL that will be shown if parsing fails
  /// & when multimedia enabled & no meta data is available.
  /// Deaults to `A crying semi-soccer ball image`.
  /// https://raw.githubusercontent.com/ghpranav/link_preview_generator/main/assets/giphy.gif
  final String errorImage;

  /// Title that need to be shown if parsing fails.
  /// Deaults to `Something went wrong!`
  final String errorTitle;

  /// Widget that needs to be shown if parsing fails.
  /// Defaults to plain container with given background colour.
  final Widget? errorWidget;

  /// Web address (URL that needs to be parsed/scrapped).
  final String link;

  /// Link Preview display style. One among `large` or `small`.
  /// Defaults to [LinkPreviewStyle.large].
  final LinkPreviewStyle linkPreviewStyle;

  /// Widget that needs to be shown when
  /// package is trying to fetch metadata.
  /// If not given anything then default widget will be shown.
  final Widget? placeholderWidget;

  /// Proxy URL to pass that resolve CORS issues on web.
  /// For example, `https://cors-anywhere.herokuapp.com/` .
  final String? proxyUrl;

  /// To remove the card elevation set it to `true`.
  /// Defaults to `false`.
  final bool removeElevation;

  /// Show or Hide body text (Description).
  /// Defaults to `true`.
  final bool showBody;

  /// Show or Hide domain name.
  /// Defaults to `true`.
  final bool showDomain;

  /// Show or Hide image, if available.
  /// Defaults to `true`.
  final bool showGraphic;

  /// Show or Hide title.
  /// Defaults to `true`.
  final bool showTitle;

  /// Adjust the box fit of the image.
  /// Defaults to [BoxFit.cover].
  final BoxFit graphicFit;

  /// Customize `title` [TextStyle].
  final TextStyle? titleStyle;

  /// Function that needs to be called when user taps on the card.
  /// If not given then given URL will be launched.
  /// Pass empty function to disable tap.
  final void Function()? onTap;

  /// Creates [LinkPreviewGenerator]
  const LinkPreviewGenerator({
    Key? key,
    required this.link,
    this.cacheDuration = const Duration(days: 7),
    this.titleStyle,
    this.bodyStyle,
    this.linkPreviewStyle = LinkPreviewStyle.large,
    this.showBody = true,
    this.showDomain = true,
    this.showGraphic = true,
    this.showTitle = true,
    this.graphicFit = BoxFit.cover,
    this.backgroundColor = const Color.fromRGBO(248, 248, 248, 1.0),
    this.bodyMaxLines,
    this.bodyTextOverflow = TextOverflow.ellipsis,
    this.onTap,
    this.placeholderWidget,
    this.proxyUrl,
    this.errorWidget,
    this.errorBody = 'Oops! Unable to parse the url.',
    this.errorImage =
        'https://raw.githubusercontent.com/ghpranav/link_preview_generator/main/assets/giphy.gif',
    this.errorTitle = 'Something went wrong!',
    this.borderRadius = 12.0,
    this.boxShadow,
    this.removeElevation = false,
  }) : super(key: key);

  @override
  State<LinkPreviewGenerator> createState() => LinkPreviewGeneratorState();
}

class LinkPreviewGeneratorState extends State<LinkPreviewGenerator> {
  WebInfo? info;
  bool loading = false;
  late String url;

  @override
  Widget build(BuildContext context) {
    final currentInfo = info;
    var containerHeight = (widget.linkPreviewStyle == LinkPreviewStyle.small ||
            !widget.showGraphic)
        ? MediaQuery.of(context).size.height * 0.15
        : MediaQuery.of(context).size.height * 0.30;

    if (loading) {
      return widget.placeholderWidget ??
          Container(
            height: containerHeight,
            width: MediaQuery.of(context).size.width,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              color: const Color.fromRGBO(248, 248, 248, 1.0),
            ),
            alignment: Alignment.center,
            child: const Text('Fetching data...'),
          );
    }

    if (info != null) {
      if (info!.type == LinkPreviewType.image) {
        var img = info!.image;
        return buildLinkContainer(
          containerHeight,
          title: widget.errorTitle,
          desc: widget.errorBody,
          image: (widget.proxyUrl ?? '') +
              (img.trim() == '' ? widget.errorImage : img),
        );
      }
    }

    return info == null
        ? widget.errorWidget ??
            buildPlaceHolder(widget.backgroundColor, containerHeight)
        : buildLinkContainer(
            containerHeight,
            domain:
                LinkPreviewAnalyzer.isNotEmpty(currentInfo!.domain) ? currentInfo.domain : '',
            title: LinkPreviewAnalyzer.isNotEmpty(currentInfo.title)
                ? currentInfo.title
                : widget.errorTitle,
            desc: LinkPreviewAnalyzer.isNotEmpty(currentInfo.description)
                ? currentInfo.description
                : widget.errorBody,
            image: LinkPreviewAnalyzer.isNotEmpty(currentInfo.image)
                ? currentInfo.image
                : LinkPreviewAnalyzer.isNotEmpty(currentInfo.icon)
                    ? currentInfo.icon
                    : widget.errorImage,
            isIcon: LinkPreviewAnalyzer.isNotEmpty(currentInfo.image) ? false : true,
          );
  }

  @override
  void initState() {
    super.initState();

    url = ((widget.proxyUrl ?? '') + widget.link).trim();
    info = LinkPreviewAnalyzer.getInfoFromCache(url) as WebInfo?;
    if (info == null) {
      loading = true;
      getInfo();
    }
  }

  Widget buildLinkContainer(
    double containerHeight, {
    String? domain = '',
    String? title = '',
    String? desc = '',
    String? image = '',
    bool isIcon = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        boxShadow: widget.removeElevation
            ? []
            : widget.boxShadow ??
                [
                  BoxShadow(
                    spreadRadius: 1,
                    blurRadius: 5,
                    color: Colors.grey.withAlpha(128),
                    offset: const Offset(0, 3),
                  )
                ],
      ),
      height: containerHeight,
      child: InkWell(
        onTap: widget.onTap ?? () => launchURL(widget.link),
        child: (widget.linkPreviewStyle == LinkPreviewStyle.small)
            ? LinkViewSmall(
                key: widget.key ?? Key(widget.link.toString()),
                url: widget.link,
                domain: domain!,
                title: title!,
                description: desc!,
                imageUri: image!,
                titleTextStyle: widget.titleStyle,
                bodyTextStyle: widget.bodyStyle,
                bodyTextOverflow: widget.bodyTextOverflow,
                bodyMaxLines: widget.bodyMaxLines,
                showBody: widget.showBody,
                showDomain: widget.showDomain,
                showGraphic: widget.showGraphic,
                showTitle: widget.showTitle,
                graphicFit: widget.graphicFit,
                isIcon: isIcon,
                bgColor: widget.backgroundColor,
                radius: widget.borderRadius,
              )
            : LinkViewLarge(
                key: widget.key ?? Key(widget.link.toString()),
                url: widget.link,
                domain: domain!,
                title: title!,
                description: desc!,
                imageUri: image!,
                titleTextStyle: widget.titleStyle,
                bodyTextStyle: widget.bodyStyle,
                bodyTextOverflow: widget.bodyTextOverflow,
                bodyMaxLines: widget.bodyMaxLines,
                showBody: widget.showBody,
                showDomain: widget.showDomain,
                showGraphic: widget.showGraphic,
                showTitle: widget.showTitle,
                graphicFit: widget.graphicFit,
                isIcon: isIcon,
                bgColor: widget.backgroundColor,
                radius: widget.borderRadius,
              ),
      ),
    );
  }

  Widget buildPlaceHolder(Color color, double defaultHeight) {
    return SizedBox(
      height: defaultHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          var layoutWidth = constraints.biggest.width;
          var layoutHeight = constraints.biggest.height;

          return Container(
            color: color,
            width: layoutWidth,
            height: layoutHeight,
          );
        },
      ),
    );
  }

  Future<void> getInfo() async {
    if (url.startsWith('http') || url.startsWith('https')) {
      info = await LinkPreviewAnalyzer.getInfo(url,
          cacheDuration: widget.cacheDuration, multimedia: true) as WebInfo?;
    } else {
      print('Error: $url is not starting with either http or https.');
    }
    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  void launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      try {
        await launchUrl(uri);
      } catch (err) {
        throw Exception('Could not launch $url. Error: $err');
      }
    }
  }
}
