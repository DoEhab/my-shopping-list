class AppConstants {
  static const String appName = 'E-Shopping List';

  // Collection names
  static const String usersCollection = 'users';
  static const String shoppingListsCollection = 'shoppingLists';

  // Field names
  static const String nameField = 'name';
  static const String itemsField = 'items';

  // Error messages
  static const String errorEmptyName = 'Please enter a name for the list';
  static const String errorEmptyItem = 'Please enter an item name';
  static const String errorInvalidUrl = 'Please enter a valid URL';

  // Success messages
  static const String successListCreated = 'Shopping list created successfully';
  static const String successListUpdated = 'Shopping list updated successfully';
  static const String successListDeleted = 'Shopping list deleted successfully';

  // UI constants
  static const double cardElevation = 2.0;
  static const double cardBorderRadius = 8.0;
  static const double imageSize = 50.0;
}
