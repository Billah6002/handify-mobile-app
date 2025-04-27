import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // This would typically come from a state management solution or a service
  // For now, we'll use a static list for demonstration
  // final List<CartItem> _cartItems = [
  //   CartItem(
  //     product: Product(
  //       id: '1',
  //       name: 'Wireless Headphones',
  //       price: 129.99,
  //       imageUrl:
  //           'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1000&q=80',
  //     ),
  //   ),
  //   CartItem(
  //     product: Product(
  //       id: '3',
  //       name: 'Fitness Tracker',
  //       price: 89.99,
  //       imageUrl:
  //           'https://images.unsplash.com/photo-1575311373937-040b8e1fd5b6?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1000&q=80',
  //     ),
  //   ),
  // ];

  double _totalAmount(List<dynamic> cartItems) {
    double total = 0;
    for (double item in cartItems) {
      total += item;
    }
    return total;
  }

  void _removeFromCart(String productId) {
    setState(() {
      FirebaseFirestore.instance.collection('cart').doc(productId).delete();
      // _cartItems.removeWhere((item) => item.product.id == productId);
    });
  }

  void _checkout(List<dynamic> cartItems) {
    if (cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your cart is empty!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    double totalAmount = _totalAmount(cartItems);
    // Implement checkout logic here
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Checkout completed. Total: \$${totalAmount.toStringAsFixed(2)}',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Clear cart after checkout
    setState(() {
      FirebaseFirestore.instance
          .collection('cart')
          .where('userId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
          .get()
          .then((snapshot) {
            for (var doc in snapshot.docs) {
              doc.reference.delete();
            }
          });
      // _cartItems.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart', style: TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: StreamBuilder(
        stream:
            FirebaseFirestore.instance
                .collection('cart')
                .where(
                  'userId',
                  isEqualTo: FirebaseAuth.instance.currentUser!.uid,
                )
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('Your cart is empty', style: TextStyle(fontSize: 18)),
            );
          }
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final cartItem = snapshot.data!.docs[index];
                    return CartItemWidget(
                      cartItem: cartItem,
                      onRemove:
                          () => _removeFromCart(snapshot.data!.docs[index].id),
                    );
                  },
                ),
              ),
              CheckoutSummary(
                totalAmount: _totalAmount(
                  snapshot.data!.docs.map((doc) => doc['price']).toList(),
                ),
                onCheckout:
                    () => _checkout(
                      snapshot.data!.docs.map((doc) => doc['price']).toList(),
                    ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class CartItemWidget extends StatelessWidget {
  final cartItem;
  final VoidCallback onRemove;

  const CartItemWidget({
    super.key,
    required this.cartItem,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            // Product Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 80,
                height: 80,
                child: Image.network(
                  cartItem['imageUrl'],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Center(
                        child: Icon(Icons.error, color: Colors.white),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cartItem['name'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${cartItem['price'].toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // Delete Button
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}

class CheckoutSummary extends StatelessWidget {
  final double totalAmount;
  final VoidCallback onCheckout;

  const CheckoutSummary({
    super.key,
    required this.totalAmount,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(51),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                '\$${totalAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onCheckout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'CHECKOUT',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Cart Item Model
// class CartItem {
//   final Product product;

//   CartItem({required this.product});
// }

// Product Model (using the same model as in home_page.dart)
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
