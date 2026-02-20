import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/biometric_service.dart';
import '../../../../core/database/database_provider.dart';
import 'package:sada/l10n/generated/app_localizations.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  bool _isAuthenticating = false;
  String _enteredPin = '';
  final int _maxPinLength = AuthService.pinLength;
  bool _showPinPad = false;
  int _lockoutSecondsRemaining = 0;
  Timer? _lockoutTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryBiometricAuth();
      _syncLockoutState();
    });
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    super.dispose();
  }

  Future<void> _syncLockoutState() async {
    final authService = ref.read(authServiceProvider.notifier);
    final remaining = await authService.getRemainingLockoutSeconds();
    if (!mounted) return;

    setState(() {
      _lockoutSecondsRemaining = remaining;
    });

    _lockoutTimer?.cancel();
    if (remaining > 0) {
      _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        if (_lockoutSecondsRemaining <= 1) {
          timer.cancel();
          setState(() {
            _lockoutSecondsRemaining = 0;
          });
          return;
        }

        setState(() {
          _lockoutSecondsRemaining--;
        });
      });
    }
  }

  Future<void> _tryBiometricAuth() async {
    if (_isAuthenticating) return;

    final biometricState = ref.read(biometricServiceProvider);
    if (!biometricState.isAvailable) {
      setState(() {
        _showPinPad = true;
      });
      return;
    }

    setState(() {
      _isAuthenticating = true;
    });

    final biometricService = ref.read(biometricServiceProvider.notifier);
    final l10n = AppLocalizations.of(context)!;

    final success = await biometricService.authenticate(
      reason: l10n.scanFingerprintToEnter,
    );

    if (!mounted) return;

    setState(() {
      _isAuthenticating = false;
    });

    if (success) {
      await _handleSuccessfulAuth(AuthType.master);
    } else {
      setState(() {
        _showPinPad = true;
      });
    }
  }

  void _onPinDigitPressed(String digit) {
    if (_lockoutSecondsRemaining > 0 || _isAuthenticating) return;

    if (_enteredPin.length < _maxPinLength) {
      setState(() {
        _enteredPin += digit;
      });

      if (_enteredPin.length == _maxPinLength) {
        _verifyPin();
      }
    }
  }

  void _onPinBackspace() {
    if (_lockoutSecondsRemaining > 0 || _isAuthenticating) return;

    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      });
    }
  }

  Future<void> _verifyPin() async {
    if (_isAuthenticating || _lockoutSecondsRemaining > 0) return;
    if (_enteredPin.length != _maxPinLength) return;

    setState(() {
      _isAuthenticating = true;
    });

    final authService = ref.read(authServiceProvider.notifier);
    final authType = await authService.verifyPin(_enteredPin);

    if (!mounted) return;

    setState(() {
      _isAuthenticating = false;
    });

    if (authType == AuthType.failure) {
      setState(() {
        _enteredPin = '';
      });
      HapticFeedback.heavyImpact();
      await _syncLockoutState();
    } else {
      await _handleSuccessfulAuth(authType);
    }
  }

  Future<void> _handleSuccessfulAuth(AuthType authType) async {
    try {
      ref.read(currentAuthTypeProvider.notifier).state = authType;
      final dbInitializer = ref.read(databaseInitializerProvider);
      await dbInitializer.initializeDatabase(authType);

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) {
            return Container();
          },
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );

      context.go(AppRoutes.home);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في تهيئة قاعدة البيانات: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final biometricState = ref.watch(biometricServiceProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primaryContainer,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_showPinPad && _lockoutSecondsRemaining > 0)
                    Padding(
                      padding: EdgeInsets.only(bottom: 16.h),
                      child: Text(
                        'محاولات كثيرة. حاول بعد ${_lockoutSecondsRemaining}s',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  Container(
                    width: 120.w,
                    height: 120.h,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onPrimary.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock_outline,
                      size: 64.sp,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                  SizedBox(height: 32.h),
                  Text(
                    l10n.sadaIsLocked,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    l10n.unlockToContinue,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontSize: 16.sp,
                      color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 48.h),
                  if (_showPinPad)
                    _buildPinDots()
                        .animate(target: _enteredPin.isEmpty ? 0 : 1)
                        .shake(
                          duration: const Duration(milliseconds: 500),
                          hz: 4,
                          curve: Curves.easeInOut,
                        )
                  else
                    SizedBox(height: 24.h),
                  SizedBox(height: 24.h),
                  if (!_showPinPad && biometricState.isAvailable)
                    SizedBox(
                      width: double.infinity,
                      height: 56.h,
                      child: ElevatedButton.icon(
                        onPressed: _isAuthenticating ? null : _tryBiometricAuth,
                        icon: _isAuthenticating
                            ? SizedBox(
                                width: 20.w,
                                height: 20.h,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    theme.colorScheme.onPrimary,
                                  ),
                                ),
                              )
                            : Icon(Icons.fingerprint, size: 24.sp),
                        label: Text(
                          l10n.unlock,
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.onPrimary,
                          foregroundColor: theme.colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                      ),
                    ),
                  if (_showPinPad) ...[SizedBox(height: 32.h), _buildPinPad()],
                  if (!_showPinPad && biometricState.isAvailable)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _showPinPad = true;
                        });
                      },
                      child: Text(
                        l10n.enterPin,
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary.withValues(
                            alpha: 0.9,
                          ),
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPinDots() {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _maxPinLength,
        (index) => Container(
          width: 16.w,
          height: 16.h,
          margin: EdgeInsets.symmetric(horizontal: 8.w),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index < _enteredPin.length
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onPrimary.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }

  Widget _buildPinPad() {
    return Column(
      children: [
        for (int row = 0; row < 3; row++)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int col = 1; col <= 3; col++)
                  _buildPinButton('${row * 3 + col}'),
              ],
            ),
          ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPinButton('0'),
              _buildPinButton('', isBackspace: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPinButton(String digit, {bool isBackspace = false}) {
    final theme = Theme.of(context);
    final isDisabled = _lockoutSecondsRemaining > 0 || _isAuthenticating;

    return Container(
      width: 70.w,
      height: 70.h,
      margin: EdgeInsets.symmetric(horizontal: 8.w),
      child: Material(
        color: theme.colorScheme.onPrimary.withValues(alpha: 0.2),
        shape: const CircleBorder(),
        child: InkWell(
          key: isBackspace ? const Key('pin_backspace') : Key('pin_$digit'),
          onTap: isDisabled
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  if (isBackspace) {
                    _onPinBackspace();
                  } else {
                    _onPinDigitPressed(digit);
                  }
                },
          customBorder: const CircleBorder(),
          child: Center(
            child: isBackspace
                ? Icon(
                    Icons.backspace,
                    color: theme.colorScheme.onPrimary,
                    size: 24.sp,
                  )
                : Text(
                    digit,
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
