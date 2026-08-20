class ReceiveDocumentUnitHelper {
  static String normalizeUnit(String? unit) {
    if (unit == null) return 'шт';
    switch (unit.toLowerCase().trim()) {
      case 'pcs':
      case 'pc':
      case 'шт':
        return 'шт';
      case 'kg':
      case 'кг':
        return 'кг';
      case 'g':
      case 'г':
      case 'gr':
        return 'г';
      case 'l':
      case 'л':
        return 'л';
      case 'ml':
      case 'мл':
        return 'мл';
      case 'portion':
      case 'порц':
      case 'порция':
        return 'порц';
      default:
        return 'шт';
    }
  }
}
