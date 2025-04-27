import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _imageUrlController = TextEditingController();

  // For image preview
  bool _isValidImageUrl = false;

  @override
  void initState() {
    super.initState();
    _imageUrlController.addListener(_updateImageUrlValidity);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _imageUrlController.removeListener(_updateImageUrlValidity);
    _imageUrlController.dispose();
    super.dispose();
  }

  void _updateImageUrlValidity() {
    setState(() {
      if (_imageUrlController.text.startsWith('http') &&
          _imageUrlController.text.contains('.')) {
        _isValidImageUrl = true;
      } else {
        _isValidImageUrl = false;
      }
    });
  }

  Future<void> addProductToDatabase() async {
    final product = {
      'name': _nameController.text.trim(),
      'price': double.parse(_priceController.text.trim()),
      'imageUrl': _imageUrlController.text.trim(),
      'userId': FirebaseAuth.instance.currentUser?.uid,
    };
    final res = await FirebaseFirestore.instance
        .collection('products')
        .add(product);
    if (res.id.isNotEmpty) {
      // Successfully added to database
      // print(res);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product added to database')),
      );
    } else {
      // Failed to add to database
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to add product')));
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      addProductToDatabase();
      final newProduct = {
        'name': _nameController.text,
        'price': double.parse(_priceController.text),
        'imageUrl': _imageUrlController.text,
      };

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product added successfully!')),
      );

      // Return to previous screen with the new product data
      Navigator.of(context).pop(newProduct);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add New Product',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Image Preview
                Container(
                  height: 200,
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      _isValidImageUrl
                          ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              _imageUrlController.text,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (_, __, ___) => const Center(
                                    child: Text('Invalid image URL'),
                                  ),
                            ),
                          )
                          : const Center(
                            child: Text('Enter a valid image URL'),
                          ),
                ),

                // Product Name Field
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Product Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.shopping_bag),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a product name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Price Field
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Price (\$)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a price';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    if (double.parse(value) <= 0) {
                      return 'Price must be greater than zero';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Image URL Field
                TextFormField(
                  controller: _imageUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Image URL',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.image),
                    hintText: 'https://example.com/image.jpg',
                  ),
                  keyboardType: TextInputType.url,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an image URL';
                    }
                    if (!value.startsWith('http')) {
                      return 'Please enter a valid URL starting with http/https';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Submit Button
                ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text(
                    'Add Product',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
