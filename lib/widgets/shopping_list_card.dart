import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/shopping_list_item.dart';

class ShoppingListCard extends StatefulWidget {
  final ShoppingListItem item;
  final VoidCallback onDelete;
  final Function(bool) onCheckChanged;

  const ShoppingListCard({
    Key? key,
    required this.item,
    required this.onDelete,
    required this.onCheckChanged,
  }) : super(key: key);

  @override
  State<ShoppingListCard> createState() => _ShoppingListCardState();
}

class _ShoppingListCardState extends State<ShoppingListCard> {
  bool _isExpanded = false;

  Future<void> _launchUrl() async {
    String? link = widget.item.link;

    if (link == null || link.isEmpty) {
      debugPrint("Error: URL is null or empty");
      return;
    }

    if (!link.startsWith("http")) {
      link = "https://$link";
    }

    if (await canLaunchUrl(Uri.parse(link))) {
      await launchUrl(Uri.parse(link));
    } else {
      debugPrint("Error: Cannot launch $link");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          ListTile(
            leading: widget.item.imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      widget.item.imageUrl!,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  )
                : const Icon(Icons.shopping_cart),
            title: Text(widget.item.name),
            subtitle: widget.item.price != null
                ? Text(
                    'Price: \$${widget.item.price}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.item.link != null)
                  IconButton(
                    icon: const Icon(Icons.link),
                    onPressed: _launchUrl,
                    tooltip: 'Open product link',
                  ),
                Checkbox(
                  value: widget.item.isChecked,
                  onChanged: (bool? value) {
                    if (value != null) {
                      widget.onCheckChanged(value);
                    }
                  },
                ),
                IconButton(
                  icon: Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                  ),
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: widget.onDelete,
                ),
              ],
            ),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.item.link != null) ...[
                    const Text(
                      'Product Link:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    InkWell(
                      onTap: _launchUrl,
                      child: Text(
                        widget.item.link!,
                        style: const TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (widget.item.imageUrl != null) ...[
                    const Text(
                      'Product Image:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        widget.item.imageUrl!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (widget.item.price != null) ...[
                    const Text(
                      'Price:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '\$${widget.item.price!.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
