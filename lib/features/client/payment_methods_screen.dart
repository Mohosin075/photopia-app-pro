import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photopya/controller/client/payment_controller.dart';
import 'package:photopya/core/widgets/custom_snacbar.dart';
import 'package:photopya/data/models/payment_method_model.dart';
import 'package:provider/provider.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PaymentController>().fetchPaymentMethods();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Payment Methods'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: Consumer<PaymentController>(
        builder: (context, controller, child) {
          if (controller.isLoading && controller.paymentMethods.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.paymentMethods.isEmpty) {
            return _buildEmptyState(controller);
          }

          return ListView.separated(
            padding: EdgeInsets.all(16.w),
            itemCount: controller.paymentMethods.length + 1,
            separatorBuilder: (context, index) => SizedBox(height: 12.h),
            itemBuilder: (context, index) {
              if (index == controller.paymentMethods.length) {
                return _buildAddButton(controller);
              }
              return _buildPaymentMethodCard(
                controller.paymentMethods[index],
                controller,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(PaymentController controller) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.credit_card,
              size: 80.sp,
              color: Colors.grey.withOpacity(0.3),
            ),
            SizedBox(height: 24.h),
            Text(
              'No Payment Methods',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.h),
            Text(
              'Add a card to make your checkout faster and easier.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 32.h),
            _buildAddButton(controller),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton(PaymentController controller) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ElevatedButton.icon(
      onPressed: () => _addNewCard(controller),
      icon: Icon(
        Icons.add,
        color: isDark ? Colors.black : Colors.white,
      ),
      label: Text(
        'Add New Card',
        style: TextStyle(
          color: isDark ? Colors.black : Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: ElevatedButton.styleFrom(
        minimumSize: Size(double.infinity, 52.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        backgroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
      ),
    );
  }

  Widget _buildPaymentMethodCard(
    PaymentMethodModel method,
    PaymentController controller,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isVisa = method.brand.toLowerCase() == 'visa';

    return Column(
      children: [
        Container(
          height: 200.h,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isVisa
                  ? [const Color(0xFF1A2980), const Color(0xFF26D0CE)]
                  : [const Color(0xFF434343), const Color(0xFF000000)],
            ),
            boxShadow: [
              BoxShadow(
                color: (isVisa ? Colors.blue : Colors.black).withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                right: -50.w,
                top: -50.h,
                child: CircleAvatar(
                  radius: 100.r,
                  backgroundColor: Colors.white.withOpacity(0.05),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Chip Icon
                        Container(
                          width: 45.w,
                          height: 35.h,
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(6.r),
                            gradient: LinearGradient(
                              colors: [Colors.amber[300]!, Colors.amber[700]!],
                            ),
                          ),
                        ),
                        // Brand Logo/Name
                        Text(
                          method.brand.toUpperCase(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),

                    // Card Number
                    Text(
                      '••••  ••••  ••••  ${method.last4}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22.sp,
                        letterSpacing: 4,
                        fontWeight: FontWeight.w600,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 2,
                            offset: const Offset(1, 1),
                          ),
                        ],
                      ),
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CARD HOLDER',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10.sp,
                                letterSpacing: 1,
                              ),
                            ),
                            Text(
                              'VALUED CUSTOMER',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'EXPIRES',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10.sp,
                                letterSpacing: 1,
                              ),
                            ),
                            Text(
                              '${method.expMonth.toString().padLeft(2, '0')}/${method.expYear.toString().substring(2)}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (method.isDefault)
                Positioned(
                  top: 15.h,
                  left: 15.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.greenAccent,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 12.sp,
                          color: Colors.black,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          'DEFAULT',
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (!method.isDefault)
              TextButton.icon(
                onPressed: () => _setDefault(method.id, controller),
                icon: Icon(Icons.star_outline, size: 18.sp),
                label: const Text('Set Default'),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                ),
              ),
            SizedBox(width: 12.w),
            TextButton.icon(
              onPressed: () => _deleteMethod(method.id, controller),
              icon: Icon(Icons.delete_outline, size: 18.sp),
              label: const Text('Remove Card'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.redAccent,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _getBrandIcon(String brand) {
    IconData iconData = Icons.credit_card;
    Color color = Colors.grey;

    switch (brand.toLowerCase()) {
      case 'visa':
        iconData = Icons.credit_card;
        color = Colors.blue[900]!;
        break;
      case 'mastercard':
        iconData = Icons.credit_card;
        color = Colors.orange;
        break;
    }

    return Container(
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Icon(iconData, color: color),
    );
  }

  Future<void> _addNewCard(PaymentController controller) async {
    final success = await controller.addNewPaymentMethod();
    if (success) {
      if (mounted) {
        CustomSnackBar.show(
          context: context,
          message: 'Card added successfully',
        );
      }
    } else {
      if (mounted) {
        CustomSnackBar.show(
          context: context,
          message: controller.errorMessage ?? 'Failed to add card',
          isError: true,
        );
      }
    }
  }

  Future<void> _setDefault(String id, PaymentController controller) async {
    final success = await controller.setDefaultMethod(id);
    if (!success && mounted) {
      CustomSnackBar.show(
        context: context,
        message: controller.errorMessage ?? 'Failed to set default',
        isError: true,
      );
    }
  }

  Future<void> _deleteMethod(String id, PaymentController controller) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Card'),
        content: const Text(
          'Are you sure you want to delete this payment method?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await controller.deleteMethod(id);
      if (!success && mounted) {
        CustomSnackBar.show(
          context: context,
          message: controller.errorMessage ?? 'Failed to delete card',
          isError: true,
        );
      }
    }
  }
}
