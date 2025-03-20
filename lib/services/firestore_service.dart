import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shopping_list_item.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getShoppingLists(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('shoppingLists')
        .snapshots();
  }

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

  Future<void> deleteShoppingList(String userId, String listId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('shoppingLists')
        .doc(listId)
        .delete();
  }
}
