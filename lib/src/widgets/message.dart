import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/src/widgets/audio_message.dart';
import 'package:intl/intl.dart';

import 'chat.dart';
import 'file_message.dart';
import 'image_message.dart';
import 'inherited_chat_theme.dart';
import 'inherited_user.dart';
import 'text_message.dart';

/// Base widget for all message types in the chat. Renders bubbles around
/// messages, delivery time and status. Sets maximum width for a message for
/// a nice look on larger screens.
class Message extends StatelessWidget {
  /// Creates a particular message from any message type
  const Message({
    Key? key,
    this.dateLocale,
    required this.message,
    required this.messageWidth,
    this.onPreviewDataFetched,
    required this.previousMessageSameAuthor,
    required this.shouldRenderTime,
    required this.nextMessageDifferentAuthor,
    this.avatarData,
    required this.previousMessageDifferentAuthor,
    this.messageContainerWrapperBuilder,
  }) : super(key: key);

  /// Locale will be passed to the `Intl` package. Make sure you initialized
  /// date formatting in your app before passing any locale here, otherwise
  /// an error will be thrown.
  final String? dateLocale;

  /// Any message type
  final types.Message message;

  /// Maximum message width
  final int messageWidth;

  /// See [TextMessage.onPreviewDataFetched]
  final void Function(types.TextMessage, types.PreviewData)? onPreviewDataFetched;

  /// Whether previous message was sent by the same person. Used for
  /// different spacing for sent and received messages.
  final bool previousMessageSameAuthor;

  /// Whether next message was sent by a different person. Used to
  /// show the name in that case.
  final bool nextMessageDifferentAuthor;

  /// Whether previous message was sent by a different person. Used to
  /// show the user icon in that case.
  final bool previousMessageDifferentAuthor;

  /// Whether delivery time should be rendered. It is not rendered for
  /// received messages and when sent messages have small difference in
  /// delivery time.
  final bool shouldRenderTime;

  /// An optional user icon and name that will only be shown if this is a message the
  /// current user received, not sent.
  final AvatarData? avatarData;

  /// If provided, allows you to wrap message widget with any other widget
  final Widget Function(types.Message, Widget)? messageContainerWrapperBuilder;

  Widget? get userName => avatarData?.userName;

  Widget? get userAvatar => avatarData?.userAvatar;

  Widget? get avatarPlaceHolder => avatarData?.avatarPlaceHolder;

  Widget _buildMessage() {
    switch (message.type) {
      case types.MessageType.file:
        final fileMessage = message as types.FileMessage;
        return FileMessage(
          message: fileMessage,
        );
      case types.MessageType.image:
        final imageMessage = message as types.ImageMessage;
        return ImageMessage(
          message: imageMessage,
          messageWidth: messageWidth,
        );
      case types.MessageType.audio:
        final audioMessage = message as types.AudioMessage;
        return AudioMessage(
          message: audioMessage,
          messageWidth: messageWidth,
        );
      case types.MessageType.text:
        final textMessage = message as types.TextMessage;
        return TextMessage(
          message: textMessage,
          onPreviewDataFetched: onPreviewDataFetched,
        );
      default:
        return Container();
    }
  }

  Widget _buildStatus(BuildContext context) {
    switch (message.status) {
      case types.Status.delivered:
        return InheritedChatTheme.of(context).theme.deliveredIcon != null
            ? Image.asset(
                InheritedChatTheme.of(context).theme.deliveredIcon!,
                color: InheritedChatTheme.of(context).theme.primaryColor,
              )
            : Image.asset(
                'assets/icon-delivered.png',
                color: InheritedChatTheme.of(context).theme.primaryColor,
                package: 'flutter_chat_ui',
              );
      case types.Status.read:
        return InheritedChatTheme.of(context).theme.readIcon != null
            ? Image.asset(
                InheritedChatTheme.of(context).theme.readIcon!,
                color: InheritedChatTheme.of(context).theme.primaryColor,
              )
            : Image.asset(
                'assets/icon-read.png',
                color: InheritedChatTheme.of(context).theme.primaryColor,
                package: 'flutter_chat_ui',
              );
      case types.Status.sending:
        return Padding(
          padding: const EdgeInsets.only(left: 2, top: 3),
          child: Icon(
            Icons.watch_later_outlined,
            color: InheritedChatTheme.of(context).theme.primaryColor,
            size: 12,
          ),
        );
      default:
        return Container();
    }
  }

  Widget _buildTime(bool currentUserIsAuthor, BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          DateFormat.jm(dateLocale).format(
            DateTime.fromMillisecondsSinceEpoch(
              message.timestamp!,
            ),
          ),
          style: InheritedChatTheme.of(context).theme.caption.copyWith(
                color: InheritedChatTheme.of(context).theme.captionColor,
              ),
        ),
        if (currentUserIsAuthor) _buildStatus(context)
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final _user = InheritedUser.of(context).user;
    final _messageBorderRadius = InheritedChatTheme.of(context).theme.messageBorderRadius;
    final _borderRadius = BorderRadius.only(
      bottomLeft: Radius.circular(_user.id == message.authorId ? _messageBorderRadius : 0),
      bottomRight: Radius.circular(_user.id == message.authorId ? 0 : _messageBorderRadius),
      topLeft: Radius.circular(_messageBorderRadius),
      topRight: Radius.circular(_messageBorderRadius),
    );
    final _currentUserIsAuthor = _user.id == message.authorId;

    return Container(
      alignment: _user.id == message.authorId ? Alignment.centerRight : Alignment.centerLeft,
      margin: EdgeInsets.only(
        bottom: previousMessageSameAuthor ? 8 : 16,
        left: 12,
        right: 12,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: shouldRenderTime ? 25 : 0),
            child: _showAvatarOrPlaceholder(_user),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: messageWidth.toDouble(),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (messageContainerWrapperBuilder != null)
                  messageContainerWrapperBuilder!(
                      message, _buildMessageBubble(_borderRadius, _currentUserIsAuthor, context, _user))
                else
                  _buildMessageBubble(_borderRadius, _currentUserIsAuthor, context, _user),
                if (shouldRenderTime)
                  Container(
                    margin: const EdgeInsets.only(
                      top: 8,
                    ),
                    child: _buildTime(_currentUserIsAuthor, context),
                  )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Container _buildMessageBubble(
      BorderRadius _borderRadius, bool _currentUserIsAuthor, BuildContext context, types.User _user) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: _borderRadius,
        color: !_currentUserIsAuthor || message.type == types.MessageType.image
            ? InheritedChatTheme.of(context).theme.secondaryColor
            : InheritedChatTheme.of(context).theme.primaryColor,
      ),
      child: ClipRRect(
        borderRadius: _borderRadius,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_user.id != message.authorId && userName != null && nextMessageDifferentAuthor) userName!,
            _buildMessage(),
          ],
        ),
      ),
    );
  }

  Widget _showAvatarOrPlaceholder(types.User user) {
    if (user.id != message.authorId) {
      if (previousMessageDifferentAuthor && userAvatar != null) {
        return userAvatar!;
      } else if (avatarPlaceHolder != null) {
        return avatarPlaceHolder!;
      }
    }
    return Container();
  }
}
