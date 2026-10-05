const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// "Sep 17, 2027"
String formatDate(DateTime d) => '${_months[d.month - 1]} ${d.day}, ${d.year}';

/// "just now" / "5 min ago" / "3 hr ago" / "2 days ago" / "Sep 12, 2026".
String timeAgo(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'just now';
  if (d.inMinutes < 60) return '${d.inMinutes} min ago';
  if (d.inHours < 24) return '${d.inHours} hr ago';
  if (d.inDays < 7) return '${d.inDays} day${d.inDays == 1 ? '' : 's'} ago';
  return formatDate(t);
}
