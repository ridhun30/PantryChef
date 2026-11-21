/// Tidies a name the user typed: trims it and collapses runs of spaces, so
/// "  Olive   oil " is stored as "Olive oil".
String tidyName(String name) => name.trim().replaceAll(RegExp(r'\s+'), ' ');

/// The form two names are compared in: tidied and lower-cased, so "Egg",
/// "egg " and "EGG" count as the same name.
String nameKey(String name) => tidyName(name).toLowerCase();

/// Orders names alphabetically regardless of case ("apple" before "Banana").
int compareNames(String a, String b) {
  final byKey = a.toLowerCase().compareTo(b.toLowerCase());
  return byKey != 0 ? byKey : a.compareTo(b);
}
