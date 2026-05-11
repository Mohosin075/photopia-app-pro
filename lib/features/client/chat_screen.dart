import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photopia/controller/client/chat_controller.dart';
import 'package:photopia/core/widgets/custom_network_image.dart';
import 'package:photopia/core/widgets/full_screen_image_viewer.dart';
import 'package:photopia/data/models/conversation_model.dart';
import 'package:photopia/data/models/chat_message_model.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photopia/features/client/media_preview_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:photopia/core/widgets/document_viewer_screen.dart';
import 'package:photopia/features/client/provider_profile_screen.dart';
import 'package:photopia/features/client/view_profile_screen.dart';
import 'package:photopia/controller/auth_controller.dart';

class ChatScreen extends StatefulWidget {
  final Conversation conversation;

  const ChatScreen({super.key, required this.conversation});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late String _currentChatId;

  @override
  void initState() {
    super.initState();
    _currentChatId = widget.conversation.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_currentChatId.isNotEmpty) {
        context.read<ChatController>().getMessages(
          _currentChatId, 
          receiverId: widget.conversation.receiverId
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickMedia(ImageSource source, bool isVideo) async {
    final ImagePicker picker = ImagePicker();
    XFile? file;
    
    if (isVideo) {
      file = await picker.pickVideo(source: source);
    } else {
      file = await picker.pickImage(source: source, imageQuality: 70);
    }

    if (file != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MediaPreviewScreen(
            filePath: file!.path,
            isVideo: isVideo,
            chatId: _currentChatId,
            receiverId: widget.conversation.receiverId,
          ),
        ),
      );
    }
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );

