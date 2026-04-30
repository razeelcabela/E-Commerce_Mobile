import 'package:flutter/material.dart';
import 'models/product.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  // Mock data - hardcoded list of products
  List<Product> products = [
    Product(
      id: 1,
      name: 'Wireless Headphones',
      price: 99.99,
      description: 'High-quality wireless headphones with noise cancellation',
      category: 'Electronics',
      imageUrl: 'https://via.placeholder.com/150',
    ),
    Product(
      id: 2,
      name: 'Smart Watch',
      price: 249.99,
      description: 'Fitness tracking smartwatch with heart rate monitor',
      category: 'Electronics',
      imageUrl: 'https://via.placeholder.com/150',
    ),
    Product(
      id: 3,
      name: 'Coffee Maker',
      price: 79.99,
      description: 'Programmable coffee maker with thermal carafe',
      category: 'Appliances',
      imageUrl: 'https://via.placeholder.com/150',
    ),
    Product(
      id: 4,
      name: 'Running Shoes',
      price: 129.99,
      description: 'Comfortable running shoes with advanced cushioning',
      category: 'Sports',
      imageUrl: 'https://via.placeholder.com/150',
    ),
    Product(
      id: 5,
      name: 'Laptop Stand',
      price: 39.99,
      description: 'Adjustable laptop stand for better ergonomics',
      category: 'Accessories',
      imageUrl: 'https://via.placeholder.com/150',
    ),
    Product(
      id: 6,
      name: 'Bluetooth Speaker',
      price: 59.99,
      description: 'Portable Bluetooth speaker with waterproof design',
      category: 'Electronics',
      imageUrl: 'https://via.placeholder.com/150',
    ),
  ];

  void _addProduct(Product product) {
    setState(() {
      products.add(product);
    });
  }

  void _updateProduct(Product updatedProduct) {
    setState(() {
      final index = products.indexWhere((p) => p.id == updatedProduct.id);
      if (index != -1) {
        products[index] = updatedProduct;
      }
    });
  }

  void _deleteProduct(int id) {
    setState(() {
      products.removeWhere((p) => p.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: ListView.builder(
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: Image.network(
                product.imageUrl,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.image, size: 50),
              ),
              title: Text(product.name),
              subtitle: Text('\$${product.price.toStringAsFixed(2)}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/form',
                        arguments: {'product': product, 'onSave': _updateProduct},
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteProduct(product.id),
                  ),
                ],
              ),
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/detail',
                  arguments: product,
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(
            context,
            '/form',
            arguments: {'onSave': _addProduct},
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}