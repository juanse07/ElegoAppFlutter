import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../widgets/logo_widget.dart';

class ItemDetailScreen extends StatefulWidget {
  final String itemId;

  const ItemDetailScreen({super.key, required this.itemId});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _itemData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadItem();
  }

  Future<void> _loadItem() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final data = await _apiService.getItemById(widget.itemId);

      setState(() {
        _itemData = data;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading item: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteItem() async {
    try {
      await _apiService.deleteItem(widget.itemId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item deleted successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting item: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const ElegoPrimeLogo(
          showSvgLogo: true,
          alignment: MainAxisAlignment.start,
        ),
        centerTitle: false,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed:
                _itemData == null
                    ? null
                    : () {
                      // Navigate to edit screen
                      // You can implement this later
                    },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed:
                _itemData == null
                    ? null
                    : () {
                      _showDeleteConfirmation();
                    },
          ),
        ],
      ),
      body: _buildBody(),
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
            ElevatedButton(onPressed: _loadItem, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_itemData == null) {
      return const Center(child: Text('Service request not found'));
    }

    final serviceType = _itemData!['serviceType'] ?? '';

    // Simple display of raw JSON data
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(serviceType),
          const Divider(height: 32),

          // Images section
          if (_hasImages()) _buildImageSection(),

          _buildDetailSection('Customer Details', icon: Icons.person),
          _buildDetailItem('Name', _itemData!['name'] ?? 'N/A'),
          _buildDetailItem('Phone', _itemData!['phone'] ?? 'N/A'),
          _buildDetailItem('Zip Code', _itemData!['zipCode'] ?? 'N/A'),

          const SizedBox(height: 16),
          _buildDetailSection(
            'Service Information',
            icon: _getServiceTypeIcon(serviceType),
          ),
          _buildDetailItem('Service Type', serviceType),
          _buildDetailItem(
            'TV Size',
            _itemData!['tvInches'] != null
                ? '${_itemData!['tvInches']}"'
                : 'N/A',
          ),
          _buildDetailItem(
            'Number of Items',
            _itemData!['numberOfItems']?.toString() ?? 'N/A',
          ),
          _buildDetailItem('Status', _itemData!['state'] ?? 'N/A'),

          const SizedBox(height: 16),
          _buildDetailSection(
            'Additional Information',
            icon: Icons.info_outline,
          ),
          Text(
            _itemData!['additionalInfo'] ??
                _itemData!['additionalInformation'] ??
                'No additional information provided',
          ),
        ],
      ),
    );
  }

  String _formatJson(Map<String, dynamic> json) {
    // Format the JSON nicely for display
    String result = '';

    // Define important fields to display first
    final List<String> priorityFields = [
      '_id',
      'name',
      'serviceType',
      'state',
      'image1Path',
      'image2Path',
      'furnitureImageUrl',
      'createdAt',
      'updatedAt',
      'requestedDate',
    ];

    // First display important fields
    for (var field in priorityFields) {
      if (json.containsKey(field)) {
        var value = json[field];
        // Highlight image paths
        if (field.contains('image') || field.contains('Image')) {
          result += '🖼️ $field: $value\n';
        } else {
          result += '$field: $value\n';
        }
      }
    }

    // Then display remaining fields
    json.forEach((key, value) {
      if (!priorityFields.contains(key)) {
        result += '$key: $value\n';
      }
    });

    return result;
  }

  bool _hasImages() {
    // Check for both old and new image path fields
    final image1Path = _itemData!['image1Path'];
    final image2Path = _itemData!['image2Path'];
    final furnitureImageUrl = _itemData!['furnitureImageUrl'];

    return (image1Path != null && image1Path.toString().isNotEmpty) ||
        (image2Path != null && image2Path.toString().isNotEmpty) ||
        (furnitureImageUrl != null && furnitureImageUrl.toString().isNotEmpty);
  }

  Widget _buildImageSection() {
    // Get both old and new image path fields
    final image1Path = _itemData!['image1Path'];
    final image2Path = _itemData!['image2Path'];
    final furnitureImageUrl = _itemData!['furnitureImageUrl'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailSection('Images', icon: Icons.photo_library),

        SizedBox(
          height: 200,
          child: Row(
            children: [
              // First try image1Path, if not available try furnitureImageUrl
              if (image1Path != null && image1Path.toString().isNotEmpty)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right:
                          image2Path != null && image2Path.toString().isNotEmpty
                              ? 8.0
                              : 0,
                    ),
                    child: _buildImageWidget(image1Path),
                  ),
                )
              else if (furnitureImageUrl != null &&
                  furnitureImageUrl.toString().isNotEmpty)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right:
                          image2Path != null && image2Path.toString().isNotEmpty
                              ? 8.0
                              : 0,
                    ),
                    child: _buildImageWidget(furnitureImageUrl),
                  ),
                ),

              // Show image2Path if available
              if (image2Path != null && image2Path.toString().isNotEmpty)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left:
                          (image1Path != null &&
                                      image1Path.toString().isNotEmpty) ||
                                  (furnitureImageUrl != null &&
                                      furnitureImageUrl.toString().isNotEmpty)
                              ? 8.0
                              : 0,
                    ),
                    child: _buildImageWidget(image2Path),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Divider(height: 24),
      ],
    );
  }

  Widget _buildImageWidget(String? path, {bool thumbnail = true}) {
    if (path == null || path.isEmpty) {
      return const Center(
        child: Icon(Icons.image_not_supported, size: 80, color: Colors.grey),
      );
    }

    final String fullImageUrl;
    if (path.startsWith('http')) {
      fullImageUrl = path;
    } else {
      // Remove the extra slash between domain and path
      if (path.startsWith('/')) {
        fullImageUrl = '${ApiService.apiFullUrl}$path';
      } else {
        fullImageUrl = '${ApiService.apiFullUrl}/$path';
      }
    }

    // For thumbnails, show a simple cached image
    if (thumbnail) {
      return GestureDetector(
        onTap: () {
          if (fullImageUrl.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => Scaffold(
                      appBar: AppBar(
                        title: Text(_getFileName(path)),
                        backgroundColor: Colors.black,
                      ),
                      body: Container(
                        color: Colors.black,
                        child: Center(
                          child: InteractiveViewer(
                            boundaryMargin: const EdgeInsets.all(20),
                            minScale: 0.1,
                            maxScale: 4.0,
                            child: CachedNetworkImage(
                              imageUrl: fullImageUrl,
                              httpHeaders: {
                                'Accept': 'image/png,image/jpeg,image/*',
                                'User-Agent': 'ElegoApp/1.0',
                              },
                              placeholder:
                                  (context, url) => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                              errorWidget: (context, url, error) {
                                return _buildDirectImageWidget(url);
                              },
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
              ),
            );
          }
        },
        child: Hero(
          tag: 'image-$fullImageUrl',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: fullImageUrl,
              httpHeaders: {
                'Accept': 'image/png,image/jpeg,image/*',
                'User-Agent': 'ElegoApp/1.0',
              },
              placeholder:
                  (context, url) => Container(
                    color: Colors.grey[300],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              errorWidget: (context, url, error) {
                // Try direct image loading as fallback
                return _buildDirectImageWidget(url);
              },
              fit: BoxFit.cover,
              height: 200,
            ),
          ),
        ),
      );
    }

    // For non-thumbnails (e.g. full screen), return a different widget
    return CachedNetworkImage(
      imageUrl: fullImageUrl,
      httpHeaders: {
        'Accept': 'image/png,image/jpeg,image/*',
        'User-Agent': 'ElegoApp/1.0',
      },
      placeholder:
          (context, url) => Container(
            color: Colors.grey[300],
            child: const Center(child: CircularProgressIndicator()),
          ),
      errorWidget: (context, url, error) {
        return _buildDirectImageWidget(url);
      },
      fit: BoxFit.cover,
    );
  }

  // Helper method to extract a valid filename from a path
  String _getFileName(String path) {
    // Avoid using example.com paths
    if (path.contains('example.com')) {
      return 'image';
    }

    try {
      // Remove query parameters if present
      String cleanPath = path;
      if (cleanPath.contains('?')) {
        cleanPath = cleanPath.split('?').first;
      }

      // Get the filename from the path
      final segments = cleanPath.split('/');
      return segments.isNotEmpty ? segments.last : 'image';
    } catch (e) {
      print('Error extracting filename: $e');
      return 'image';
    }
  }

  Widget _buildHeader(String serviceType) {
    String status = _itemData!['state'] ?? 'unknown';
    Color statusColor;

    switch (status.toLowerCase()) {
      case 'pending':
        statusColor = Colors.orange;
        break;
      case 'completed':
        statusColor = Colors.green;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                status.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              _getServiceTypeIcon(serviceType),
              color: Theme.of(context).colorScheme.primary,
            ),
            const Spacer(),
            Text(
              'ID: ${_getIdString(_itemData!)}',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      ],
    );
  }

  String _getIdString(Map<String, dynamic> data) {
    // Handle different ID formats that might come from MongoDB
    try {
      if (data['_id'] == null) return '';

      String fullId;
      if (data['_id'] is String) {
        fullId = data['_id'];
      } else if (data['_id'] is Map) {
        // MongoDB ObjectId format: { "$oid": "67e70b65aef0e1f9399f59fa" }
        if (data['_id']['\$oid'] != null) {
          fullId = data['_id']['\$oid'];
        } else {
          fullId = data['_id'].toString();
        }
      } else {
        // Fallback: try to convert to string
        fullId = data['_id'].toString();
      }

      // Only show the last 6 characters of the ID
      if (fullId.length > 6) {
        return '...${fullId.substring(fullId.length - 6)}';
      } else {
        return fullId;
      }
    } catch (e) {
      print('Error parsing ID: $e');
      return '';
    }
  }

  Widget _buildDetailSection(String title, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
          ],
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Service Request'),
            content: const Text(
              'Are you sure you want to delete this service request?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _deleteItem();
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
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
      return Icons.format_paint;
    } else if (type.contains('curtain') || type.contains('blind')) {
      return Icons.blinds; // Standard blinds icon
    } else if (type.contains('network') || type.contains('wifi')) {
      return Icons.wifi;
    } else if (type.contains('clean')) {
      return Icons.cleaning_services;
    } else if (type.contains('electric')) {
      return Icons.electrical_services;
    } else if (type.contains('plumb')) {
      return Icons.plumbing;
    }

    // Default icon
    return Icons.handyman;
  }

  // Alternative direct image loading without caching
  Widget _buildDirectImageWidget(String imageUrl) {
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      headers: {
        'Accept': 'image/png,image/jpeg,image/*',
        'User-Agent': 'ElegoApp/1.0',
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value:
                loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey[300],
          child: const Center(
            child: Icon(Icons.broken_image, size: 40, color: Colors.red),
          ),
        );
      },
    );
  }
}
