import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photopia/features/client/widgets/message_list_item.dart';
import 'package:photopia/features/client/widgets/shimmer_skeletons.dart';
import 'package:photopia/features/client/chat_screen.dart';
import 'package:provider/provider.dart';
import 'package:photopia/controller/client/chat_controller.dart';
import 'package:photopia/controller/auth_controller.dart';
import 'package:photopia/core/widgets/app_refresher.dart';
import 'package:photopia/core/localization/app_localizations.dart';

class ProviderMessageScreen extends StatefulWidget {
  const ProviderMessageScreen({super.key});

  @override
  State<ProviderMessageScreen> createState() => _ProviderMessageScreenState();
}

class _ProviderMessageScreenState extends State<ProviderMessageScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatController>().getChats();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            Expanded(
              child: Consumer<ChatController>(
                builder: (context, controller, child) {
                  if (controller.isLoading && controller.chats.isEmpty) {
                    return _buildShimmerList();
                  }

                  if (controller.errorMessage.isNotEmpty && controller.chats.isEmpty) {
                    return Center(child: Text(controller.errorMessage));
                  }

                  if (controller.chats.isEmpty) {
                    return _buildEmptyState();
                  }

                  return AppRefresher(
                    onRefresh: () async => controller.getChats(),
                    color: Theme.of(context).colorScheme.primary,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    child: _buildConversationList(controller),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.message_outlined, size: 64.sp, color: Theme.of(context).dividerColor.withOpacity(0.1)),
          SizedBox(height: 16.h),
          Text(
            context.l10n.noMessagesYet,
            style: TextStyle(
              fontSize: 16.sp,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 15.h, 20.w, 10.h),
      child: Row(
        children: [
          Image.asset(
            'assets/images/message_icon.png',
            width: 28.sp.clamp(24, 32),
            height: 28.sp.clamp(24, 32),
            color: Theme.of(context).colorScheme.onSurface,
          ),
          SizedBox(width: 12.w),
          Text(
            context.l10n.navMessages,
            style: TextStyle(
              fontSize: 20.sp.clamp(20, 22),
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      child: Container(
        height: 48.h,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.3 : 0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) {
            context.read<ChatController>().searchChats(value);
          },
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 14.sp,
          ),
          decoration: InputDecoration(
            hintText: context.l10n.searchConversations,
            hintStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              fontSize: 14.sp,
            ),
            prefixIcon: Padding(
              padding: EdgeInsets.only(left: 15.w, right: 10.w),
              child: Icon(
                Icons.search_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 22.sp,
              ),
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 12.h),
          ),
        ),
      ),
    );
  }

  Widget _buildConversationList(ChatController controller) {
    final chats = controller.chats;
    final currentUserId = AuthController.userId;

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      itemCount: chats.length,
      itemBuilder: (context, index) {
        final chatRoom = chats[index];
        final conversation = chatRoom.toConversation(currentUserId);

        return MessageListItem(
          conversation: conversation,
          onTap: () {
            Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute(
                builder: (context) =>
                    ChatScreen(conversation: conversation),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 8,
      itemBuilder: (context, index) => const MessageListItemSkeleton(),
    );
  }
}
