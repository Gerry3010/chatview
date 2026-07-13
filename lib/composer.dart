/// Public API surface for building a **custom send-message composer** on top of
/// chatview's internal composer widgets.
///
/// chatview renders a built-in text field, but apps that need a bespoke
/// composer (custom send handling, reply adoption, drafts, paste, extra
/// actions) previously had to reach into `package:chatview/src/...` directly.
/// That coupling is fragile: an upstream refactor that moves or renames those
/// files silently breaks the app. This barrel is the stable, fork-maintained
/// contract — import `package:chatview/composer.dart` instead, and if upstream
/// reorganizes its internals only this one file needs to follow.
///
/// (Chattr-fork addition — not part of upstream chatview.)
library;

// Layout constants used to size the composer consistently with the package.
export 'src/utils/constants/constants.dart'
    show bottomPadding1, bottomPadding2, bottomPadding3, bottomPadding4;

// Ambient config getters (chatViewIW / chatListConfig / suggestionsConfig)
// a custom composer reads from its State / BuildContext.
export 'src/extensions/extensions.dart'
    show StatefulWidgetExtension, BuildContextExtension;

// Callback typedefs (e.g. StringMessageCallBack for onSendTap).
export 'src/values/typedefs.dart';

// The composer widget hierarchy + sub-widgets a custom text field composes.
export 'src/widgets/send_message_widget.dart';
export 'src/widgets/chatui_textfield.dart';
export 'src/widgets/reply_message_view.dart';
export 'src/widgets/scroll_to_bottom_button.dart';
export 'src/widgets/selected_image_view_widget.dart';
