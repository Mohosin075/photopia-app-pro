import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photopya/core/constants/app_typography.dart';
import 'package:photopya/core/constants/app_sizes.dart';
import 'package:photopya/features/provider/screen/provider_transaction_details_screen.dart';
import 'package:photopya/features/provider/screen/provider_request_payout_screen.dart';
import 'package:photopya/controller/provider/wallet_controller.dart';
import 'package:provider/provider.dart';
import 'package:photopya/core/localization/app_localizations.dart';

class ProviderWalletScreen extends StatefulWidget {
  const ProviderWalletScreen({super.key});

  @override
  State<ProviderWalletScreen> createState() => _ProviderWalletScreenState();
}

class _ProviderWalletScreenState extends State<ProviderWalletScreen> {
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final walletController = context.read<WalletController>();
      walletController.getMyWallet();
      walletController.getTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        title: Text(
          context.l10n.walletTitle,
          style: TextStyle(
            fontSize: AppTypography.h1,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface, size: 24.sp),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final walletController = context.read<WalletController>();
          await walletController.getMyWallet();
          await walletController.getTransactions();
        },
        color: Theme.of(context).colorScheme.onSurface,
        backgroundColor: Theme.of(context).colorScheme.surface,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Column(
            children: [
              // Balance Card
              _buildBalanceCard(context),
              SizedBox(height: 24.h),

              // Stats Row
              Consumer<WalletController>(
                builder: (context, controller, child) {
                  final thisMonth = controller.walletData?.thisMonthEarnings;
                  final lastMonth = controller.walletData?.lastMonthEarnings;

                  return Row(
                    children: [
                      Expanded(
                        child: _buildStatsCard(
                          title: context.l10n.thisMonth,
                          amount: '€${thisMonth?.amount?.toStringAsFixed(0) ?? '0'}',
                          growth:
                              context.l10n.vsLastMonth(thisMonth?.percentageChange?.toDouble() ?? 0),
                          isPositive:
                              (thisMonth?.percentageChange?.toDouble() ?? 0) >=
                              0,
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: _buildStatsCard(
                          title: context.l10n.lastMonth,
                          amount: '€${lastMonth?.amount?.toStringAsFixed(0) ?? '0'}',
                          growth:
                              context.l10n.vsLastMonth(lastMonth?.percentageChange?.toDouble() ?? 0),
                          isPositive:
                              (lastMonth?.percentageChange?.toDouble() ?? 0) >=
                              0,
                        ),
                      ),
                    ],
                  );
                },
              ),
              SizedBox(height: 24.h),

              // Tabs / Filter
              _buildFilterTabs(),
              SizedBox(height: 16.h),

              // Transactions List
              Consumer<WalletController>(
                builder: (context, walletController, child) {
                  if (walletController.isLoading && walletController.transactions.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 32.h),
                        child: const CircularProgressIndicator(),
                      ),
                    );
                  }

                  // Filter transactions based on selection
                  final filtered = walletController.transactions.where((tx) {
                    final status = tx['status']?.toString().toLowerCase() ?? '';
                    final isBooking = tx['type'] == 'booking';
                    
                    if (_selectedTab == 1) {
                      // Received (Completed bookings / earnings)
                      return isBooking && status == 'completed';
                    } else if (_selectedTab == 2) {
                      // Upcoming (Pending/Confirmed bookings)
                      return isBooking && (status == 'pending' || status == 'confirmed');
                    }
                    // All Transactions
                    return true;
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40.h),
                        child: Text(
                          'No transactions found',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) => SizedBox(height: 16.h),
                    itemBuilder: (context, index) {
                      final tx = filtered[index];
                      final isWithdrawal = tx['type'] == 'withdrawal';
                      final status = tx['status']?.toString().toLowerCase() ?? '';

                      // Map status color
                      Color statusColor = Colors.orange;
                      if (status == 'completed' || status == 'succeeded' || status == 'confirmed') {
                        statusColor = isWithdrawal ? Colors.green : Colors.blue;
                      } else if (status == 'failed' || status == 'cancelled') {
                        statusColor = Colors.red;
                      }

                      // Localized status text
                      String statusText = tx['status'] ?? '';
                      if (status == 'completed' || status == 'succeeded') {
                        statusText = isWithdrawal ? context.l10n.statusPaidOut : context.l10n.statusCompleted;
                      } else if (status == 'pending') {
                        statusText = context.l10n.filterUpcoming;
                      }

                      final dateRaw = tx['date'] ?? '';
                      final date = dateRaw.contains('T') ? dateRaw.split('T')[0] : dateRaw;

                      return _buildTransactionItem(
                        context,
                        title: tx['title'] ?? '',
                        name: tx['name'] ?? '',
                        date: date,
                        amount: tx['amount'] ?? 0.0,
                        isWithdrawal: isWithdrawal,
                        status: statusText,
                        statusColor: statusColor,
                        transaction: tx,
                      );
                    },
                  );
                },
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context) {
    return Consumer<WalletController>(
      builder: (context, controller, child) {
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E), // Dark card background
            borderRadius: BorderRadius.circular(24.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.totalBalance,
                style: TextStyle(
                  fontSize: AppTypography.bodyMedium,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                '€${controller.totalBalance.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 32.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Outfit',
                ),
              ),
              SizedBox(height: 24.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.balanceAvailable,
                        style: TextStyle(
                          fontSize: AppTypography.bodySmall,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '€${controller.balance.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: AppTypography.bodyLarge,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.balancePending,
                        style: TextStyle(
                          fontSize: AppTypography.bodySmall,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '€${controller.pendingBalance.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: AppTypography.bodyLarge,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                height: AppSizes.fieldHeight,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProviderRequestPayoutScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    context.l10n.requestPayout,
                    style: TextStyle(
                      fontSize: AppTypography.bodyLarge,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsCard({
    required String title,
    required String amount,
    required String growth,
    required bool isPositive,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isPositive ? Icons.trending_up : Icons.trending_down,
                size: 16.sp,
                color: isPositive ? Colors.green : Colors.red,
              ),
              SizedBox(width: 4.w),
              Text(
                title,
                style: TextStyle(
                  fontSize: AppTypography.bodySmall,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            amount,
            style: TextStyle(
              fontSize: AppTypography.h1,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            growth,
            style: TextStyle(
              fontSize: 10.sp,
              color: isPositive ? Colors.green : Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(context.l10n.allTransactions, 0),
          SizedBox(width: 12.w),
          _buildFilterChip(context.l10n.filterReceived, 1),
          SizedBox(width: 12.w),
          _buildFilterChip(context.l10n.filterUpcoming, 2),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: AppTypography.bodyMedium,
            color: isSelected ? Theme.of(context).colorScheme.surface : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionItem(
    BuildContext context, {
    required String title,
    required String name,
    required String date,
    required double amount,
    required bool isWithdrawal,
    required String status,
    required Color statusColor,
    required dynamic transaction,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProviderTransactionDetailsScreen(transaction: transaction),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: AppTypography.bodyLarge,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: AppTypography.bodySmall,
                          color: Colors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 12.sp,
                            color: Colors.grey,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            date,
                            style: TextStyle(
                              fontSize: AppTypography.bodySmall,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${isWithdrawal ? "-" : "+"}€${amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: AppTypography.bodyLarge,
                        fontWeight: FontWeight.bold,
                        color: isWithdrawal ? Colors.red : Colors.green,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 14.sp,
                            color: statusColor,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            status,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProviderTransactionDetailsScreen(transaction: transaction),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                    child: Text(
                      context.l10n.viewDetails,
                      style: TextStyle(
                        fontSize: AppTypography.bodyMedium,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
                if (!isWithdrawal) ...[
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Action for Invoice
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.onSurface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.download, size: 16.sp, color: Theme.of(context).colorScheme.surface),
                          SizedBox(width: 8.w),
                          Text(
                            context.l10n.invoiceBtn,
                            style: TextStyle(
                              fontSize: AppTypography.bodyMedium,
                              color: Theme.of(context).colorScheme.surface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
