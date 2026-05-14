// lib/screens/auth/pin_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_router.dart';

class PinScreen extends ConsumerStatefulWidget {
  final bool isSetup;
  const PinScreen({super.key, required this.isSetup});

  @override
  ConsumerState<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends ConsumerState<PinScreen>
    with SingleTickerProviderStateMixin {
  static const _pinKey = 'iponko_pin';
  static const _pinLength = 4;

  String _pin = '';
  String _confirmPin = '';
  bool _isConfirming = false;
  bool _hasError = false;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onKeyTap(String key) {
    if (key == '⌫') {
      _onDelete();
      return;
    }
    final current = _isConfirming ? _confirmPin : _pin;
    if (current.length >= _pinLength) return;

    setState(() {
      _hasError = false;
      if (_isConfirming) {
        _confirmPin += key;
      } else {
        _pin += key;
      }
    });

    final updated = _isConfirming ? _confirmPin : _pin;
    if (updated.length == _pinLength) {
      Future.delayed(const Duration(milliseconds: 120), () {
        if (mounted) _onPinComplete(updated);
      });
    }
  }

  void _onDelete() {
    setState(() {
      _hasError = false;
      if (_isConfirming) {
        if (_confirmPin.isNotEmpty) {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        }
      } else {
        if (_pin.isNotEmpty) {
          _pin = _pin.substring(0, _pin.length - 1);
        }
      }
    });
  }

  Future<void> _onPinComplete(String enteredPin) async {
    if (widget.isSetup) {
      if (!_isConfirming) {
        // First entry — ask to confirm
        setState(() {
          _isConfirming = true;
          _confirmPin = '';
        });
      } else {
        // Second entry — check match
        if (_pin == _confirmPin) {
          await _savePin(_pin);
          if (mounted) _goToDashboard();
        } else {
          _showError();
          setState(() {
            _isConfirming = false;
            _pin = '';
            _confirmPin = '';
          });
        }
      }
    } else {
      // Login mode — check against saved PIN
      final saved = await _getSavedPin();
      if (saved == null) {
        // No PIN set — go straight to dashboard
        if (mounted) _goToDashboard();
        return;
      }
      if (enteredPin == saved) {
        if (mounted) _goToDashboard();
      } else {
        _showError();
        setState(() => _pin = '');
      }
    }
  }

  Future<void> _savePin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pinKey, pin);
  }

  Future<String?> _getSavedPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_pinKey);
  }

  void _showError() {
    setState(() => _hasError = true);
    _shakeController.forward(from: 0);
  }

  void _goToDashboard() async {
    final repo = ref.read(repositoryProvider);
    final user = await repo.getCurrentUser();
    if (mounted) {
      if (user?.isParent == true) {
        context.go(AppRoutes.parentDashboard);
      } else {
        context.go(AppRoutes.studentDashboard);
      }
    }
  }

  String get _currentPin => _isConfirming ? _confirmPin : _pin;

  String get _title {
    if (widget.isSetup) {
      return _isConfirming ? 'Ulitin ang PIN' : 'Gumawa ng PIN';
    }
    return 'I-enter ang PIN';
  }

  String get _subtitle {
    if (widget.isSetup) {
      return _isConfirming
          ? 'I-type ulit ang iyong 4-digit PIN'
          : 'Piliin ang iyong 4-digit na PIN para sa mabilis na login';
    }
    return 'I-enter ang iyong PIN para pumasok';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.philippineBlue,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),

            // ── Back button (login mode only) ──────────────────────────
            if (!widget.isSetup)
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white),
                  onPressed: () => context.go(AppRoutes.splash),
                ),
              ),

            const Spacer(),

            // ── Logo + Title ───────────────────────────────────────────
            const Text('🐷', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              _title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                _subtitle,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 40),

            // ── PIN Dots ───────────────────────────────────────────────
            AnimatedBuilder(
              animation: _shakeAnimation,
              builder: (_, child) {
                final offset =
                    _hasError ? 8 * (0.5 - _shakeAnimation.value).abs() : 0.0;
                return Transform.translate(
                  offset: Offset(offset * 10, 0),
                  child: child,
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pinLength, (i) {
                  final filled = i < _currentPin.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _hasError
                          ? AppColors.error
                          : filled
                              ? AppColors.philippineYellow
                              : Colors.white.withOpacity(0.3),
                      border: Border.all(
                        color: _hasError
                            ? AppColors.error
                            : Colors.white.withOpacity(0.5),
                        width: 1.5,
                      ),
                    ),
                  );
                }),
              ),
            ),

            if (_hasError) ...[
              const SizedBox(height: 12),
              Text(
                widget.isSetup
                    ? 'Hindi magkatugma! Subukan ulit.'
                    : 'Maling PIN! Subukan ulit.',
                style: const TextStyle(
                    color: AppColors.philippineYellow,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
            ],

            const Spacer(),

            // ── Keypad ─────────────────────────────────────────────────
            _Keypad(onKeyTap: _onKeyTap),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── Keypad ────────────────────────────────────────────────────────────────────

class _Keypad extends StatelessWidget {
  final ValueChanged<String> onKeyTap;

  const _Keypad({required this.onKeyTap});

  static const _keys = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['', '0', '⌫'],
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        children: _keys.map((row) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: row.map((key) {
                if (key.isEmpty) return const SizedBox(width: 72);
                return _KeyButton(label: key, onTap: () => onKeyTap(key));
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _KeyButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _KeyButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDelete = label == '⌫';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(isDelete ? 0.08 : 0.15),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: isDelete ? 22 : 26,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
