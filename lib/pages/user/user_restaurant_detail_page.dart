import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';

class UserRestaurantDetailPage extends StatefulWidget {
  final String restaurantId;
  final Map<String, dynamic> data;
  const UserRestaurantDetailPage({super.key, required this.restaurantId, required this.data});

  @override
  State<UserRestaurantDetailPage> createState() => _UserRestaurantDetailPageState();
}

class _UserRestaurantDetailPageState extends State<UserRestaurantDetailPage> {
  bool isFavorite = false;
  String selectedOrderType = "Dine-in";
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
  }

  void _checkIfFavorite() async {
    if (user != null) {
      var doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).collection('favorites').doc(widget.restaurantId).get();
      setState(() => isFavorite = doc.exists);
    }
  }

  void _toggleFavorite() async {
    final favRef = FirebaseFirestore.instance.collection('users').doc(user!.uid).collection('favorites').doc(widget.restaurantId);
    setState(() => isFavorite = !isFavorite);
    isFavorite ? await favRef.set({'name': widget.data['name'], 'imageUrl': widget.data['imageUrl'], 'cuisine': widget.data['cuisine'], 'priceRange': widget.data['priceRange']}) : await favRef.delete();
  }

  void _showRealCheckout(CartProvider cart) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Review Your Order", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const Divider(),
              ...cart.items.values.map((item) => ListTile(title: Text(item.name), trailing: Text("${item.quantity}x ₱${item.price}"))),
              const Divider(),
              const Text("Service Type:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ToggleButtons(
                isSelected: [selectedOrderType == "Dine-in", selectedOrderType == "Take-out"],
                onPressed: (index) => setModalState(() => selectedOrderType = index == 0 ? "Dine-in" : "Take-out"),
                borderRadius: BorderRadius.circular(10),
                selectedColor: Colors.white,
                fillColor: const Color(0xFFE46A3E),
                children: const [Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text("Dine-in")), Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text("Take-out"))],
              ),
              const SizedBox(height: 20),
              Text("Total: ₱${cart.total.toStringAsFixed(2)}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFE46A3E))),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  // Finalizing order
                  String itemSummary = cart.items.values.map((i) => "${i.quantity}x ${i.name}").join(", ");
                  var orderData = {
                    'restaurantId': widget.restaurantId,
                    'restaurantName': widget.data['name'],
                    'total': double.parse(cart.total.toStringAsFixed(2)),
                    'items': itemSummary,
                    'status': 'Pending',
                    'orderType': selectedOrderType,
                    'isPaid': true, // Simulated payment
                    'timestamp': FieldValue.serverTimestamp(),
                  };

                  // Save to User History
                  await FirebaseFirestore.instance.collection('users').doc(user?.uid).collection('orders').add(orderData);
                  // Save to Restaurant Queue
                  await FirebaseFirestore.instance.collection('restaurants').doc(widget.restaurantId).collection('orders').add(orderData);

                  cart.clear();
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Payment Verified! Order Sent."), backgroundColor: Colors.green));
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, minimumSize: const Size(double.infinity, 50)),
                child: const Text("PAY NOW & ORDER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        floatingActionButton: cart.totalItems > 0 ? FloatingActionButton.extended(onPressed: () => _showRealCheckout(cart), backgroundColor: const Color(0xFFE46A3E), label: Text("Review Order (₱${cart.total.toStringAsFixed(2)})", style: const TextStyle(color: Colors.white))) : null,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              expandedHeight: 200, pinned: true, backgroundColor: const Color(0xFFE46A3E),
              actions: [IconButton(icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border, color: isFavorite ? Colors.red : Colors.white), onPressed: _toggleFavorite)],
              flexibleSpace: FlexibleSpaceBar(title: Text(widget.data['name']), background: widget.data['imageUrl'] != "" ? Image.network(widget.data['imageUrl'], fit: BoxFit.cover) : Container(color: Colors.grey)),
            ),
            const SliverToBoxAdapter(child: TabBar(labelColor: Color(0xFFE46A3E), tabs: [Tab(text: "Menu"), Tab(text: "Vouchers")])),
          ],
          body: TabBarView(children: [_buildMenuTab(cart), _buildVouchersTab(cart)]),
        ),
      ),
    );
  }

  Widget _buildMenuTab(CartProvider cart) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('restaurants').doc(widget.restaurantId).collection('menu').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final items = snapshot.data!.docs;
        return ListView.builder(itemCount: items.length, itemBuilder: (context, index) {
          var item = items[index].data();
          return ListTile(title: Text(item['name']), subtitle: Text("₱${item['price']}"), trailing: IconButton(icon: const Icon(Icons.add_circle, color: Color(0xFFE46A3E)), onPressed: () => cart.addItem(items[index].id, item['name'], (item['price'] as num).toDouble())));
        });
      },
    );
  }

  Widget _buildVouchersTab(CartProvider cart) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('restaurants').doc(widget.restaurantId).collection('vouchers').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final vouchers = snapshot.data!.docs;
        return ListView(children: vouchers.map((v) => ListTile(title: Text("${v['code']} - ${v['discount']}% Off"), trailing: ElevatedButton(onPressed: () => cart.applyVoucher(v['code'], (v['discount'] as num).toDouble()), child: const Text("Apply")))).toList());
      },
    );
  }
}