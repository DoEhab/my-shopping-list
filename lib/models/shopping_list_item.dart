class ShoppingListItem {
  final String name;
  final String? link;
  final String? imageUrl;
  final double? price;
  final bool isChecked;

  ShoppingListItem({
    required this.name,
    this.link,
    this.imageUrl,
    this.price,
    this.isChecked = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'link': link,
      'imageUrl': imageUrl,
      'price': price,
      'isChecked': isChecked,
    };
  }

  factory ShoppingListItem.fromMap(Map<String, dynamic> map) {
    return ShoppingListItem(
      name: map['name'] as String,
      link: map['link'] as String?,
      imageUrl: map['imageUrl'] as String?,
      price: map['price'] as double?,
      isChecked: map['isChecked'] as bool? ?? false,
    );
  }

  ShoppingListItem copyWith({
    String? name,
    String? link,
    String? imageUrl,
    double? price,
    bool? isChecked,
  }) {
    return ShoppingListItem(
      name: name ?? this.name,
      link: link ?? this.link,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      isChecked: isChecked ?? this.isChecked,
    );
  }
}
