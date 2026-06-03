class ThemeFormatter {
  static String format(String theme) {
    final String trimmed = theme.trim();
    if (trimmed.toUpperCase() == 'EDITING AND POST-PRODUCTION') {
      return 'Editing';
    }
    if (trimmed.toUpperCase() == 'ALL') {
      return 'All';
    }
    if (trimmed.isEmpty) return '';
    final String lower = trimmed.toLowerCase();
    return lower[0].toUpperCase() + lower.substring(1);
  }
}
