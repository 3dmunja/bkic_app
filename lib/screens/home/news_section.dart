import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';

class NewsSection extends StatefulWidget {
  final List<dynamic> news;

  const NewsSection({
    super.key,
    required this.news,
  });

  @override
  State<NewsSection> createState() => _NewsSectionState();
}

class _NewsSectionState extends State<NewsSection> {
  final ScrollController _scrollController = ScrollController();

  String _pickTitle(dynamic item) {
    if (item is Map) {
      return item['titel']?.toString() ?? item['title']?.toString() ?? '';
    }
    return '';
  }

  String _pickText(dynamic item) {
    if (item is Map) {
      return item['tekst']?.toString() ??
          item['text']?.toString() ??
          item['content']?.toString() ??
          '';
    }
    return '';
  }

  String _pickStart(dynamic item) {
    if (item is Map) {
      return item['start']?.toString() ?? item['pocetak']?.toString() ?? '';
    }
    return '';
  }

  String _pickEnd(dynamic item) {
    if (item is Map) {
      return item['slut']?.toString() ?? item['end']?.toString() ?? '';
    }
    return '';
  }

  String _trimText(String value) {
    return value.trim();
  }

  String _truncateText(String value, {int maxLength = 220}) {
    final clean = _trimText(value);
    if (clean.length <= maxLength) return clean;
    return '${clean.substring(0, maxLength).trimRight()}…';
  }

  String _formatDateTime(String value) {
    final raw = value.trim();
    if (raw.isEmpty) return '';

    if (RegExp(r'^\d{2}\.\d{2}\.\d{4}').hasMatch(raw)) {
      final normalized =
          raw.replaceAll(',', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

      return normalized.replaceFirstMapped(
        RegExp(r'(\d{1,2})\.(\d{2})$'),
        (m) => '${m.group(1)}:${m.group(2)}',
      );
    }

    if (RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(raw)) {
      return raw
          .replaceFirst('T', ' ')
          .substring(0, raw.length >= 16 ? 16 : raw.length);
    }

    return raw;
  }

  Widget _buildMetaLine({
    required String start,
    required String end,
  }) {
    final formattedStart = _formatDateTime(start);
    final formattedEnd = _formatDateTime(end);

    if (formattedStart.isEmpty && formattedEnd.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (formattedStart.isNotEmpty)
          Text(
            'Od: $formattedStart',
            style: const TextStyle(
              color: Color(0xFFE8FFF2),
              fontSize: 12.2,
              height: 1.3,
            ),
          ),
        if (formattedEnd.isNotEmpty)
          Text(
            'Do: $formattedEnd',
            style: const TextStyle(
              color: Color(0xFFE8FFF2),
              fontSize: 12.2,
              height: 1.3,
            ),
          ),
      ],
    );
  }

  Widget _buildNewsTitle(String title) {
    if (title.length <= 22) {
      return Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 14.5,
          color: Colors.white,
        ),
      );
    }

    return SizedBox(
      height: 20,
      child: Marquee(
        text: title,
        style: const TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 14.5,
          color: Colors.white,
        ),
        scrollAxis: Axis.horizontal,
        blankSpace: 35,
        velocity: 25,
        pauseAfterRound: const Duration(seconds: 1),
        startPadding: 0,
        accelerationDuration: const Duration(milliseconds: 400),
        accelerationCurve: Curves.linear,
        decelerationDuration: const Duration(milliseconds: 400),
        decelerationCurve: Curves.easeOut,
      ),
    );
  }

  Widget _buildNewsItem(dynamic item) {
    final title = _trimText(_pickTitle(item));
    final text = _truncateText(_pickText(item));

    final end = _pickEnd(item);
    final startRaw = _pickStart(item);
    final start = startRaw.trim().isNotEmpty ? startRaw : end;

    return RepaintBoundary(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0x2210231B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0x3348A66A)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title.isNotEmpty) _buildNewsTitle(title),
            if (title.isNotEmpty) const SizedBox(height: 6),
            _buildMetaLine(start: start, end: end),
            if ((start.isNotEmpty || end.isNotEmpty) && text.isNotEmpty)
              const SizedBox(height: 8),
            if (text.isNotEmpty)
              Text(
                text,
                style: const TextStyle(
                  color: Color(0xDDE8FFF2),
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.news.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0x1810A05A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0x3348A66A)),
        ),
        child: const Text(
          'Trenutno nema vijesti.',
          style: TextStyle(
            color: Color(0xCCE8FFF2),
            fontSize: 13,
          ),
        ),
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 260),
      child: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        child: ListView.separated(
          controller: _scrollController,
          padding: const EdgeInsets.only(right: 6),
          shrinkWrap: true,
          itemCount: widget.news.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            return _buildNewsItem(widget.news[index]);
          },
        ),
      ),
    );
  }
}