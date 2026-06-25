class Formatters {
  Formatters._();

  static String formatRetryCountdown(int seconds) {
    if (seconds <= 0) return 'a moment';
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (minutes == 0) {
      return '$remainingSeconds second${remainingSeconds == 1 ? '' : 's'}';
    }
    if (remainingSeconds == 0) {
      return '$minutes minute${minutes == 1 ? '' : 's'}';
    }
    return '$minutes minute${minutes == 1 ? '' : 's'} and '
        '$remainingSeconds second${remainingSeconds == 1 ? '' : 's'}';
  }

  static String maskPhone(String phone) {
    if (phone.length < 4) return phone;
    final visible = phone.substring(phone.length - 4);
    return '***$visible';
  }

  static String maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final name = parts[0];
    if (name.length <= 2) return email;
    return '${name.substring(0, 2)}***@${parts[1]}';
  }
}
