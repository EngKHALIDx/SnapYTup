/// Helpers for formatting byte sizes and durations in a human-friendly way.
class FormatUtils {
  FormatUtils._();

  /// Format a byte count as e.g. "1.2 MB", "850 KB", "4.5 GB".
  static String bytes(int? bytes) {
    if (bytes == null || bytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    int unit = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && unit < units.length - 1) {
      size /= 1024;
      unit++;
    }
    return '${size.toStringAsFixed(size < 10 && unit > 0 ? 1 : 0)} ${units[unit]}';
  }

  /// Format a bit-rate, e.g. "12.3 MB/s".
  static String rate(int? bytesPerSec) {
    if (bytesPerSec == null || bytesPerSec <= 0) return '--';
    return '${bytes(bytesPerSec)}/s';
  }

  /// Format a [Duration] as `M:SS` or `H:MM:SS`.
  static String duration(Duration? d) {
    if (d == null) return '--:--';
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  /// Format an ETA in seconds as `Mm Ss` or just `Ss`.
  static String eta(int? seconds) {
    if (seconds == null || seconds <= 0) return '--';
    if (seconds < 60) return '${seconds}s';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (m < 60) return '${m}m ${s}s';
    final h = m ~/ 60;
    final rm = m % 60;
    return '${h}h ${rm}m';
  }

  /// Compact view count, e.g. "1.2M views".
  static String views(int? count) {
    if (count == null) return '';
    if (count < 1000) return '$count views';
    if (count < 1000000) {
      return '${(count / 1000).toStringAsFixed(1)}K views';
    }
    if (count < 1000000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M views';
    }
    return '${(count / 1000000000).toStringAsFixed(1)}B views';
  }

  /// Compact relative date, e.g. "3 days ago".
  static String timeAgo(DateTime? date) {
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
    return '${(diff.inDays / 365).floor()}y ago';
  }
}
