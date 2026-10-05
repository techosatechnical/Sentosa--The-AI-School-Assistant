import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

class WifiStatusWidget extends StatefulWidget {
  const WifiStatusWidget({super.key});

  @override
  State<WifiStatusWidget> createState() => _WifiStatusWidgetState();
}

class _WifiStatusWidgetState extends State<WifiStatusWidget> {
  bool _isConnected = false;
  bool _isConnecting = false;
  String _ssid = "Disconnected";
  int _signalStrength = 0; // 0 to 100
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _checkWifiStatus();
    _timer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _checkWifiStatus(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkWifiStatus() async {
    try {
      final result = await Process.run('netsh', ['wlan', 'show', 'interfaces']);
      final output = result.stdout.toString();
      final stateMatch = RegExp(r'State\s*:\s*([a-zA-Z]+)').firstMatch(output);
      final stateStr = stateMatch?.group(1)?.toLowerCase() ?? '';

      if (stateStr == 'connected') {
        final ssidMatch = RegExp(r'SSID\s*:\s*(.+)').firstMatch(output);
        final signalMatch = RegExp(r'Signal\s*:\s*(\d+)%').firstMatch(output);

        if (mounted) {
          setState(() {
            _isConnected = true;
            _isConnecting = false;
            _ssid = ssidMatch?.group(1)?.trim() ?? "Connected";
            _signalStrength = int.tryParse(signalMatch?.group(1) ?? '0') ?? 0;
          });
        }
      } else if (stateStr == 'connecting' || stateStr == 'associating' || stateStr == 'authenticating') {
        if (mounted) {
          setState(() {
            _isConnected = false;
            _isConnecting = true;
            _ssid = "Connecting...";
            _signalStrength = 0;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isConnected = false;
            _isConnecting = false;
            _ssid = "Disconnected";
            _signalStrength = 0;
          });
        }
      }
    } catch (e) {
      // Ignore errors in background
    }
  }

  IconData _getWifiIcon() {
    if (!_isConnected) return Icons.wifi_off_rounded;
    if (_signalStrength > 75) return Icons.wifi_rounded;
    if (_signalStrength > 50) return Icons.network_wifi_3_bar_rounded;
    if (_signalStrength > 25) return Icons.network_wifi_2_bar_rounded;
    return Icons.network_wifi_1_bar_rounded;
  }

  void _showNetworkPanel() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.2),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: EdgeInsets.only(top: 80, right: 32),
            child: Material(
              color: Colors.transparent,
              child: WifiNetworkPanel(),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0.0, -0.05),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOut),
                ),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _showNetworkPanel,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isConnected
                ? const Color(0xFFBAE6FD).withValues(alpha: 0.6)
                : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F2942).withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getWifiIcon(),
              size: 16,
              color: _isConnected
                  ? const Color(0xFF0284C7)
                  : (_isConnecting ? const Color(0xFFF59E0B) : const Color(0xFF64748B)),
            ),
            const SizedBox(width: 6),
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isConnected
                    ? const Color(0xFF10B981)
                    : (_isConnecting ? const Color(0xFFF59E0B) : const Color(0xFF94A3B8)),
                boxShadow: _isConnected || _isConnecting
                    ? [
                        BoxShadow(
                          color: _isConnected ? const Color(0xFF6EE7B7) : const Color(0xFFFCD34D),
                          blurRadius: 5,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
            ),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 100),
              child: Text(
                _ssid,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF334155),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WifiNetworkPanel extends StatefulWidget {
  const WifiNetworkPanel({super.key});

  @override
  State<WifiNetworkPanel> createState() => _WifiNetworkPanelState();
}

class _WifiNetworkPanelState extends State<WifiNetworkPanel> {
  bool _isLoading = true;
  List<Map<String, String>> _networks = [];
  String? _selectedSsidForPassword;
  String _tempPassword = '';

  @override
  void initState() {
    super.initState();
    _scanNetworks();
  }

