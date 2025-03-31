import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../widgets/logo_widget.dart';
import 'calendar_screen.dart';
import 'item_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _rawItems = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Fetch raw data first (already sorted in API service)
      final rawData = await _apiService.getItems();

      setState(() {
        // Use the pre-sorted data from the API
        _rawItems = rawData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  // Helper method to get shortened ID
  String _getShortenedId(dynamic item) {
    try {
      String fullId;
      if (item['_id'] is String) {
        fullId = item['_id'];
      } else if (item['_id'] is Map && item['_id']['\$oid'] != null) {
        fullId = item['_id']['\$oid'];
      } else {
        fullId = item['_id'].toString();
      }

      if (fullId.length > 6) {
        return '...${fullId.substring(fullId.length - 6)}';
      }
      return fullId;
    } catch (e) {
      return '';
    }
  }

  // Helper method to format dates
  String _formatDate(dynamic dateValue) {
    try {
      DateTime date;
      if (dateValue is String) {
        date = DateTime.parse(dateValue);
      } else if (dateValue is Map && dateValue['\$date'] != null) {
        if (dateValue['\$date'] is String) {
          date = DateTime.parse(dateValue['\$date']);
        } else if (dateValue['\$date'] is Map &&
            dateValue['\$date']['\$numberLong'] != null) {
          date = DateTime.fromMillisecondsSinceEpoch(
            int.parse(dateValue['\$date']['\$numberLong']),
          );
        } else {
          return '';
        }
      } else {
        return '';
      }

      // Format date as "MM/dd/yyyy"
      return "${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}";
    } catch (e) {
      return '';
    }
  }

  // Helper method to get appropriate icon for service type
  IconData _getServiceTypeIcon(String serviceType) {
    // Convert to lowercase for case-insensitive comparison
    final type = serviceType.toLowerCase();

    if (type.contains('tv') || type.contains('television')) {
      if (type.contains('mount') || type.contains('install')) {
        return Icons.live_tv;
      }
      return Icons.tv;
    } else if (type.contains('furniture')) {
      if (type.contains('assembly')) {
        return Icons.chair;
      } else if (type.contains('delivery')) {
        return Icons.local_shipping;
      }
      return Icons.weekend;
    } else if (type.contains('shelf') || type.contains('shelves')) {
      return Icons.book_online; // Bookshelf related
    } else if (type.contains('picture') ||
        type.contains('photo') ||
        type.contains('frame')) {
      return Icons.image; // Image/picture related
    } else if (type.contains('hang') || type.contains('hanging')) {
      if (type.contains('picture') ||
          type.contains('photo') ||
          type.contains('frame')) {
        return Icons.image; // Use image icon for hanging pictures
      }
      return Icons.format_paint;
    } else if (type.contains('paint')) {
      return Icons.brush; // Use brush icon for painting
    } else if (type.contains('curtain') || type.contains('blind')) {
      return Icons.blinds; // Standard blinds icon
    } else if (type.contains('network') || type.contains('wifi')) {
      return Icons.wifi;
    } else if (type.contains('clean')) {
      return Icons.cleaning_services;
    } else if (type.contains('electric')) {
      return Icons.electrical_services;
    } else if (type.contains('lamp') || type.contains('light fixture')) {
      return Icons.lightbulb; // Use lightbulb icon for lamps
    } else if (type.contains('wall fixture') ||
        type.contains('wall mount') ||
        type.contains('wall installation')) {
      return Icons.hardware; // Use drill/hardware icon for wall fixtures
    } else if (type.contains('plumb') ||
        type.contains('toilet') ||
        type.contains('bathroom')) {
      return Icons.bathroom; // Use toilet/bathroom icon for plumbing
    }

    // Default icon
    return Icons.handyman;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const ElegoPrimeLogo(
          showSvgLogo: true,
          alignment: MainAxisAlignment.start,
        ),
        centerTitle: false,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadItems,
            tooltip: 'Refresh',
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
              child: const ElegoPrimeLogo(
                showSvgLogo: true,
                alignment: MainAxisAlignment.center,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context); // Close drawer
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month),
              title: const Text('Manage Availability'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CalendarScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to add item screen
          // You can implement this later
        },
        tooltip: 'Add Request',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_errorMessage'),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadItems, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_rawItems.isEmpty) {
      return const Center(child: Text('No service requests found'));
    }

    // Simple list view of raw items
    return RefreshIndicator(
      onRefresh: _loadItems,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _rawItems.length,
        itemBuilder: (context, index) {
          final item = _rawItems[index];
          final serviceType = item['serviceType'] ?? 'Unknown';

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.primary.withOpacity(0.1),
                child: Icon(
                  _getServiceTypeIcon(serviceType),
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              title: Row(
                children: [
                  Expanded(child: Text(item['name'] ?? 'No name')),
                  Text(
                    'ID: ${_getShortenedId(item)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Type: $serviceType'),
                  Text('Phone: ${item['phone'] ?? 'Unknown'}'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Status: ${item['state'] ?? 'Unknown'}'),
                      if (item['createdAt'] != null)
                        Text(
                          _formatDate(item['createdAt']),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              onTap: () {
                // Extract the ID correctly based on format
                String id;
                if (item['_id'] is String) {
                  id = item['_id'];
                } else if (item['_id'] is Map && item['_id']['\$oid'] != null) {
                  id = item['_id']['\$oid'];
                } else {
                  id = item['_id'].toString();
                }

                if (id.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ItemDetailScreen(itemId: id),
                    ),
                  ).then((_) => _loadItems());
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Error: No ID available for this item'),
                    ),
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }
}
