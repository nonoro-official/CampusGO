import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';

class UserRestaurantDetailPage extends StatefulWidget {
  final String restaurantId;
  final Map<String, dynamic> data;

  const UserRestaurantDetailPage({
    super.key,
    required this.restaurantId,
    required this.data,
  });

  @override
  State<UserRestaurantDetailPage> createState() => _UserRestaurantDetailPageState();
}

class _UserRestaurantDetailPageState extends State<UserRestaurantDetailPage> {
  bool isFavorite = false;
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
    if (user == null) return;
    final favRef = FirebaseFirestore.instance.collection('users').doc(user!.uid).collection('favorites').doc(widget.restaurantId);

    setState(() => isFavorite = !isFavorite);

    if (isFavorite) {
      await favRef.set({
        'name': widget.data['name'],
        'imageUrl': widget.data['imageUrl'],
        'cuisine': widget.data['cuisine'],
        'priceRange': widget.data['priceRange'],
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Added to Saved Places!")));
    } else {
      await favRef.delete();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Removed from Saved Places.")));
    }
  }

  void _showRealCheckout(CartProvider cart) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Your Pre-Order", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Divider(),
            ...cart.items.values.map((item) => ListTile(
              title: Text(item.name),
              trailing: Text("${item.quantity}x ₱${item.price}"),
            )),
            const Divider(),
            if (cart.discountPercentage > 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Text("Discount: -${cart.discountPercentage.toInt()}% (${cart.appliedVoucherCode})",
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ),
            Text("Total: ₱${cart.total.toStringAsFixed(2)}",
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFE46A3E))),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                String itemSummary = cart.items.values.map((i) => "${i.quantity}x ${i.name}").join(", ");

                await FirebaseFirestore.instance.collection('users').doc(user?.uid).collection('orders').add({
                  'restaurantId': widget.restaurantId,
                  'restaurantName': widget.data['name'],
                  'total': double.parse(cart.total.toStringAsFixed(2)),
                  'items': itemSummary,
                  'status': 'Pending',
                  'timestamp': FieldValue.serverTimestamp(),
                });

                cart.clear();
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("🎉 Order Placed Successfully!"), backgroundColor: Colors.green));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE46A3E),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text("Confirm & Place Order", style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    String imageUrl = widget.data['imageUrl'] ?? '';
    String name = widget.data['name'] ?? 'Unknown Restaurant';

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        floatingActionButton: cart.totalItems > 0
            ? FloatingActionButton.extended(
          onPressed: () => _showRealCheckout(cart),
          backgroundColor: const Color(0xFFE46A3E),
          icon: const Icon(Icons.shopping_bag, color: Colors.white),
          label: Text("Review Order (₱${cart.total.toStringAsFixed(2)})", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        )
            : null,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 250.0,
                pinned: true,
                backgroundColor: const Color(0xFFE46A3E),
                foregroundColor: Colors.white,
                actions: [
                  IconButton(
                    icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border, color: isFavorite ? Colors.red : Colors.white),
                    onPressed: _toggleFavorite,
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black54, blurRadius: 4)])),
                  background: imageUrl.isNotEmpty
                      ? Image.network(imageUrl, fit: BoxFit.cover)
                      : Container(color: Colors.grey.shade300, child: const Icon(Icons.restaurant, size: 80, color: Colors.grey)),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [const Icon(Icons.access_time, size: 16, color: Color(0xFFE46A3E)), const SizedBox(width: 5), Text(widget.data['operatingHours'] ?? 'Hours unlisted', style: const TextStyle(fontWeight: FontWeight.bold))]),
                      const SizedBox(height: 5),
                      Text("📍 ${widget.data['address'] ?? 'No address'}"),
                      if (widget.data['contactNumber'] != null) Text("📞 ${widget.data['contactNumber']}"),
                      const SizedBox(height: 10),
                      Text(widget.data['description'] ?? '', style: TextStyle(color: Colors.grey.shade700)),
                    ],
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  const TabBar(
                    labelColor: Color(0xFFE46A3E),
                    indicatorColor: Color(0xFFE46A3E),
                    tabs: [Tab(icon: Icon(Icons.restaurant_menu), text: "Menu"), Tab(icon: Icon(Icons.local_offer), text: "Vouchers")],
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [
              _buildMenuTab(cart),
              _buildVouchersTab(cart),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuTab(CartProvider cart) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('restaurants').doc(widget.restaurantId).collection('menu').orderBy('category').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final items = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: items.length,
          itemBuilder: (context, index) {
            var item = items[index].data() as Map<String, dynamic>;
            return Card(
              child: ListTile(
                title: Text(item['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("${item['category']} • ₱${item['price']}"),
                trailing: IconButton(
                  icon: const Icon(Icons.add_circle, color: Color(0xFFE46A3E), size: 30),
                  onPressed: () => cart.addItem(items[index].id, item['name'], (item['price'] as num).toDouble()),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildVouchersTab(CartProvider cart) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('restaurants').doc(widget.restaurantId).collection('vouchers').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final vouchers = snapshot.data!.docs;
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            ...vouchers.map((v) => Card(
              child: ListTile(
                title: Text("${v['discount']}% OFF", style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Code: ${v['code']}"),
                trailing: ElevatedButton(
                  onPressed: () {
                    cart.applyVoucher(v['code'], (v['discount'] as num).toDouble());
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Voucher ${v['code']} applied!")));
                  },
                  child: const Text("Apply"),
                ),
              ),
            )),
          ],
        );
      },
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);
  final TabBar _tabBar;
  @override double get minExtent => _tabBar.preferredSize.height;
  @override double get maxExtent => _tabBar.preferredSize.height;
  @override Widget build(context, shrinkOffset, overlapsContent) => Container(color: Colors.white, child: _tabBar);
  @override bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}