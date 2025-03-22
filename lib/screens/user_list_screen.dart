import 'package:e_shopping_list/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../models/shopping_list_item.dart';
import '../services/firestore_service.dart';
import '../widgets/shopping_list_card.dart';
import '../utils/constants.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({Key? key}) : super(key: key);

  @override
  _UserListScreenState createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _itemController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _createList() async {
    // Show dialog to get list name
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New List'),
        content: TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'List Name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (_nameController.text.isEmpty) {
                Fluttertoast.showToast(msg: AppConstants.errorEmptyName);
                return;
              }

              setState(() => _isLoading = true);
              try {
                await _firestoreService.createShoppingList(
                  _auth.currentUser!.uid,
                  _nameController.text,
                  [],
                );
                _nameController.clear();
                Fluttertoast.showToast(msg: AppConstants.successListCreated);
                Navigator.pop(context);
              } catch (e) {
                Fluttertoast.showToast(msg: 'Error creating list: $e');
              } finally {
                setState(() => _isLoading = false);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _addItem(String listId, List<ShoppingListItem> currentItems,
      String listName) async {
    if (_itemController.text.isEmpty) {
      Fluttertoast.showToast(msg: AppConstants.errorEmptyItem);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final newItem = ShoppingListItem(
        name: _itemController.text,
        link: _linkController.text.isNotEmpty ? _linkController.text : null,
        isChecked: false,
      );

      final updatedItems = [...currentItems, newItem];
      await _firestoreService.updateShoppingList(
        _auth.currentUser!.uid,
        listId,
        listName,
        updatedItems,
      );

      _itemController.clear();
      _linkController.clear();
      Fluttertoast.showToast(msg: 'Item added successfully');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error adding item: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteItem(String listId, List<ShoppingListItem> currentItems,
      int index, String listName) async {
    setState(() => _isLoading = true);
    try {
      final updatedItems = List<ShoppingListItem>.from(currentItems)
        ..removeAt(index);
      await _firestoreService.updateShoppingList(
        _auth.currentUser!.uid,
        listId,
        listName,
        updatedItems,
      );
      Fluttertoast.showToast(msg: 'Item deleted successfully');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error deleting item: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleItemCheck(String listId,
      List<ShoppingListItem> currentItems, int index, String listName) async {
    setState(() => _isLoading = true);
    try {
      final updatedItems = List<ShoppingListItem>.from(currentItems);
      updatedItems[index] = updatedItems[index].copyWith(
        isChecked: !updatedItems[index].isChecked,
      );

      await _firestoreService.updateShoppingList(
        _auth.currentUser!.uid,
        listId,
        listName,
        updatedItems,
      );
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error updating item: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteList(String listId, [BuildContext? dialogContext]) async {
    // Show confirmation dialog
    final bool? confirm = await showDialog<bool>(
      context: dialogContext ?? context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Delete List'),
        content: const Text('Are you sure you want to delete this list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await _firestoreService.deleteShoppingList(
          _auth.currentUser!.uid,
          listId,
        );
        if (dialogContext != null) {
          Navigator.of(dialogContext)
              .pop(); // Pop the detail screen if we're in it
        }
        Fluttertoast.showToast(msg: AppConstants.successListDeleted);
      } catch (e) {
        Fluttertoast.showToast(msg: 'Error deleting list: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const Login(),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: StreamBuilder(
        stream: _firestoreService.getShoppingLists(_auth.currentUser!.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final lists = snapshot.data?.docs ?? [];

          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
              childAspectRatio: 0.8,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: lists.length,
            itemBuilder: (context, index) {
              final list = lists[index];
              final items = (list['items'] as List).map((item) {
                if (item is String) {
                  return ShoppingListItem(name: item);
                }
                return ShoppingListItem.fromMap(item as Map<String, dynamic>);
              }).toList();

              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    ListTile(
                      title: Text(
                        list['name'] ?? 'Unnamed List',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteList(list.id, context),
                        tooltip: 'Delete List',
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => Scaffold(
                                appBar: AppBar(
                                  title: Text(list['name'] ?? 'Unnamed List'),
                                  actions: [
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () =>
                                          _deleteList(list.id, context),
                                      tooltip: 'Delete List',
                                    ),
                                  ],
                                ),
                                body: Column(
                                  children: [
                                    Expanded(
                                      child: ListView(
                                        padding: const EdgeInsets.all(8),
                                        children: [
                                          if (items.isEmpty)
                                            const Padding(
                                              padding: EdgeInsets.all(16.0),
                                              child: Center(
                                                child: Text(
                                                  'No items yet',
                                                  style: TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ),
                                            )
                                          else
                                            ...items
                                                .map((item) => ShoppingListCard(
                                                      item: item,
                                                      onDelete: () => _deleteItem(
                                                          list.id,
                                                          items,
                                                          items.indexOf(item),
                                                          list['name'] ??
                                                              'Unnamed List'),
                                                      onCheckChanged:
                                                          (checked) =>
                                                              _toggleItemCheck(
                                                        list.id,
                                                        items,
                                                        items.indexOf(item),
                                                        list['name'] ??
                                                            'Unnamed List',
                                                      ),
                                                    )),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          TextField(
                                            controller: _itemController,
                                            decoration: const InputDecoration(
                                              labelText: 'Item Name',
                                              border: OutlineInputBorder(),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          TextField(
                                            controller: _linkController,
                                            decoration: const InputDecoration(
                                              labelText:
                                                  'Product Link (Optional)',
                                              border: OutlineInputBorder(),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          ElevatedButton(
                                            onPressed: _isLoading
                                                ? null
                                                : () => _addItem(
                                                      list.id,
                                                      items,
                                                      list['name'] ??
                                                          'Unnamed List',
                                                    ),
                                            child: _isLoading
                                                ? const SizedBox(
                                                    height: 20,
                                                    width: 20,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                                  )
                                                : const Text('Add Item'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                        child: Container(
                          color: Colors.grey[50],
                          child: ListView(
                            padding: const EdgeInsets.all(8),
                            children: [
                              if (items.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Center(
                                    child: Text(
                                      'No items yet',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                ...items.take(3).map((item) => ListTile(
                                      title: Text(
                                        item.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      leading: Icon(
                                        item.isChecked
                                            ? Icons.check_box
                                            : Icons.check_box_outline_blank,
                                        color: item.isChecked
                                            ? Colors.green
                                            : null,
                                      ),
                                    )),
                              if (items.length > 3)
                                const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text(
                                    'Tap to see more...',
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontSize: 12,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading ? null : _createList,
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.add),
      ),
    );
  }
}
