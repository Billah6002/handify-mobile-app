import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProductPage extends StatefulWidget {
  const ProductPage({super.key});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  // final List<Product> _products = [
  //   Product(
  //     id: '1',
  //     name: 'Wireless Headphones',
  //     price: 129.99,
  //     imageUrl:
  //         'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1000&q=80',
  //   ),
  //   Product(
  //     id: '2',
  //     name: 'Smart Watch',
  //     price: 199.99,
  //     imageUrl:
  //         'https://images.unsplash.com/photo-1523275335684-37898b6baf30?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1000&q=80',
  //   ),
  //   Product(
  //     id: '3',
  //     name: 'Fitness Tracker',
  //     price: 89.99,
  //     imageUrl:
  //         'https://images.unsplash.com/photo-1575311373937-040b8e1fd5b6?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1000&q=80',
  //   ),
  //   Product(
  //     id: '4',
  //     name: 'Bluetooth Speaker',
  //     price: 79.99,
  //     imageUrl:
  //         'https://images.unsplash.com/photo-1608043152269-423dbba4e7e1?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1000&q=80',
  //   ),
  //   Product(
  //     id: '5',
  //     name: 'Smartphone',
  //     price: 699.99,
  //     imageUrl:
  //         'https://images.unsplash.com/photo-1592899677977-9c10ca588bbd?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1000&q=80',
  //   ),
  //   Product(
  //     id: '6',
  //     name: 'Gaming Controller',
  //     price: 59.99,
  //     imageUrl:
  //         'https://images.unsplash.com/photo-1593118247619-e2d6f056869e?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1000&q=80',
  //   ),
  // ];
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('products').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No products found'));
        }
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              return ProductCard(product: (snapshot.data!.docs as List)[index]);
            },
          ),
        );
      },
    );
  }
}

class ProductCard extends StatefulWidget {
  final product;

  const ProductCard({super.key, required this.product});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  Future<void> _addToCart() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to add items to your cart'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final name = widget.product['name'] as String;
    final res = await FirebaseFirestore.instance.collection('cart').add({
      'name': widget.product['name'],
      'price': widget.product['price'],
      'imageUrl': widget.product['imageUrl'],
      'userId': uid,
    });
    if (res.id.isNotEmpty) {
      // Successfully added to database
      // print(res);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Product $name added to Cart')));
    } else {
      // Failed to add to database
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to add to Cart')));
    }
  }

  Future<void> _deleteProduct() async {
    if (widget.product['userId'] != FirebaseAuth.instance.currentUser?.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can only delete your own products'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    try {
      await FirebaseFirestore.instance
          .collection('products')
          .doc(widget.product.id)
          .delete();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.product['name']} deleted successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting product: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: SizedBox(
              height: 120,
              width: double.infinity,
              child: Image.network(
                widget.product['imageUrl'],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(Icons.error, color: Colors.white),
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value:
                          loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  (loadingProgress.expectedTotalBytes ?? 1)
                              : null,
                    ),
                  );
                },
              ),
            ),
          ),

          // Product Details
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.product['name'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${widget.product['price'].toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Action Buttons
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Delete Button
                  FloatingActionButton.small(
                    onPressed: _deleteProduct,
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    child: const Icon(Icons.delete),
                  ),

                  // Add to Cart Button
                  FloatingActionButton.small(
                    onPressed: () {
                      _addToCart();
                    },
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    child: const Icon(Icons.add_shopping_cart),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// class Product {
//   final String id;
//   final String name;
//   final double price;
//   final String imageUrl;

//   Product({
//     required this.id,
//     required this.name,
//     required this.price,
//     required this.imageUrl,
//   });
// }
