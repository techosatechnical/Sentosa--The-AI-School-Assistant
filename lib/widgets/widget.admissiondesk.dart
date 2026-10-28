import 'dart:async';
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

  // --- Keyboard triggers for textual inputs only ---
  document.addEventListener('focusin', function(e) {
    if (isTextInput(e.target)) {
      notifyKeyboard();
    }
  }, true);

  document.addEventListener('click', function(e) {
    if (isTextInput(e.target)) {
      notifyKeyboard();
    }
  }, true);

  document.addEventListener('pointerdown', function(e) {
    if (isTextInput(e.target)) {
      notifyKeyboard();
    }
  }, true);

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
        if (message is Map && message['action'] == 'openKeyboard') {
          KeyboardService.openOnScreenKeyboard();
        } else if (message is String && message.contains('openKeyboard')) {
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
    _controller.dispose();
    super.dispose();
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
                                Webview(
                                  _controller,
                                  permissionRequested: _onPermissionRequested,
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
                                      onTap:
                                          KeyboardService.openOnScreenKeyboard,
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
