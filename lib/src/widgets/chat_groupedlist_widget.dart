/*
 * Copyright (c) 2022 Simform Solutions
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

import 'package:chatview_utils/chatview_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../extensions/extensions.dart';
import '../models/config_models/feature_active_config.dart';
import '../models/config_models/message_list_configuration.dart';
import '../models/config_models/send_message_configuration.dart';
import '../values/enumeration.dart';
import '../values/typedefs.dart';
import 'chat_bubble_widget.dart';
import 'chat_group_header.dart';
import 'end_message_footer.dart';
import 'pagination_loader.dart';

class ChatGroupedListWidget extends StatefulWidget {
  const ChatGroupedListWidget({
    super.key,
    required this.showPopUp,
    required this.scrollController,
    required this.assignReplyMessage,
    required this.onChatListTap,
    required this.onChatBubbleLongPress,
    required this.isEnableSwipeToSeeTime,
    this.textFieldConfig,
    this.loadMoreData,
    this.isLastPage,
    this.loadingWidget,
  });

  /// Allow user to swipe to see time while reaction pop is not open.
  final bool showPopUp;

  /// Pass scroll controller
  final ScrollController scrollController;

  /// Provides callback for assigning reply message when user swipe on chat bubble.
  final ValueSetter<Message> assignReplyMessage;

  /// Provides callback when user tap anywhere on whole chat.
  final VoidCallback onChatListTap;

  /// Provides callback when user press chat bubble for certain time then usual.
  final ChatBubbleLongPressCallback onChatBubbleLongPress;

  /// Provide flag for turn on/off to see message crated time view when user
  /// swipe whole chat.
  final bool isEnableSwipeToSeeTime;

  /// Provides configuration for text field.
  final TextFieldConfiguration? textFieldConfig;

  /// Provides callback when user actions reaches to top and needs to load more
  /// chat
  final PaginationCallback? loadMoreData;

  /// Provides flag if there is no more next data left in list.
  final ValueGetter<bool>? isLastPage;

  /// Provides widget for loading view while pagination is enabled.
  final Widget? loadingWidget;

  @override
  State<ChatGroupedListWidget> createState() => _ChatGroupedListWidgetState();
}

class _ChatGroupedListWidgetState extends State<ChatGroupedListWidget>
    with TickerProviderStateMixin {
  final ValueNotifier<bool> _isNextPageLoading = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _isPrevPageLoading = ValueNotifier<bool>(false);

  bool get showPopUp => widget.showPopUp;

  bool highlightMessage = false;
  final ValueNotifier<String?> _replyId = ValueNotifier(null);
  final _listKey = ValueNotifier(UniqueKey());

  AnimationController? _animationController;
  Animation<Offset>? _slideAnimation;

  FeatureActiveConfig? featureActiveConfig;

  ChatController? chatController;

  bool get isEnableSwipeToSeeTime => widget.isEnableSwipeToSeeTime;

  ChatBackgroundConfiguration get chatBackgroundConfig =>
      chatListConfig.chatBackgroundConfig;

  final Map<String, GlobalKey> _messageKeys = {};

  /// Monotonic token identifying the currently-active jump/scroll-to-message
  /// scan. Each new request bumps it; an in-flight scan loop bails the moment a
  /// newer one starts, so only ONE scan can ever run (concurrent scans fought
  /// over the scroll controller and oscillated "back and forth" without ever
  /// reaching the target).
  int _scanGeneration = 0;

  bool get isPaginationEnabled =>
      featureActiveConfig?.enablePagination ?? false;

  ValueListenable<bool>? get typingIndicatorNotifier =>
      chatController?.typingIndicatorNotifier;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
  }

  void _initializeAnimation() {
    // When this flag is on at that time only animation controllers will be
    // initialized.
    if (!isEnableSwipeToSeeTime) return;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _slideAnimation =
        Tween<Offset>(begin: Offset.zero, end: Offset.zero).animate(
      CurvedAnimation(curve: Curves.decelerate, parent: _animationController!),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (chatViewIW != null) {
      featureActiveConfig = chatViewIW!.featureActiveConfig;
      chatController = chatViewIW!.chatController
        ..registerListViewReset(() => _listKey.value = UniqueKey());
      // p18: react to app-driven jump-to-message (favorites / global search).
      final notifier = chatViewIW!.highlightMessageNotifier;
      if (notifier != null && !identical(notifier, _highlightNotifier)) {
        _highlightNotifier?.removeListener(_onHighlightRequested);
        _highlightNotifier = notifier..addListener(_onHighlightRequested);
        // Handle a value set before this widget subscribed.
        if (notifier.value != null) _onHighlightRequested();
      }
    }
    _initializeAnimation();
  }

  /// p18: scroll the requested message into view + pulse it, reusing the
  /// replied-message auto-scroll/highlight path. Deferred a frame so the list
  /// is laid out (message GlobalKeys populated) before we scroll.
  ValueNotifier<String?>? _highlightNotifier;
  void _onHighlightRequested() {
    final id = _highlightNotifier?.value;
    if (id == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final messages = chatController?.initialMessageList ?? const <Message>[];
      final inList = messages.any((m) => m.id == id);
      // Only scan when the target is actually in the loaded list. Paging older
      // history in is the HOST's job (it re-requests the highlight once the
      // message is loaded) — doing it here too spawned a second, competing scan
      // loop that fought the first over the scroll controller (neither made
      // progress → both gave up).
      if (inList) {
        _onReplyTap(id, messages);
      }
      _highlightNotifier?.value = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate:
          isEnableSwipeToSeeTime && !showPopUp ? _onHorizontalDrag : null,
      onHorizontalDragEnd: isEnableSwipeToSeeTime && !showPopUp
          ? (_) => _animationController?.reverse()
          : null,
      onTap: widget.onChatListTap,
      child: _animationController == null
          ? _chatStreamBuilder
          : AnimatedBuilder(
              animation: _animationController!,
              builder: (_, __) => _chatStreamBuilder,
            ),
    );
  }

  Future<void> _onReplyTap(
    String id,
    List<Message> messages, {
    int? messageIndex,
    int scrollAttempts = 0,
    double scanDir = 0,
    bool flipped = false,
    int? generation,
  }) async {
    // First entry (generation == null) starts a new scan and supersedes any
    // in-flight one; recursive steps carry their scan's token and bail if a
    // newer scan has since started.
    final gen = generation ?? ++_scanGeneration;
    if (gen != _scanGeneration) return;

    final index = messageIndex == null || messageIndex.isNegative
        ? messages.indexWhere((message) => id == message.id)
        : messageIndex;

    // The message is not in the list. Notify the user to get messages around
    // it.
    if (index == -1) {
      final repliedMsgConfig = chatListConfig.repliedMessageConfig;
      if (repliedMsgConfig == null) {
        throw Exception(
          'Please provide [loadOldReplyMessage] callback in '
          '[RepliedMessageConfiguration] to load old messages.',
        );
      }

      // We have already requested user to load more data containing the message
      // id. But still the message is not found in the list.
      if (messageIndex?.isNegative ?? false) {
        throw Exception(
          'Failed to find message with id: $id. '
          'Please ensure to load the message in loadMoreData callback.',
        );
      }

      await repliedMsgConfig.loadOldReplyMessage(id);

      // Search for the message again in the updated message list.
      _onReplyTap(
        id,
        // Use the latest user updated message list.
        chatViewIW!.chatController.initialMessageList,
        // Helps stopping recursion.
        messageIndex: index,
        generation: gen,
      );
      return;
    }

    final repliedMessage = messages[index];
    final repliedMsgState = _messageKeys[repliedMessage.id]?.currentState;

    // The message is in the data list but its widget isn't built/rendered yet
    // (it's outside the ListView's cache extent). Scroll toward it a viewport at
    // a time until it renders, then fall through to ensureVisible below.
    if (repliedMsgState == null) {
      // p18: the scroll position may not be attached yet on the first frames
      // after open — a programmatic jump (favorites / global search) can fire
      // while the message stream hasn't emitted the list, so the ListView (and
      // its ScrollController position) isn't built. Reading
      // `scrollController.position` then throws "Bad state: No element" and
      // crashes the app. Wait for it to attach, bounded so it can't spin forever.
      if (!widget.scrollController.hasClients) {
        if (scrollAttempts >= 40) return; // give up quietly, no crash
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _onReplyTap(id, messages,
                messageIndex: index,
                scrollAttempts: scrollAttempts + 1,
                generation: gen);
          }
        });
        return;
      }

      // Bound the scan so a target we can never render (variable-height media
      // makes a fixed linear estimate never line up) can't loop forever and
      // FREEZE the UI. 80 viewport-steps is far more than any real chat.
      if (scrollAttempts >= 80) return;

      final position = widget.scrollController.position;
      final step = position.viewportDimension * 0.8;

      // Direction: don't assume the list's index→offset orientation (it bit us —
      // the guess was inverted and we hit the wrong edge instantly). Keep the
      // direction we're already scanning in; only on the FIRST step make a guess,
      // and if a step hits an edge without rendering the target, FLIP once and
      // scan the whole other way. The target is known to be in `messages`, so a
      // full sweep in the correct direction is guaranteed to bring it into the
      // cache extent and render it.
      double direction = scanDir;
      if (direction == 0) {
        // Initial guess from a rendered neighbour (index delta), else midpoint.
        for (final entry in _messageKeys.entries) {
          if (entry.value.currentState == null) continue;
          final renderedIndex = messages.indexWhere((m) => m.id == entry.key);
          if (renderedIndex == -1 || renderedIndex == index) continue;
          direction = index > renderedIndex ? 1.0 : -1.0;
          break;
        }
        if (direction == 0) direction = 1.0;
      }

      final next = (position.pixels + step * direction)
          .clamp(position.minScrollExtent, position.maxScrollExtent);
      if ((next - position.pixels).abs() < 1.0) {
        // Can't move further this way. Flip once and sweep the other direction;
        // if we've already flipped, the target genuinely isn't reachable — stop.
        if (!flipped) {
          _onReplyTap(id, messages,
              messageIndex: index,
              scrollAttempts: scrollAttempts + 1,
              scanDir: -direction,
              flipped: true,
              generation: gen);
        }
        return;
      }
      widget.scrollController
          .animateTo(
            next,
            curve: Curves.ease,
            duration: const Duration(milliseconds: 50),
          )
          .then((_) => _onReplyTap(id, messages,
              messageIndex: index,
              scrollAttempts: scrollAttempts + 1,
              scanDir: direction,
              flipped: flipped,
              generation: gen));
      return;
    }

    final repliedMsgAutoScrollConfig =
        chatListConfig.repliedMessageConfig?.repliedMsgAutoScrollConfig;
    final highlightDuration = repliedMsgAutoScrollConfig?.highlightDuration ??
        const Duration(milliseconds: 300);

    // Scrolls to replied message and highlights
    await Scrollable.ensureVisible(
      repliedMsgState.context,
      curve: repliedMsgAutoScrollConfig?.highlightScrollCurve ?? Curves.easeIn,
      duration: highlightDuration,
      // This value will make widget to be in center when auto scrolled.
      alignment: repliedMsgAutoScrollConfig?.alignment ?? 0.5,
    );

    if (repliedMsgAutoScrollConfig?.enableHighlightRepliedMsg ?? false) {
      _pulseHighlight(id, highlightDuration);
    }
  }

  /// Blink the highlight a few times (p18) instead of a single flash — the
  /// single pulse read as "too subtle" for jump-to-message. Each on/off cycle
  /// runs for [duration]; a short gap between makes the blink legible.
  Future<void> _pulseHighlight(String id, Duration duration, {int times = 3}) async {
    // Hold each on/off phase for the full [duration] so the bubble's
    // AnimatedContainer colour fade completes each way — a clean pulse rather
    // than a clipped shimmer.
    for (var i = 0; i < times; i++) {
      if (!mounted) return;
      _replyId.value = id;
      await Future.delayed(duration);
      if (!mounted) return;
      _replyId.value = null;
      if (i < times - 1) await Future.delayed(duration);
    }
  }

  /// When user swipe at that time only animation is assigned with value.
  void _onHorizontalDrag(DragUpdateDetails details) {
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-0.2, 0.0),
    ).animate(
      CurvedAnimation(
        curve: chatBackgroundConfig.messageTimeAnimationCurve,
        parent: _animationController!,
      ),
    );

    details.delta.dx > 1
        ? _animationController?.reverse()
        : _animationController?.forward();
  }

  @override
  void dispose() {
    _highlightNotifier?.removeListener(_onHighlightRequested);
    _animationController?.dispose();
    _replyId.dispose();
    _isNextPageLoading.dispose();
    _isPrevPageLoading.dispose();
    super.dispose();
  }

  Widget get _chatStreamBuilder {
    var lastMatchedDate = DateTime.now();
    return StreamBuilder<List<Message>>(
      stream: chatController?.messageStreamController.stream,
      builder: (context, snapshot) {
        if (!snapshot.connectionState.isActive) {
          return Center(
            child: chatBackgroundConfig.loadingWidget ??
                const CircularProgressIndicator.adaptive(),
          );
        } else {
          final data = snapshot.data!;
          final messages = chatBackgroundConfig.sortEnable
              ? sortMessage(data)
              : data.reversed.toList();

          final enableSeparator =
              featureActiveConfig?.enableChatSeparator ?? false;

          var messageSeparator = <int, DateTime>{};
          var separatorCounts = <int, int>{};

          if (enableSeparator && messages.isNotEmpty) {
            /// Get separator when date differ for two messages
            (messageSeparator, lastMatchedDate, separatorCounts) =
                _getMessageSeparator(messages, lastMatchedDate);
          } else {
            _initMessageKeys(messages);
          }

          final messageLength = messages.length;

          var itemCount = enableSeparator
              ? messageLength + messageSeparator.length
              : messageLength;

          return NotificationListener<ScrollUpdateNotification>(
            onNotification: (notification) => _onScrollUpdateNotification(
              notification,
              messages,
            ),
            child: ListenableBuilder(
              listenable: Listenable.merge([
                _listKey,
                chatViewIW?.chatTextFieldHeight,
                _isNextPageLoading,
                _isPrevPageLoading,
              ]),
              builder: (context, child) {
                // Whether to reserve an extra slot at the top (the list is
                // reversed) for the previous-page loader.
                final showPrevPageLoader = _isPrevPageLoading.value;

                // Derive the effective count without mutating [itemCount].
                // Using `++itemCount` here would permanently inflate the
                // captured [itemCount] every time this builder re-runs while
                // [_isPrevPageLoading] is true (e.g. when the text field
                // height changes during a load), eventually producing
                // out-of-range indices.
                final effectiveItemCount =
                    showPrevPageLoader ? itemCount + 1 : itemCount;

                return ListView.builder(
                  key: _listKey.value,
                  controller: widget.scrollController,
                  keyboardDismissBehavior:
                      chatBackgroundConfig.scrollViewKeyboardDismissBehavior ??
                          ScrollViewKeyboardDismissBehavior.manual,
                  // When reaction popup is being appeared at that user should
                  // not scroll.
                  physics:
                      showPopUp ? const NeverScrollableScrollPhysics() : null,
                  padding: EdgeInsets.only(
                    // Adds bottom space to the message list, ensuring it is
                    // displayed above the message text field.
                    bottom: chatViewIW?.chatTextFieldHeight.value ?? 0,
                  ),
                  reverse: true,
                  itemCount: effectiveItemCount,
                  itemBuilder: (context, index) {
                    // Since the list is reversed, check if it's the last item
                    // to display the loading widget at top.
                    if (showPrevPageLoader && index == effectiveItemCount - 1) {
                      return PaginationLoader(
                        listenable: _isPrevPageLoading,
                        loader: widget.loadingWidget,
                      );
                    }

                    /// Check [messageSeparator] contains group separator for [index]
                    if (enableSeparator &&
                        messageSeparator.containsKey(index)) {
                      final separator = messageSeparator[index]!;
                      return chatBackgroundConfig.groupSeparatorBuilder
                              ?.call(separator.toString()) ??
                          ChatGroupHeader(
                            day: separator,
                            groupSeparatorConfig: chatBackgroundConfig
                                .defaultGroupSeparatorConfig,
                          );
                    }

                    /// By removing separators encountered till now from the [index]
                    /// so that we'll get actual index to display message in chat
                    var newIndex = index - (separatorCounts[index] ?? 0);

                    final messageChild = ValueListenableBuilder<String?>(
                      valueListenable: _replyId,
                      builder: (context, state, child) {
                        final message = messages[newIndex];
                        final messageKey =
                            _messageKeys[message.id] ??= GlobalKey();
                        final enableScrollToRepliedMsg = chatListConfig
                                .repliedMessageConfig
                                ?.repliedMsgAutoScrollConfig
                                .enableScrollToRepliedMsg ??
                            false;
                        // ListView is reversed: index 0 = newest (bottom).
                        // isLastInGroup  → avatar shown (newest in group, visually bottom).
                        // isFirstInGroup → name shown  (oldest in group, visually top).
                        //
                        // Edited messages show an "Edited" label ABOVE the bubble,
                        // creating a visual break only on the top side. So:
                        //  • isFirstInGroup=true when THIS message is edited
                        //    (Edited label above → detach from older message above).
                        //  • isLastInGroup=true when the NEWER/below neighbor is
                        //    edited (that neighbor's Edited label visually separates
                        //    it from the current message below).
                        // The connection below the edited message is preserved so
                        // messages sent after it stay grouped with it.
                        final prevMessage =
                            newIndex > 0 ? messages[newIndex - 1] : null;
                        final isLastInGroup = newIndex == 0 ||
                            !_isSameGroup(message, messages[newIndex - 1]) ||
                            (prevMessage?.updatedAt != null);
                        final isFirstInGroup = newIndex ==
                                messages.length - 1 ||
                            !_isSameGroup(message, messages[newIndex + 1]) ||
                            message.updatedAt != null;
                        return ChatBubbleWidget(
                          key: messageKey,
                          message: message,
                          slideAnimation: _slideAnimation,
                          onLongPress: (yCoordinate, xCoordinate) =>
                              widget.onChatBubbleLongPress(
                            yCoordinate,
                            xCoordinate,
                            message,
                          ),
                          onSwipe: widget.assignReplyMessage,
                          shouldHighlight: state == message.id,
                          onReplyTap: enableScrollToRepliedMsg
                              ? (id) => _onReplyTap(id, messages)
                              : null,
                          isFirstInGroup: isFirstInGroup,
                          isLastInGroup: isLastInGroup,
                        );
                      },
                    );

                    return index != 0
                        ? messageChild
                        // Since the list is reversed, we need to check if
                        // we are at the first item to display the typing indicator
                        // , suggestions and loading widget.
                        : EndMessageFooter(
                            loadingWidget: widget.loadingWidget,
                            isNextPageLoading: _isNextPageLoading,
                            typingIndicatorNotifier: typingIndicatorNotifier,
                            child: messageChild,
                          );
                  },
                );
              },
            ),
          );
        }
      },
    );
  }

  List<Message> sortMessage(List<Message> messages) {
    final elements = messages.toList();
    // When no custom [messageSorter] is supplied, sort newest-first by
    // createdAt with the message id as a deterministic tiebreak. createdAt is
    // not a unique key (sub-second collisions, mixed clock sources) and
    // List.sort is not stable, so without the tiebreak equal timestamps render
    // in an arbitrary, jittering order. The id tiebreak makes this a strict
    // total order (chattr p11).
    elements.sort(
      chatBackgroundConfig.messageSorter ??
          (a, b) {
            final byTime = b.createdAt.compareTo(a.createdAt);
            return byTime != 0 ? byTime : b.id.compareTo(a.id);
          },
    );
    // [elements] is already a fresh copy, so it can be returned directly for
    // the ascending case instead of allocating another list.
    return chatBackgroundConfig.groupedListOrder.isAsc
        ? elements
        : elements.reversed.toList();
  }

  /// return DateTime by checking lastMatchedDate and message created DateTime
  DateTime _groupBy(
    Message message,
    DateTime lastMatchedDate,
  ) {
    // If the conversation is ongoing on the same date,
    // return the same date [lastMatchedDate].

    // When the conversation starts on a new date,
    // we are returning new date [message.createdAt].
    return lastMatchedDate.getDateFromDateTime ==
            message.createdAt.getDateFromDateTime
        ? lastMatchedDate
        : message.createdAt;
  }

  GetMessageSeparatorWithCounts _getMessageSeparator(
    List<Message> messages,
    DateTime lastDate,
  ) {
    var counter = 0;
    var lastMatchedDate = lastDate;
    final messageSeparator = <int, DateTime>{};

    // Build separator counts as we build the separator map
    final separatorCounts = <int, int>{
      0: 0, // Initial count since the loop starts from index 1
    };

    _messageKeys.putIfAbsent(messages.first.id, () => GlobalKey());

    // Build separator map and update counts in the same loop
    for (var i = 1; i < messages.length; i++) {
      final message = messages[i];
      _messageKeys.putIfAbsent(message.id, () => GlobalKey());
      lastMatchedDate = _groupBy(
        message,
        lastMatchedDate,
      );
      final previousDate = _groupBy(
        messages[i - 1],
        lastMatchedDate,
      );

      if (previousDate == lastMatchedDate) {
        separatorCounts[i + counter] = counter;
      } else {
        // Group separator when previous message and current message time differ
        final separatorIndex = i + counter++;
        separatorCounts[separatorIndex + 1] = counter;
        messageSeparator[separatorIndex] = previousDate;
      }
    }

    final separatorIndex = messages.length + counter;
    separatorCounts[separatorIndex + 1] = counter;
    messageSeparator[separatorIndex] = lastMatchedDate;

    return (messageSeparator, lastMatchedDate, separatorCounts);
  }

  bool _isSameGroup(Message a, Message b) {
    if (!(featureActiveConfig?.enableMessageGrouping ?? true)) return false;
    final threshold = featureActiveConfig?.messageGroupingThresholdMinutes ?? 1;
    return a.sentBy == b.sentBy &&
        a.createdAt.difference(b.createdAt).inMinutes.abs() < threshold;
  }

  void _initMessageKeys(List<Message> messages) {
    final messagesLength = messages.length;
    for (var i = 0; i < messagesLength; i++) {
      final message = messages[i];
      _messageKeys.putIfAbsent(message.id, () => GlobalKey());
    }
  }

  bool _onScrollUpdateNotification(
    ScrollUpdateNotification notification,
    List<Message> messages,
  ) {
    if (!isPaginationEnabled) return true;

    final metrics = notification.metrics;

    PaginationScrollUpdateResult result = (direction: null, message: null);

    final pixels = metrics.pixels;

    // Changed direction as ListView scrolls direction is reversed.
    if (pixels <= metrics.minScrollExtent) {
      result = (
        direction: ChatPaginationDirection.next,
        message: messages.firstOrNull,
      );
    } else if (pixels >= metrics.maxScrollExtent) {
      result = (
        direction: ChatPaginationDirection.previous,
        message: messages.lastOrNull,
      );
    }

    if (result.direction == null || result.message == null) return true;

    _pagination(direction: result.direction!, message: result.message!);
    return true;
  }

  void _pagination({
    required ChatPaginationDirection direction,
    required Message message,
  }) {
    if (widget.loadMoreData == null || (widget.isLastPage?.call() ?? false)) {
      return;
    }

    switch (direction) {
      case ChatPaginationDirection.previous:
        if (_isPrevPageLoading.value) return;
        _isPrevPageLoading.value = true;
        widget.loadMoreData
            ?.call(direction, message)
            .whenComplete(() => _isPrevPageLoading.value = false);
      case ChatPaginationDirection.next:
        if (_isNextPageLoading.value) return;
        _isNextPageLoading.value = true;
        widget.loadMoreData
            ?.call(direction, message)
            .whenComplete(() => _isNextPageLoading.value = false);
    }
  }
}