    if (result != null && result.files.single.path != null) {
      final String path = result.files.single.path!;
      
      // Directly send document or show preview? 
      // For now, let's just send it via the controller's media method
      if (mounted) {
        context.read<ChatController>().sendMediaMessage(
          _currentChatId, 
          path, 
          receiverId: widget.conversation.receiverId,
        );
      }
    }
  }

  Future<void> _openFile(String? url, String? localPath, {String? fileName}) async {
    final pathOrUrl = localPath ?? url;
    if (pathOrUrl == null || pathOrUrl.isEmpty) return;

    if (pathOrUrl.toLowerCase().endsWith('.pdf')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DocumentViewerScreen(
            urlOrPath: pathOrUrl,
            title: fileName ?? 'Document',
          ),
        ),
      );
      return;
    }

    if (localPath != null && await File(localPath).exists()) {
      await OpenFilex.open(localPath);
      return;
    }
    
    if (url != null && url.isNotEmpty) {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  void _showAttachmentMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20).r)),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 20.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentOption(
                  icon: Icons.image,
                  label: 'Image',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.pop(context);
                    _pickMedia(ImageSource.gallery, false);
                  },
                ),
                _buildAttachmentOption(
                  icon: Icons.videocam,
                  label: 'Video',
                  color: Colors.red,
                  onTap: () {
                    Navigator.pop(context);
                    _pickMedia(ImageSource.gallery, true);
                  },
                ),
                _buildAttachmentOption(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  color: Colors.green,
                  onTap: () {
                    Navigator.pop(context);
                    _pickMedia(ImageSource.camera, false);
                  },
                ),
                _buildAttachmentOption(
                  icon: Icons.insert_drive_file,
                  label: 'Document',
                  color: Colors.orange,
                  onTap: () {
                    Navigator.pop(context);
                    _pickDocument();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(15.r),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 30.sp),
          ),
          SizedBox(height: 8.h),
          Text(label, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Future<void> _handleSendMessage() async {
    final String text = _messageController.text.trim();
    if (text.isEmpty) return;

    final controller = context.read<ChatController>();
    _messageController.clear();

    if (_currentChatId.isEmpty && widget.conversation.isTemporary) {
      final String? newChatId = await controller.createChatAndSendMessage(
        widget.conversation.receiverId ?? '',
        text,
      );
      if (newChatId != null) {
        _currentChatId = newChatId;
      }
    } else {
      await controller.sendMessage(
        _currentChatId, 
        text, 
        receiverId: widget.conversation.receiverId
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body: Consumer<ChatController>(
        builder: (context, controller, child) {
          if (controller.isLoading && controller.messages.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              Expanded(
                child: controller.messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
                        itemCount: controller.messages.length,
                        itemBuilder: (context, index) {
                          final message = controller.messages[index];
                          return _buildMessageBubble(message);
                        },
                      ),
              ),
              _buildInputArea(controller.isLoading),
            ],
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      surfaceTintColor: Colors.transparent,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
        onPressed: () => Navigator.pop(context),
      ),
      title: InkWell(
        onTap: () {
          final activeRole = AuthController.activeRole;
          final receiverId = widget.conversation.receiverId;
          
          debugPrint("🚀 [CHAT] Header Clicked. Role: $activeRole, ReceiverId: $receiverId");

          if (receiverId == null || receiverId.isEmpty) {
            debugPrint("⚠️ [CHAT] Navigation aborted: receiverId is null or empty");
            return;
          }

          if (activeRole == 'client' || activeRole == 'user') {
            // Client viewing Provider
            debugPrint("🚀 [CHAT] Navigating to ProviderProfileScreen (Client View)");
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProviderProfileScreen(
                  provider: {
                    '_id': receiverId,
                    'id': receiverId,
                    'name': widget.conversation.name,
                    'avatar': widget.conversation.avatarUrl,
                  },
                ),
              ),
            );
          } else {
            // Provider viewing Client
            debugPrint("🚀 [CHAT] Provider viewing client: $receiverId");
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ViewProfileScreen(
                  userId: receiverId,
                ),
              ),
            );
          }
        },
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 5.h),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20.r,
                backgroundColor: Theme.of(context).colorScheme.surface,
                backgroundImage: widget.conversation.avatarUrl.isNotEmpty
                    ? (widget.conversation.avatarUrl.startsWith('assets/')
                        ? AssetImage(widget.conversation.avatarUrl) as ImageProvider
                        : NetworkImage(widget.conversation.avatarUrl))
                    : null,
                child: widget.conversation.avatarUrl.isEmpty
                    ? Icon(Icons.person, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4), size: 24.sp)
                    : null,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.conversation.name,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 15.sp, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      widget.conversation.isOnline ? 'Online' : 'Offline',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 11.sp),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64.sp, color: Theme.of(context).dividerColor.withOpacity(0.1)),
          SizedBox(height: 16.h),
          Text('No messages yet', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4), fontSize: 16.sp)),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final bool isLeft = !message.isMe;

    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: Column(
        crossAxisAlignment: isLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          Container(
            constraints: BoxConstraints(maxWidth: 0.75.sw),
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: message.isMe ? Theme.of(context).colorScheme.primary : (Theme.of(context).brightness == Brightness.dark ? Theme.of(context).dividerColor.withOpacity(0.1) : const Color(0xFFF1F3F5)),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16).r,
                topRight: Radius.circular(16).r,
                bottomLeft: Radius.circular(isLeft ? 0 : 16).r,
                bottomRight: Radius.circular(isLeft ? 16 : 0).r,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMediaContent(message),
                if (message.type == ChatMessageType.file) _buildFileContent(message),
                if (message.text.trim().isNotEmpty && message.text != "[Empty Message]")
                  Text(
                    message.text.trim(),
                    style: TextStyle(color: message.isMe ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface, fontSize: 14.sp),
                  ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 4.h),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(DateFormat('hh:mm a').format(message.time), style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3), fontSize: 10.sp)),
                if (message.isMe) ...[
                  SizedBox(width: 4.w),
                  _buildStatusIcon(message.status),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return SizedBox(width: 10.r, height: 10.r, child: const CircularProgressIndicator(strokeWidth: 1.5));
      case MessageStatus.sent:
      case MessageStatus.delivered:
      case MessageStatus.read:
        return Icon(Icons.check_circle, size: 12.r, color: Colors.blue);
      case MessageStatus.error:
        return Icon(Icons.error_outline, size: 14.r, color: Colors.red);
    }
  }

  Widget _buildMediaContent(ChatMessage message) {
    if (message.fileUrl == null) return const SizedBox.shrink();
    if (message.type == ChatMessageType.image) {
      return Padding(
        padding: EdgeInsets.only(bottom: 8.h),
        child: _buildImageContent(message),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildImageContent(ChatMessage message) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FullScreenImageViewer(
              imageUrl: message.fileUrl,
              tag: 'chat_img_${message.id}',
            ),
          ),
        );
      },
      child: Hero(
        tag: 'chat_img_${message.id}',
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12).r,
          child: message.isLocal
              ? Image.file(
                  File(message.fileUrl!),
                  height: 200.h,
                  width: 150.w,
                  fit: BoxFit.cover,
                )
              : CustomNetworkImage(
                  imageUrl: message.fileUrl!,
                  height: 200.h,
                  width: 150.w,
                  fit: BoxFit.cover,
                ),
        ),
      ),
    );
  }

  Widget _buildFileContent(ChatMessage message) {
    return GestureDetector(
      onTap: () => _openFile(message.fileUrl, message.isLocal ? message.fileUrl : null, fileName: message.fileName),
      child: Container(
        padding: EdgeInsets.all(10.r),
        margin: EdgeInsets.only(bottom: 8.h),
        decoration: BoxDecoration(color: message.isMe ? Colors.white.withOpacity(0.1) : (Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.white), borderRadius: BorderRadius.circular(12).r),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.attach_file, color: message.isMe ? Colors.white : Theme.of(context).colorScheme.onSurface, size: 20.sp),
            SizedBox(width: 8.w),
            Flexible(child: Text(message.fileName ?? 'File', style: TextStyle(color: message.isMe ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface, fontSize: 13.sp), overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(bool isSending) {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 30.h),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, border: Border(top: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1)))),
      child: Row(
        children: [
          IconButton(icon: Icon(Icons.attach_file, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), size: 24.sp), onPressed: _showAttachmentMenu),
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(24).r, border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1))),
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(hintText: 'Type a message...', border: InputBorder.none, hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
                onSubmitted: (_) => _handleSendMessage(),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          GestureDetector(
            onTap: _handleSendMessage,
            child: Container(
              width: 48.r,
              height: 48.r,
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, shape: BoxShape.circle),
              child: Icon(Icons.send_rounded, color: Theme.of(context).colorScheme.onPrimary, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}
