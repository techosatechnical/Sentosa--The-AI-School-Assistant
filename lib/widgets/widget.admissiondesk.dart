import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nira/services/services.dart';
import 'package:webview_windows/webview_windows.dart';

class AdmissionAssistantDialog extends StatefulWidget {
  const AdmissionAssistantDialog({super.key});

  @override
  State<AdmissionAssistantDialog> createState() =>
      _AdmissionAssistantDialogState();
}

class _AdmissionAssistantDialogState extends State<AdmissionAssistantDialog> {
  final _controller = WebviewController();
  bool _isWebviewInitialized = false;
  StreamSubscription? _webMessageSubscription;
  StreamSubscription? _loadingStateSubscription;
  final FocusNode _webviewFocusNode = FocusNode(
    debugLabel: 'AdmissionWebviewKeyBridge',
  );

  static const String _keyboardInjectionScript = '''
(function() {
  if (window.__sentosa_osk_v3) return;
  window.__sentosa_osk_v3 = true;

  function notifyKeyboard() {
    try {
      if (window.chrome && window.chrome.webview) {
        window.chrome.webview.postMessage(JSON.stringify({ action: 'openKeyboard' }));
      }
    } catch (_) {}
  }

  function isTextInput(el) {
    if (!el || el.disabled || el.readOnly) return false;
    var tag = (el.tagName || '').toLowerCase();
    if (tag === 'textarea' || el.isContentEditable) {
      return true;
    }
    if (tag === 'input') {
      var type = (el.type || 'text').toLowerCase();
      var textTypes = [
        'text',
        'password',
        'email',
        'number',
        'tel',
        'search',
        'url',
        'date',
        'datetime-local',
        'time',
        'month',
        'week'
      ];
      return textTypes.indexOf(type) !== -1;
    }
    return false;
  }

  // --- Suppress the Windows Touch Keyboard: mark fields inputmode="none" ---
  function markNoTouchKeyboard(el) {
    try {
      if (el && el.getAttribute && el.getAttribute('inputmode') !== 'none') {
        el.setAttribute('inputmode', 'none');
      }
    } catch (_) {}
  }

  var FIELD_SELECTOR = 'input, textarea, [contenteditable]';

  function suppressTouchKeyboard(root) {
    try {
      if (root.matches && root.matches(FIELD_SELECTOR)) markNoTouchKeyboard(root);
      if (root.querySelectorAll) {
        var nodes = root.querySelectorAll(FIELD_SELECTOR);
        for (var i = 0; i < nodes.length; i++) markNoTouchKeyboard(nodes[i]);
      }
    } catch (_) {}
  }

  suppressTouchKeyboard(document);
  document.addEventListener('DOMContentLoaded', function() {
    suppressTouchKeyboard(document);
  });
  try {
    new MutationObserver(function(mutations) {
      for (var i = 0; i < mutations.length; i++) {
        var added = mutations[i].addedNodes;
        for (var j = 0; j < added.length; j++) {
          if (added[j].nodeType === 1) suppressTouchKeyboard(added[j]);
        }
      }
    }).observe(document, { childList: true, subtree: true });
  } catch (_) {}

  // --- Open osk.exe only on an actual tap (never on page-load auto-focus) ---
  document.addEventListener('pointerdown', function(e) {
    if (isTextInput(e.target)) {
      markNoTouchKeyboard(e.target);
      notifyKeyboard();
    }
  }, true);

  document.addEventListener('click', function(e) {
    if (isTextInput(e.target)) {
      notifyKeyboard();
    }
  }, true);

  // --- Key bridge: keystrokes forwarded from Flutter (osk.exe / physical keyboard) ---
  function deepActiveElement() {
    var el = document.activeElement;
    while (el && el.tagName === 'IFRAME') {
      try {
        var d = el.contentDocument;
        if (!d || !d.activeElement) break;
        el = d.activeElement;
      } catch (_) { break; }
    }
    return el;
  }

  function readValue(el) {
    return el.isContentEditable ? el.innerText : (el.value || '');
  }

  function supportsSelection(el) {
    try { return typeof el.selectionStart === 'number' && el.selectionStart !== null; }
    catch (_) { return false; }
  }

  function setSel(el, pos) {
    try { el.setSelectionRange(pos, pos); } catch (_) {}
  }

  function setNativeValue(el, value) {
    var win = (el.ownerDocument && el.ownerDocument.defaultView) || window;
    var proto = el.tagName.toLowerCase() === 'textarea'
      ? win.HTMLTextAreaElement.prototype
      : win.HTMLInputElement.prototype;
    var desc = Object.getOwnPropertyDescriptor(proto, 'value');
    if (desc && desc.set) { desc.set.call(el, value); } else { el.value = value; }
    el.dispatchEvent(new Event('input', { bubbles: true }));
    el.dispatchEvent(new Event('change', { bubbles: true }));
  }

  function insertText(el, text) {
    var doc = el.ownerDocument || document;
    var before = readValue(el);
    try { doc.execCommand('insertText', false, text); } catch (_) {}
    if (el.isContentEditable || readValue(el) !== before) return;

    // Fallback when execCommand did not apply (e.g. document not focused).
    if ((el.type || '').toLowerCase() === 'number' && !/^[0-9.eE+-]+\$/.test(text)) return;
    var v = el.value || '';
    if (supportsSelection(el)) {
      var s = el.selectionStart, e = el.selectionEnd;
      setNativeValue(el, v.slice(0, s) + text + v.slice(e));
      setSel(el, s + text.length);
    } else {
      setNativeValue(el, v + text);
    }
  }

  function deleteText(el, forward) {
    var doc = el.ownerDocument || document;
    var before = readValue(el);
    try { doc.execCommand(forward ? 'forwardDelete' : 'delete', false, null); } catch (_) {}
    if (el.isContentEditable || readValue(el) !== before) return;

    var v = el.value || '';
    if (supportsSelection(el)) {
      var s = el.selectionStart, e = el.selectionEnd;
      if (s !== e) {
        setNativeValue(el, v.slice(0, s) + v.slice(e));
        setSel(el, s);
      } else if (!forward && s > 0) {
        setNativeValue(el, v.slice(0, s - 1) + v.slice(s));
        setSel(el, s - 1);
      } else if (forward && s < v.length) {
        setNativeValue(el, v.slice(0, s) + v.slice(s + 1));
        setSel(el, s);
      }
    } else if (!forward && v.length) {
      setNativeValue(el, v.slice(0, -1));
    }
  }

  function moveCaret(el, action) {
    if (!supportsSelection(el)) return;
    var v = el.value || '';
    var s = el.selectionStart, e = el.selectionEnd;
    if (action === 'left') setSel(el, s !== e ? s : Math.max(0, s - 1));
    else if (action === 'right') setSel(el, s !== e ? e : Math.min(v.length, e + 1));
    else if (action === 'home') setSel(el, 0);
    else if (action === 'end') setSel(el, v.length);
  }

  function isVisible(n) {
    return !!(n.offsetWidth || n.offsetHeight || n.getClientRects().length);
  }

  function moveFocus(el, backwards, textOnly) {
    var doc = (el && el.ownerDocument) || document;
    var all = doc.querySelectorAll(
      'input, textarea, select, button, a[href], [contenteditable], [tabindex]'
    );
    var list = Array.prototype.filter.call(all, function(n) {
      if (n.disabled || n.tabIndex < 0 || (n.type || '').toLowerCase() === 'hidden') return false;
      if (!isVisible(n)) return false;
      return textOnly ? isTextInput(n) : true;
    });
    if (!list.length) return;
    var idx = list.indexOf(el);
    var next = idx === -1
      ? list[0]
      : list[idx + (backwards ? -1 : 1)];
    if (next) {
      next.focus();
      try { next.scrollIntoView({ block: 'center', behavior: 'smooth' }); } catch (_) {}
    }
  }

  window.__niraKey = function(action, data) {
    var el = deepActiveElement();
    if (action === 'tab') { moveFocus(el, !!data, false); return true; }
    if (!isTextInput(el)) return false;

    switch (action) {
      case 'text':
        insertText(el, String(data == null ? '' : data));
        break;
      case 'backspace':
        deleteText(el, false);
        break;
      case 'delete':
        deleteText(el, true);
        break;
      case 'enter':
        if ((el.tagName || '').toLowerCase() === 'textarea' || el.isContentEditable) {
          insertText(el, '\\n');
        } else {
          moveFocus(el, false, true);
        }
        break;
      case 'left':
      case 'right':
      case 'home':
      case 'end':
        moveCaret(el, action);
        break;
      case 'selectAll':
        try { el.select ? el.select() : (el.ownerDocument || document).execCommand('selectAll'); } catch (_) {}
        break;
    }
    return true;
  };

  // --- Custom in-DOM dropdown picker for HTML <select> elements ---
  function openCustomSelect(select) {
    if (!select || select.disabled) return;
    var existing = document.getElementById('__sentosa_select_modal');
    if (existing) existing.remove();

    var options = Array.from(select.options || []);
    if (!options.length) return;

    var overlay = document.createElement('div');
    overlay.id = '__sentosa_select_modal';
    overlay.style.cssText = 'position:fixed;top:0;left:0;width:100vw;height:100vh;background:rgba(15,23,42,0.5);backdrop-filter:blur(2px);z-index:2147483647;display:flex;align-items:center;justify-content:center;padding:16px;box-sizing:border-box;font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif;';

    var modal = document.createElement('div');
    modal.style.cssText = 'background:#ffffff;border-radius:20px;max-width:440px;width:100%;max-height:75vh;display:flex;flex-direction:column;box-shadow:0 25px 50px -12px rgba(0,0,0,0.35);overflow:hidden;border:1.5px solid #e2e8f0;';

    var header = document.createElement('div');
    header.style.cssText = 'padding:14px 18px;border-bottom:1px solid #f1f5f9;display:flex;align-items:center;justify-content:space-between;background:#f8fafc;';

    var titleText = select.getAttribute('aria-label') || select.name || select.id || 'Select Option';
    try {
      var label = select.id ? document.querySelector('label[for="' + select.id + '"]') : select.closest('label');
      if (label && label.innerText) {
        var cleanLabel = label.innerText.replace(/[*:]/g, '').trim();
        if (cleanLabel) titleText = cleanLabel;
      }
    } catch (_) {}

    var title = document.createElement('div');
    title.style.cssText = 'font-weight:700;font-size:16px;color:#0f2942;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;max-width:320px;';
    title.innerText = titleText;

    var closeBtn = document.createElement('button');
    closeBtn.type = 'button';
    closeBtn.style.cssText = 'border:none;background:transparent;cursor:pointer;font-size:24px;color:#64748b;padding:0 6px;line-height:1;border-radius:8px;';
    closeBtn.innerHTML = '&times;';
    closeBtn.onclick = function(ev) {
      ev.stopPropagation();
      overlay.remove();
    };

    header.appendChild(title);
    header.appendChild(closeBtn);
    modal.appendChild(header);

    var list = document.createElement('div');
    list.style.cssText = 'overflow-y:auto;padding:10px;flex:1;max-height:calc(75vh - 60px);';

    options.forEach(function(opt, idx) {
      var item = document.createElement('div');
      var isSelected = opt.selected || select.selectedIndex === idx;
      var isDisabled = opt.disabled;

      item.style.cssText = 'padding:13px 16px;margin:3px 0;border-radius:12px;font-size:15px;display:flex;align-items:center;justify-content:space-between;transition:background 0.12s;' +
        (isDisabled ? 'opacity:0.4;cursor:not-allowed;' : 'cursor:pointer;') +
        (isSelected ? 'background:#e0f2fe;color:#0284c7;font-weight:700;' : 'color:#1e293b;');

      var textSpan = document.createElement('span');
      textSpan.innerText = opt.text || opt.label || opt.value || ('Option ' + (idx + 1));
      item.appendChild(textSpan);

      if (isSelected) {
        var check = document.createElement('span');
        check.innerHTML = '&#10003;';
        check.style.cssText = 'font-weight:bold;color:#0284c7;font-size:16px;margin-left:8px;';
        item.appendChild(check);
      }

      if (!isDisabled) {
        item.onclick = function(ev) {
          ev.stopPropagation();
          select.selectedIndex = idx;
          select.value = opt.value;
          try {
            select.dispatchEvent(new Event('input', { bubbles: true }));
            select.dispatchEvent(new Event('change', { bubbles: true }));
          } catch (err) {
            var evt = document.createEvent('HTMLEvents');
            evt.initEvent('change', true, true);
            select.dispatchEvent(evt);
          }
          overlay.remove();
        };
      }

      list.appendChild(item);
    });

    modal.appendChild(list);
    overlay.appendChild(modal);

    overlay.onclick = function(ev) {
      if (ev.target === overlay) {
        overlay.remove();
      }
    };

    (document.body || document.documentElement).appendChild(overlay);
  }

  function handleSelectTrigger(e) {
    var target = e.target;
    var select = target ? target.closest('select') : null;
    if (select && !select.disabled) {
      e.preventDefault();
      e.stopPropagation();
      openCustomSelect(select);
    }
  }

  document.addEventListener('pointerdown', handleSelectTrigger, true);
  document.addEventListener('mousedown', handleSelectTrigger, true);
  document.addEventListener('click', handleSelectTrigger, true);
  document.addEventListener('touchstart', handleSelectTrigger, true);
})();
''';

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    try {
      await _controller.initialize();
      await _controller.setBackgroundColor(Colors.transparent);
      await _controller.setPopupWindowPolicy(WebviewPopupWindowPolicy.deny);

      try {
        await _controller.addScriptToExecuteOnDocumentCreated(
          _keyboardInjectionScript,
        );
      } catch (_) {}

      _webMessageSubscription = _controller.webMessage.listen((message) {
        final wantsKeyboard =
            (message is Map && message['action'] == 'openKeyboard') ||
            (message is String && message.contains('openKeyboard'));
        if (wantsKeyboard) {
          _focusKeyBridge();
          KeyboardService.openOnScreenKeyboard();
        }
      });

      _loadingStateSubscription = _controller.loadingState.listen((state) {
        if (state == LoadingState.navigationCompleted) {
          try {
            _controller.executeScript(_keyboardInjectionScript);
          } catch (_) {}
        }
      });

      await _controller.loadUrl('https://nirmalabhavanschool.org/admission');

      if (!mounted) return;
      setState(() {
        _isWebviewInitialized = true;
      });
    } on PlatformException catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Error'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Code: ${e.code}'),
                Text('Message: ${e.message}'),
              ],
            ),
            actions: [
              TextButton(
                child: const Text('Continue'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _webMessageSubscription?.cancel();
    _loadingStateSubscription?.cancel();
    _webviewFocusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  // --- Key bridge -----------------------------------------------------------
  // webview_windows renders WebView2 off-screen and only forwards pointer
  // events, so keystrokes (from osk.exe or a physical keyboard) land on the
  // Flutter window. We capture them here and replay them into the focused
  // field inside the page via window.__niraKey (see _keyboardInjectionScript).

  void _focusKeyBridge() {
    if (mounted && !_webviewFocusNode.hasFocus) {
      _webviewFocusNode.requestFocus();
    }
  }

  Future<void> _sendKeyToWeb(String action, [Object? data]) async {
    if (!_isWebviewInitialized) return;
    try {
      await _controller.executeScript(
        'window.__niraKey && window.__niraKey(${jsonEncode(action)}, ${jsonEncode(data)});',
      );
    } catch (_) {}
  }

  Future<void> _pasteIntoWeb() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text != null && text.isNotEmpty) {
      await _sendKeyToWeb('text', text);
    }
  }

  KeyEventResult _handleWebviewKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;

    final key = event.logicalKey;
    final keyboard = HardwareKeyboard.instance;

    // Ctrl shortcuts (AltGr reports Ctrl+Alt, so let that fall through).
    if ((keyboard.isControlPressed || keyboard.isMetaPressed) &&
        !keyboard.isAltPressed) {
      if (key == LogicalKeyboardKey.keyV) {
        _pasteIntoWeb();
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.keyA) {
        _sendKeyToWeb('selectAll');
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    if (key == LogicalKeyboardKey.backspace) {
      _sendKeyToWeb('backspace');
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.delete) {
      _sendKeyToWeb('delete');
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      _sendKeyToWeb('enter');
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.tab) {
      _sendKeyToWeb('tab', keyboard.isShiftPressed);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft) {
      _sendKeyToWeb('left');
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight) {
      _sendKeyToWeb('right');
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.home) {
      _sendKeyToWeb('home');
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.end) {
      _sendKeyToWeb('end');
      return KeyEventResult.handled;
    }

    final ch = event.character;
    if (ch != null && ch.isNotEmpty) {
      final code = ch.codeUnitAt(0);
      if (code >= 0x20 && code != 0x7F) {
        _sendKeyToWeb('text', ch);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  Future<WebviewPermissionDecision> _onPermissionRequested(
    String url,
    WebviewPermissionKind kind,
    bool isUserInitiated,
  ) async {
    final decision = await showDialog<WebviewPermissionDecision>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('WebView permission requested'),
        content: Text('WebView has requested permission \'$kind\''),
        actions: <Widget>[
          TextButton(
            onPressed: () =>
                Navigator.pop(context, WebviewPermissionDecision.deny),
            child: const Text('Deny'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, WebviewPermissionDecision.allow),
            child: const Text('Allow'),
          ),
        ],
      ),
    );

    return decision ?? WebviewPermissionDecision.none;
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        width: 1000,
        height: screenHeight * 0.75,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 24,
              spreadRadius: 8,
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: -50,
              left: -50,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFBAE6FD).withValues(alpha: 0.45),
                ),
              ),
            ),
            Positioned(
              top: 280,
              right: -60,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFDBEAFE).withValues(alpha: 0.5),
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              left: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFCCFBF1).withValues(alpha: 0.35),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.auto_awesome,
                            color: Colors.blueAccent,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "Admission Assistant",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 28),
                        onPressed: () => Navigator.of(context).pop(),
                        splashRadius: 24,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: Container(
                      clipBehavior: Clip.hardEdge,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey[300]!,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: _isWebviewInitialized
                          ? Stack(
                              children: [
                                Focus(
                                  focusNode: _webviewFocusNode,
                                  autofocus: true,
                                  onKeyEvent: _handleWebviewKey,
                                  child: Listener(
                                    onPointerDown: (_) => _focusKeyBridge(),
                                    child: Webview(
                                      _controller,
                                      permissionRequested:
                                          _onPermissionRequested,
                                    ),
                                  ),
                                ),
                                StreamBuilder<LoadingState>(
                                  stream: _controller.loadingState,
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData &&
                                        snapshot.data == LoadingState.loading) {
                                      return Container(
                                        color: Colors.white.withValues(
                                          alpha: 0.9,
                                        ),
                                        child: Center(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.school_rounded,
                                                size: 72,
                                                color: Colors.blueAccent,
                                              ),
                                              const SizedBox(height: 24),
                                              const Text(
                                                'Preparing Admission Form...',
                                                style: TextStyle(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.blueAccent,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                              const SizedBox(height: 24),
                                              SizedBox(
                                                width: 250,
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  child: const LinearProgressIndicator(
                                                    minHeight: 6,
                                                    backgroundColor: Color(
                                                      0xFFE0F2FE,
                                                    ),
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                          Color
                                                        >(Colors.blueAccent),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                                Positioned(
                                  right: 18,
                                  bottom: 18,
                                  child: Material(
                                    color: Colors.white,
                                    elevation: 6,
                                    shadowColor: Colors.black.withValues(
                                      alpha: 0.2,
                                    ),
                                    borderRadius: BorderRadius.circular(24),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(24),
                                      onTap: () {
                                        _focusKeyBridge();
                                        KeyboardService.openOnScreenKeyboard();
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF0F9FF),
                                          borderRadius: BorderRadius.circular(
                                            24,
                                          ),
                                          border: Border.all(
                                            color: const Color(0xFF38BDF8),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: const [
                                            Icon(
                                              Icons.keyboard_alt_outlined,
                                              size: 20,
                                              color: Color(0xFF0284C7),
                                            ),
                                            SizedBox(width: 6),
                                            Text(
                                              "Open Keyboard",
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF0284C7),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Container(
                              color: Colors.white,
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.cloud_sync_rounded,
                                      size: 72,
                                      color: Colors.blueAccent,
                                    ),
                                    const SizedBox(height: 24),
                                    const Text(
                                      'Connecting to portal...',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.blueAccent,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    SizedBox(
                                      width: 250,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: const LinearProgressIndicator(
                                          minHeight: 6,
                                          backgroundColor: Color(0xFFE0F2FE),
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.blueAccent,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
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
    );
  }
}
