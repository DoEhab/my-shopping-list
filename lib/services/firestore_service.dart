import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shopping_list_item.dart';

/*
FirestoreService class handles all database operations
* */
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // selects all user saved lists
  Stream<QuerySnapshot> getShoppingLists(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('shoppingLists')
        .snapshots();
  }

  // adds new list to the database
  Future<void> createShoppingList(
      String userId, String name, List<ShoppingListItem> items) async {
    final itemsData = items.map((item) => item.toMap()).toList();
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('shoppingLists')
        .add({
      'name': name,
      'items': itemsData,
    });
  }

  // update existing list in the database
  Future<void> updateShoppingList(String userId, String listId, String name,
      List<ShoppingListItem> items) async {
    final itemsData = items.map((item) => item.toMap()).toList();
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('shoppingLists')
        .doc(listId)
        .update({
      'name': name,
      'items': itemsData,
    });
  }

  // deletes a list from the database
  Future<void> deleteShoppingList(String userId, String listId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('shoppingLists')
        .doc(listId)
        .delete();
  }
}
