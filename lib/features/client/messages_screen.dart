import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photopya/controller/client/chat_controller.dart';
import 'package:photopya/data/models/chat_response_model.dart';
import 'package:photopya/features/client/widgets/message_list_item.dart';
import 'package:photopya/features/client/widgets/shimmer_skeletons.dart';
import 'package:photopya/features/client/chat_screen.dart';
import 'package:photopya/controller/auth_controller.dart';
import 'package:provider/provider.dart';
import 'package:photopya/core/localization/app_localizations.dart';
import 'package:photopya/core/widgets/app_refresher.dart';
import 'package:photopya/core/utils/app_transitions.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (AuthController.isLoggedIn) {
        context.read<ChatController>().getChats();
      }
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
                builder: (context, chatController, child) {
                  if (chatController.isLoading) {
                    return _buildShimmerList();
                  }

                  if (chatController.chats.isEmpty) {
                    return _buildEmptyState();
                  }

                  return RefreshIndicator(
                    onRefresh: () async => await chatController.getChats(),
                    color: Theme.of(context).colorScheme.primary,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    child: _buildConversationList(chatController.chats),
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
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: 0.6.sh,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(32.r),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).dividerColor.withOpacity(0.05),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 64.sp,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              context.l10n.noMessagesYet,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 12.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40.w),
              child: Text(
                context.l10n.noMessagesDesc,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
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
        height: 44.h.clamp(40, 48),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(15).r,
          border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          textAlignVertical: TextAlignVertical.center,
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
              padding: EdgeInsets.only(left: 12.w, right: 8.w),
              child: Icon(
                Icons.search_rounded,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                size: 22.sp,
              ),
            ),
            prefixIconConstraints: BoxConstraints(
              minWidth: 35.w,
              minHeight: 44.h.clamp(40, 48),
            ),
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }

  Widget _buildConversationList(List<ChatRoom> chats) {
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
              AppTransitions.createPremiumRoute(
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