  Future<void> _scanNetworks() async {
    setState(() => _isLoading = true);
    try {
      final result = await Process.run('netsh', ['wlan', 'show', 'networks']);
      final output = result.stdout.toString();

      final networks = <Map<String, String>>[];
      final lines = output.split('\n');

      String currentSsid = '';

      for (final line in lines) {
        if (line.trim().startsWith('SSID')) {
          final parts = line.split(':');
          if (parts.length > 1) {
            currentSsid = parts.sublist(1).join(':').trim();
            if (currentSsid.isNotEmpty) {
              networks.add({'ssid': currentSsid, 'auth': ''});
            }
          }
        } else if (line.trim().startsWith('Authentication') &&
            currentSsid.isNotEmpty) {
          final parts = line.split(':');
          if (parts.length > 1 && networks.isNotEmpty) {
            networks.last['auth'] = parts[1].trim();
          }
        }
      }

      if (mounted) {
        setState(() {
          _networks = networks;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _connectToNetwork(String ssid, String auth) async {
    final isSecure = auth != 'Open' && auth.isNotEmpty;

    bool isSaved = false;
    try {
      final profileResult = await Process.run('netsh', ['wlan', 'show', 'profiles', 'name="$ssid"']);
      isSaved = profileResult.exitCode == 0;
    } catch (_) {}

    if (!isSecure || isSaved) {
      await Process.run('netsh', ['wlan', 'connect', 'name="$ssid"']);
      if (mounted) Navigator.of(context).pop();
      return;
    }

    setState(() {
      if (_selectedSsidForPassword == ssid) {
        _selectedSsidForPassword = null; // Toggle off
      } else {
        _selectedSsidForPassword = ssid;
        _tempPassword = '';
      }
    });
  }

  Future<void> _submitPassword(String ssid) async {
    if (_tempPassword.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final xml =
          '''<?xml version="1.0"?>
<WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1">
    <name>$ssid</name>
    <SSIDConfig>
        <SSID>
            <name>$ssid</name>
        </SSID>
    </SSIDConfig>
    <connectionType>ESS</connectionType>
    <connectionMode>auto</connectionMode>
    <MSM>
        <security>
            <authEncryption>
                <authentication>WPA2PSK</authentication>
                <encryption>AES</encryption>
                <useOneX>false</useOneX>
            </authEncryption>
            <sharedKey>
                <keyType>passPhrase</keyType>
                <protected>false</protected>
                <keyMaterial>$_tempPassword</keyMaterial>
            </sharedKey>
        </security>
    </MSM>
</WLANProfile>''';

      final tempDir = Directory.systemTemp;
      final file = File('${tempDir.path}\\wifi_profile_$ssid.xml');
      await file.writeAsString(xml);

      await Process.run('netsh', [
        'wlan',
        'add',
        'profile',
        'filename="${file.path}"',
      ]);
      await Process.run('netsh', ['wlan', 'connect', 'name="$ssid"']);

      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // Connection error
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        _selectedSsidForPassword = null;
      });
      Navigator.of(context).pop();
    }
  }

  // Removed _showPasswordDialog

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      constraints: const BoxConstraints(maxHeight: 400),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.wifi_rounded,
                      color: Color(0xFF0F2942),
                      size: 22,
                    ),
                    SizedBox(width: 10),
                    Text(
                      "Wi-Fi Networks",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F2942),
                      ),
                    ),
                  ],
                ),
                if (_isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF0284C7),
                      ),
                    ),
                  )
                else
                  InkWell(
                    onTap: _scanNetworks,
                    borderRadius: BorderRadius.circular(20),
                    child: const Icon(
                      Icons.refresh_rounded,
                      size: 20,
                      color: Color(0xFF64748B),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          if (!_isLoading && _networks.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                "No networks found.",
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                shrinkWrap: true,
                itemCount: _networks.length,
                itemBuilder: (context, index) {
                  final network = _networks[index];
                  final ssid = network['ssid'] ?? 'Unknown';
                  final auth = network['auth'] ?? '';
                  final isSecure = auth != 'Open';

                  final isExpanded = _selectedSsidForPassword == ssid;

                  return Column(
                    children: [
                      InkWell(
                        onTap: () => _connectToNetwork(ssid, auth),
                        child: Container(
                          color: isExpanded ? const Color(0xFFF1F5F9) : Colors.transparent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSecure
                                    ? Icons.wifi_lock_rounded
                                    : Icons.wifi_rounded,
                                color: const Color(0xFF0F2942),
                                size: 20,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ssid,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF0F2942),
                                      ),
                                    ),
                                    if (isSecure)
                                      const Text(
                                        "Secured",
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (isExpanded)
                        Container(
                          color: const Color(0xFFF1F5F9),
                          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextField(
                                obscureText: true,
                                autofocus: true,
                                style: const TextStyle(fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: 'Enter network password',
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF0284C7),
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                                onChanged: (val) => _tempPassword = val,
                                onSubmitted: (_) => _submitPassword(ssid),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () => setState(() => _selectedSsidForPassword = null),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text(
                                      "Cancel",
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: () => _submitPassword(ssid),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0284C7),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text(
                                      "Connect",
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
