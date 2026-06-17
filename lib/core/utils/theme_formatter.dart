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
    
    String formatted = trimmed.replaceAll(RegExp(r'graphy', caseSensitive: false), '');
    
    final String lower = formatted.toLowerCase();
    return lower[0].toUpperCase() + lower.substring(1);
  }
}
