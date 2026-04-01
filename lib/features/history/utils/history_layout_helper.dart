class HistoryLayoutHelper {
  static double calculateTop(double tapY, double maxHeight, double cardHeight) {
    const double spacing = 16.0;
    if (tapY - cardHeight - spacing > 0) {
      return tapY - cardHeight - spacing;
    } else {
      double top = tapY + spacing;
      if (top + cardHeight > maxHeight) {
        return (maxHeight - cardHeight > 0) ? maxHeight - cardHeight : 0;
      }
      return top;
    }
  }

  static double calculateLeft(double screenTapX, double maxWidth, double cardWidth) {
    double actualScreenTapX = screenTapX + 16.0;
    double left = actualScreenTapX - (cardWidth / 2);

    if (left < 16.0) left = 16.0;
    if (left + cardWidth > maxWidth - 16.0) left = maxWidth - cardWidth - 16.0;

    return left;
  }
}
