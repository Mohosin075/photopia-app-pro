import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:photopya/controller/provider/provider_orders_controller.dart';
import 'package:photopya/core/widgets/custom_snacbar.dart';
import 'package:photopya/core/network/Api_service/network_caller.dart';
import 'package:photopya/core/network/urls.dart';
import 'package:photopya/core/widgets/custom_network_image.dart';
import 'package:photopya/data/models/conversation_model.dart';
import 'package:photopya/data/models/chat_message_model.dart';
import 'package:photopya/features/client/chat_screen.dart';

class BookingDetailsScreen extends StatelessWidget {
  static const String name = "/booking-details";
  final Map<String, dynamic> booking;

  const BookingDetailsScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Booking Details',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 18.sp.clamp(18, 20),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline, color: Theme.of(context).colorScheme.onSurface),
            onPressed: () {},
          ),
        ],
      ),
      body: FutureBuilder(
        future: NetworkCaller.getRequest(url: Urls.getSingleBooking(booking['_id'] ?? booking['id'] ?? '')),
        builder: (context, snapshot) {
          Map<String, dynamic> currentBooking = booking;

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData) {
            final response = snapshot.data!;
            if (response.isSuccess && response.body != null) {
              final rawData = response.body!['data'];
              currentBooking = (rawData is Map && rawData.containsKey('booking')) 
                  ? rawData['booking'] 
                  : rawData ?? booking;
            }
          }

          final client = currentBooking['clientId'] is Map ? currentBooking['clientId'] : <String, dynamic>{};
          final service = currentBooking['serviceId'] is Map ? currentBooking['serviceId'] : <String, dynamic>{};
          final location = currentBooking['eventLocation'] is Map ? currentBooking['eventLocation'] : <String, dynamic>{};

          return SingleChildScrollView(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildClientInfo(context, client, currentBooking),
                SizedBox(height: 20.h),
                _buildServiceDetails(context, service, location, currentBooking),
                SizedBox(height: 20.h),
                _buildSpecialNotes(context, location['notes']?.toString() ?? 'No special notes provided'),
                SizedBox(height: 30.h),
                _buildActionButtons(context, currentBooking['status']?.toString() ?? 'pending', currentBooking),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildClientInfo(BuildContext context, Map<String, dynamic> client, Map<String, dynamic> currentBooking) {
    final status = currentBooking['status']?.toString() ?? 'pending';
    return Container(
      padding: EdgeInsets.all(15.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Client Information',
                    style: TextStyle(
                      fontSize: 16.sp.clamp(14, 18),
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  if (currentBooking['depositPercentage'] != null) ...[
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Icon(Icons.check_circle_outline, size: 14.sp, color: Colors.green),
                        SizedBox(width: 4.w),
                        Text(
                          'Deposit Paid: ${((currentBooking['depositPercentage'] ?? 1.0) * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: status.toLowerCase() == 'confirmed' 
                    ? (Theme.of(context).brightness == Brightness.dark ? Colors.green.withOpacity(0.2) : const Color(0xFFE8F5E9)) 
                    : (Theme.of(context).brightness == Brightness.dark ? Colors.orange.withOpacity(0.2) : const Color(0xFFFFF3E0)),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  status[0].toUpperCase() + status.substring(1),
                  style: TextStyle(
                    fontSize: 10.sp.clamp(9, 11),
                    color: status.toLowerCase() == 'confirmed' 
                      ? (Theme.of(context).brightness == Brightness.dark ? Colors.green[300] : const Color(0xFF2E7D32)) 
                      : (Theme.of(context).brightness == Brightness.dark ? Colors.orange[300] : const Color(0xFFE65100)),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 15.h),
          Row(
            children: [
              CustomNetworkImage(
                imageUrl: client['profile'] ?? client['profileImage'] ?? client['image'] ?? client['avatar'] ?? '',
                width: 70.r,
                height: 70.r,
                shape: BoxShape.circle,
                fit: BoxFit.cover,
                placeholder: Icon(Icons.person, size: 35.r, color: Colors.grey),
              ),
              SizedBox(width: 15.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client['name'] ?? currentBooking['clientName'] ?? 'Unknown Client',
                      style: TextStyle(
                        fontSize: 17.sp.clamp(16, 18),
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Icon(Icons.email_outlined, size: 14.sp, color: Colors.grey[600]),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            client['email'] ?? currentBooking['clientEmail'] ?? 'No email available',
                            style: TextStyle(
                              fontSize: 13.sp.clamp(12, 14),
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceDetails(BuildContext context, Map<String, dynamic> service, Map<String, dynamic> location, Map<String, dynamic> currentBooking) {
    // 1. Move logic to the START of the function
    final String displayPrice = () {
      String price = '0';
      final pricingDetails = currentBooking['pricingDetails'];
      final String? packageName = currentBooking['packageName'];
      
      // Priority 1: Subtotal (What the provider sees)
      if (pricingDetails != null && pricingDetails['subtotal'] != null && pricingDetails['subtotal'] != 0) {
        price = pricingDetails['subtotal'].toString();
      } 
      // Priority 2: Base Rate
      else if (pricingDetails != null && pricingDetails['baseRate'] != null && pricingDetails['baseRate'] != 0) {
        price = pricingDetails['baseRate'].toString();
      } else if (packageName != null && service['pricingModel'] != null && service['pricingModel']['packages'] != null) {
        final List packages = service['pricingModel']['packages'];
        final package = packages.firstWhere((p) => p['name'] == packageName, orElse: () => null);
        if (package != null) {
          price = package['price']?.toString() ?? service['price']?.toString() ?? '0';
        }
      }
      
      if (price == '0' || price == '0.0') {
        if (currentBooking['totalAmount'] != null && currentBooking['totalAmount'] != 0) {
          price = currentBooking['totalAmount'].toString();
        } else {
          price = service['price']?.toString() ?? '0';
        }
      }
      return price;
    }();

    double dPrice = double.tryParse(displayPrice) ?? 0;
    double dDepositPercent = double.tryParse(currentBooking['depositPercentage']?.toString() ?? '1.0') ?? 1.0;
    double displayPaid = dPrice * dDepositPercent;
    double displayRemaining = dPrice - displayPaid;

    return Container(
      padding: EdgeInsets.all(15.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Service Details',
            style: TextStyle(
              fontSize: 16.sp.clamp(14, 18),
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 20.h),
          _buildDetailRow(context, 'Service', service['title'] ?? 'Generic Service'),
          _buildDetailRow(context, 'Date', currentBooking['bookingDate']?.toString().split('T')[0] ?? 'N/A'),
          _buildDetailRow(context, 'Time', '${currentBooking['startTime'] ?? 'N/A'} - ${currentBooking['endTime'] ?? ''}'),
          _buildDetailRow(context, 'Location', location['address'] ?? 'Location N/A'),
          SizedBox(height: 10.h),
          const Divider(),
          SizedBox(height: 10.h),
          SizedBox(height: 10.h),
          const Divider(),
          SizedBox(height: 10.h),
          
          // Price Breakdown for Provider
          Builder(
            builder: (context) {
              final pricing = currentBooking['pricingDetails'];
              double subtotal = 0;
              if (pricing != null && pricing['subtotal'] != null) {
                subtotal = double.tryParse(pricing['subtotal'].toString()) ?? 0;
              }
              
              double commission = 0;
              if (pricing != null && pricing['platformCommissionProvider'] != null) {
                commission = double.tryParse(pricing['platformCommissionProvider'].toString()) ?? 0;
              }
              
              double earnings = 0;
              if (pricing != null && pricing['providerEarnings'] != null) {
                earnings = double.tryParse(pricing['providerEarnings'].toString()) ?? (subtotal - commission);
              } else {
                earnings = subtotal - commission;
              }

              double displayPaid = double.tryParse(currentBooking['depositAmount']?.toString() ?? '0') ?? (subtotal * dDepositPercent);
              double displayRemaining = double.tryParse(currentBooking['balanceAmount']?.toString() ?? '0') ?? (subtotal - displayPaid);
              
              // Note: If displayRemaining is more than earnings, it means the client owes more than what provider gets (because of platform fee)
              // But for the provider, we show what they will actually receive.
              double providerRemaining = earnings - (currentBooking['isPaid'] == true ? earnings : 0); // Simplification

              return Column(
                children: [
                  _buildPaymentDetailRow(context, 'Booking Subtotal', '€${subtotal.toStringAsFixed(0)}'),
                  if (commission > 0)
                    _buildPaymentDetailRow(context, 'Platform Commission (5%)', '-€${commission.toStringAsFixed(0)}', color: Colors.redAccent),
                  const Divider(),
                  _buildPaymentDetailRow(
                    context, 
                    'Your Total Earnings', 
                    '€${earnings.toStringAsFixed(0)}', 
                    isBold: true,
                    color: Theme.of(context).colorScheme.primary
                  ),
                  SizedBox(height: 12.h),
                  _buildPaymentDetailRow(
                    context,
                    'Paid (Deposit)', 
                    '€${displayPaid.toStringAsFixed(0)}',
                    color: const Color(0xFF4CAF50),
                  ),
                  _buildPaymentDetailRow(
                    context,
                    'Client Remaining', 
                    '€${displayRemaining.toStringAsFixed(0)}',
                    color: Colors.grey[600],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentDetailRow(BuildContext context, String label, String value, {Color? color, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13.sp.clamp(12, 14),
            color: Colors.grey[600],
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp.clamp(13, 15),
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color ?? Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14.sp.clamp(13, 15),
              color: Colors.grey[500],
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14.sp.clamp(13, 15),
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialNotes(BuildContext context, String notes) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(15.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Special Notes',
            style: TextStyle(
              fontSize: 16.sp.clamp(14, 18),
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            notes.isEmpty ? 'No special notes provided' : notes,
            style: TextStyle(
              fontSize: 14.sp.clamp(13, 15),
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, String status, Map<String, dynamic> currentBooking) {
    final clientMap = currentBooking['clientId'] is Map ? currentBooking['clientId'] : <String, dynamic>{};
    
    // Support situations where clientId is populated or just a string reference
    String clientId = '';
    if (clientMap.isNotEmpty) {
      clientId = clientMap['_id']?.toString() ?? clientMap['id']?.toString() ?? '';
    } else if (currentBooking['clientId'] is String) {
      clientId = currentBooking['clientId'].toString();
    }
    // Also fallback to root fields if backend gives them there
    clientId = clientId.isEmpty ? (currentBooking['client'] ?? '') : clientId;

    final clientName = clientMap['name']?.toString() ?? currentBooking['clientName']?.toString() ?? 'Client';
    final clientAvatar = clientMap['profile'] ?? clientMap['profileImage'] ?? clientMap['image'] ?? clientMap['avatar'] ?? '';

    final isPending = status.toLowerCase() == 'pending';
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50.h,
          child: ElevatedButton(
            onPressed: () {
              if (clientId.isEmpty) {
                CustomSnackBar.show(
                  context: context,
                  message: 'Client information not available',
                  isError: true,
                );
                return;
              }
              final conversation = Conversation(
                id: '',
                name: clientName,
                lastMessage: '',
                avatarUrl: clientAvatar,
                lastMessageTime: DateTime.now(),
                unreadCount: 0,
                isOnline: false,
                status: MessageStatus.read,
                isTemporary: true,
                receiverId: clientId,
              );
              Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(
                  builder: (context) => ChatScreen(conversation: conversation),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              elevation: 0,
            ),
            child: Text(
              'Contact Client',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontSize: 15.sp.clamp(14, 16),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        if (isPending && (currentBooking['paymentStatus']?.toString().toLowerCase() == 'pending')) ...[
          SizedBox(height: 15.h),
          SizedBox(
            width: double.infinity,
            height: 50.h,
            child: OutlinedButton.icon(
              onPressed: () => _showModifyOfferDialog(context, currentBooking),
              icon: Icon(Icons.edit_note, size: 20.sp),
              label: Text(
                'Modify Offer',
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
                side: BorderSide(color: Theme.of(context).colorScheme.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ),
          SizedBox(height: 15.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTextActionButton(context, 'Decline', Icons.close, Colors.red, false, currentBooking),
              _buildTextActionButton(context, 'Accept', Icons.check, Theme.of(context).colorScheme.onSurface, true, currentBooking),
            ],
          ),
        ],
      ],
    );
  }

  void _showModifyOfferDialog(BuildContext context, Map<String, dynamic> currentBooking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ModifyOfferSheet(booking: currentBooking),
    );
  }

  void _showConfirmationDialog({
    required BuildContext context,
    required bool isAccept,
    required String bookingId,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(15.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        isAccept ? 'Do you want to accept this?' : 'Do you want to decline this?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(dialogContext),
                      child: Icon(Icons.close, size: 24.sp, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8)),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE0E0E0)),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 25.h, horizontal: 20.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Yes Button
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final status = isAccept ? 'confirmed' : 'cancelled';
                          final controller = Provider.of<ProviderOrdersController>(context, listen: false);
                          
                          // Close dialog
                          Navigator.pop(dialogContext);
                          
                          final success = await controller.updateOrderStatus(bookingId, status);
                          
                          if (context.mounted) {
                            CustomSnackBar.show(
                              context: context,
                              message: success 
                                ? 'Order ${isAccept ? 'accepted' : 'declined'} successfully!' 
                                : 'Failed to update order status',
                              isError: !success,
                            );
                            if (success) {
                              Navigator.of(context).pop();
                            }
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.green.withOpacity(0.2) : const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check, color: const Color(0xFF2E7D32), size: 18.sp),
                              SizedBox(width: 8.w),
                              Text(
                                'Yes',
                                style: TextStyle(
                                  color: Theme.of(context).brightness == Brightness.dark ? Colors.green[300] : const Color(0xFF2E7D32),
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 15.w),
                    // No Button
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(dialogContext),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.red.withOpacity(0.2) : const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.close, color: const Color(0xFFC62828), size: 18.sp),
                              SizedBox(width: 8.w),
                              Text(
                                'No',
                                style: TextStyle(
                                  color: Theme.of(context).brightness == Brightness.dark ? Colors.red[300] : const Color(0xFFC62828),
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextActionButton(BuildContext context, String text, IconData icon, Color color, bool isAccept, Map<String, dynamic> currentBooking) {
    return GestureDetector(
      onTap: () {
        final bookingId = currentBooking['_id'] ?? currentBooking['id'] ?? '';
        if (bookingId.isEmpty) return;
        _showConfirmationDialog(
          context: context,
          isAccept: isAccept,
          bookingId: bookingId,
        );
      },
      child: Row(
        children: [
          Icon(icon, color: color),
          SizedBox(width: 8.w),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 16.sp.clamp(14, 18),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModifyOfferSheet extends StatefulWidget {
  final Map<String, dynamic> booking;
  const _ModifyOfferSheet({required this.booking});

  @override
  State<_ModifyOfferSheet> createState() => _ModifyOfferSheetState();
}

class _ModifyOfferSheetState extends State<_ModifyOfferSheet> {
  late TextEditingController _packageNameController;
  late TextEditingController _baseRateController;
  final List<Map<String, dynamic>> _customOptions = [];
  final List<TextEditingController> _nameControllers = [];
  final List<TextEditingController> _priceControllers = [];

  @override
  void initState() {
    super.initState();
    final pricing = widget.booking['pricingDetails'] ?? {};
    _packageNameController = TextEditingController(text: widget.booking['packageName'] ?? '');
    _baseRateController = TextEditingController(text: (pricing['baseRate'] ?? 0).toString());
    
    if (widget.booking['customOptions'] != null) {
      for (var option in (widget.booking['customOptions'] as List)) {
        _customOptions.add({'name': option['name']?.toString() ?? '', 'price': option['price'] ?? 0.0});
        _nameControllers.add(TextEditingController(text: option['name']?.toString() ?? ''));
        _priceControllers.add(TextEditingController(text: option['price']?.toString() ?? '0'));
      }
    }
  }

  @override
  void dispose() {
    _packageNameController.dispose();
    _baseRateController.dispose();
    for (var c in _nameControllers) {
      c.dispose();
    }
    for (var c in _priceControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    setState(() {
      _customOptions.add({'name': '', 'price': 0.0});
      _nameControllers.add(TextEditingController());
      _priceControllers.add(TextEditingController());
    });
  }

  void _removeOption(int index) {
    setState(() {
      _customOptions.removeAt(index);
      _nameControllers[index].dispose();
      _nameControllers.removeAt(index);
      _priceControllers[index].dispose();
      _priceControllers.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, MediaQuery.of(context).viewInsets.bottom + 20.h),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Modify Offer',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: Theme.of(context).colorScheme.onSurface),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            _buildLabel('Package Name'),
            TextField(
              controller: _packageNameController,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              decoration: _buildInputDecoration('Enter package name'),
            ),
            SizedBox(height: 15.h),
            _buildLabel('Base Rate (€)'),
            TextField(
              controller: _baseRateController,
              keyboardType: TextInputType.number,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              decoration: _buildInputDecoration('Enter base rate'),
            ),
            SizedBox(height: 25.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildLabel('Custom Options'),
                TextButton.icon(
                  onPressed: _addOption,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Option'),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            ...List.generate(_customOptions.length, (index) {
              return Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _nameControllers[index],
                        onChanged: (val) => _customOptions[index]['name'] = val,
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 13.sp),
                        decoration: _buildInputDecoration('Option name'),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: TextField(
                        controller: _priceControllers[index],
                        keyboardType: TextInputType.number,
                        onChanged: (val) => _customOptions[index]['price'] = double.tryParse(val) ?? 0.0,
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 13.sp),
                        decoration: _buildInputDecoration('Price'),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _removeOption(index),
                      icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                    ),
                  ],
                ),
              );
            }),
            SizedBox(height: 30.h),
            Consumer<ProviderOrdersController>(
              builder: (context, controller, child) {
                return SizedBox(
                  width: double.infinity,
                  height: 50.h,
                  child: ElevatedButton(
                    onPressed: controller.isUpdating ? null : () async {
                      // Filter out custom options with empty names before sending
                      final filteredOptions = _customOptions
                          .where((opt) => opt['name'] != null && opt['name'].toString().trim().isNotEmpty)
                          .toList();

                      final body = {
                        'packageName': _packageNameController.text,
                        'baseRate': double.tryParse(_baseRateController.text) ?? 0.0,
                        'customOptions': filteredOptions,
                      };
                      
                      final success = await controller.modifyOffer(
                        widget.booking['_id'] ?? widget.booking['id'],
                        body,
                      );
                      
                      if (mounted) {
                        if (success) {
                          Navigator.pop(context); // Close sheet
                          Navigator.pop(context); // Go back to orders list
                          CustomSnackBar.show(
                            context: context,
                            message: 'Offer modified successfully!',
                          );
                        } else {
                          CustomSnackBar.show(
                            context: context,
                            message: controller.errorMessage,
                            isError: true,
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                      elevation: 0,
                    ),
                    child: controller.isUpdating 
                      ? SizedBox(
                          height: 20.h,
                          width: 20.h,
                          child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'Update Offer',
                          style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.bold),
                        ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13.sp),
      contentPadding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 12.h),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.r),
        borderSide: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.r),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
      ),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surface,
    );
  }
}
