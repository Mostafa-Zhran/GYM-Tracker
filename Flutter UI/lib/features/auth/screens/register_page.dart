import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../data/auth_repository.dart';
import 'package:Gym/core/navigation/app_router.dart';
import 'dart:math' as math;

// ── Unified Animation System ─────────────────────────────────────────────────────
// Motion hierarchy: Primary > Secondary > Micro
class AppAnimation {
  // Durations
  static const Duration instant = Duration(milliseconds: 50);
  static const Duration micro = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration verySlow = Duration(milliseconds: 600);

  // Curves
  static const Curve ease = Curves.ease;
  static const Curve easeIn = Curves.easeIn;
  static const Curve easeOut = Curves.easeOut;
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve easeOutCubic = Curves.easeOutCubic;
  static const Curve easeInOutCubic = Curves.easeInOutCubic;
  static const Curve easeOutBack = Curves.easeOutBack;
  static const Curve easeInOutBack = Curves.easeInOutBack;
  static const Curve bounceIn = Curves.bounceIn;
  static const Curve bounceOut = Curves.bounceOut;

  // Animation hierarchy - static properties instead of nested classes
  static const Duration primaryDuration = slow;
  static const Curve primaryCurve = easeOutCubic;
  
  static const Duration secondaryDuration = medium;
  static const Curve secondaryCurve = easeOutCubic;
  
  static const Duration microDuration = fast;
  static const Curve microCurve = easeOut;
}

class GymRegisterPage extends ConsumerStatefulWidget {
  const GymRegisterPage({super.key});

  @override
  ConsumerState<GymRegisterPage> createState() => _GymRegisterPageState();
}

class _GymRegisterPageState extends ConsumerState<GymRegisterPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _userNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPassController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  // Always Trainee — no role selector
  final String _selectedRole = 'Trainee';

  bool _userNameFocused = false;
  bool _emailFocused = false;
  bool _passwordFocused = false;
  bool _confirmFocused = false;

  // ── FIX: track password text for strength bar ─────────────────────────
  String _passwordText = '';

  late final AnimationController _fadeCtrl;
  late final AnimationController _slideCtrl;
  late final AnimationController _pulseCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _pulseAnim;

  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: AppAnimation.primaryDuration);
    _slideCtrl = AnimationController(
        vsync: this, duration: AppAnimation.secondaryDuration);
    _pulseCtrl = AnimationController(
        vsync: this, duration: AppAnimation.verySlow)
      ..repeat(reverse: true);

    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: AppAnimation.primaryCurve);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: AppAnimation.secondaryCurve));
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.06)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: AppAnimation.easeInOut));

    _fadeCtrl.forward();
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _userNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPassController.dispose();
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Step 1: Register the trainee account
      await ref.read(authRepositoryProvider).register(
            userName: _userNameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
            confirmPassword: _confirmPassController.text.trim(),
            role: _selectedRole,
          );

      // Step 2: Auto-login to obtain the real trainee ID from the server
      // ── FIX: traineeId was always '' before this step ─────────────────
      final user = await ref.read(authRepositoryProvider).login(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      // Step 3: Navigate to coach selection with the real ID
      if (mounted) {
        context.push(
          AppRoutes.selectCoach,
          extra: {
            'traineeId': user.id, // ✅ real ID from login response
            'traineeName': user.name, // ✅ userName from server
          },
        );
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Stack(
        children: [
          _BackgroundDecoration(size: size),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _TopBadge(pulseAnim: _pulseAnim),
                        const SizedBox(height: 32),
                        const _Headline(),
                        const SizedBox(height: 36),

                        // ── Username ────────────────────────────────
                        _GymTextField(
                          controller: _userNameController,
                          label: 'Username',
                          hint: 'e.g. john_smith',
                          icon: Icons.person_outline_rounded,
                          isFocused: _userNameFocused,
                          onFocusChange: (v) {
                            setState(() => _userNameFocused = v);
                            if (v) HapticFeedback.lightImpact();
                          },
                          textInputAction: TextInputAction.next,
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Username is required';
                            }
                            if (v.length < 3) return 'Minimum 3 characters';
                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        // ── Email ────────────────────────────────────
                        _GymTextField(
                          controller: _emailController,
                          label: 'Email Address',
                          hint: 'you@example.com',
                          icon: Icons.alternate_email_rounded,
                          keyboardType: TextInputType.emailAddress,
                          isFocused: _emailFocused,
                          onFocusChange: (v) {
                            setState(() => _emailFocused = v);
                            if (v) HapticFeedback.lightImpact();
                          },
                          textInputAction: TextInputAction.next,
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Email is required';
                            }
                            if (!v.contains('@')) {
                              return 'Enter a valid email';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        // ── Password ─────────────────────────────────
                        _GymTextField(
                          controller: _passwordController,
                          label: 'Password',
                          hint: '••••••••',
                          icon: Icons.lock_outline_rounded,
                          obscureText: _obscurePassword,
                          isFocused: _passwordFocused,
                          onFocusChange: (v) {
                            setState(() => _passwordFocused = v);
                            if (v) HapticFeedback.lightImpact();
                          },
                          textInputAction: TextInputAction.next,
                          onChanged: (v) => setState(() => _passwordText = v),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: const Color(0xFF6B7280),
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() => _obscurePassword = !_obscurePassword);
                              HapticFeedback.lightImpact();
                            },
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Password is required';
                            }
                            if (v.length < 6) return 'Minimum 6 characters';
                            return null;
                          },
                        ),

                        const SizedBox(height: 10),
                        _PasswordStrengthHint(password: _passwordText),

                        const SizedBox(height: 20),

                        // ── Confirm Password ─────────────────────────
                        _GymTextField(
                          controller: _confirmPassController,
                          label: 'Confirm Password',
                          hint: '••••••••',
                          icon: Icons.lock_outline_rounded,
                          obscureText: _obscureConfirm,
                          isFocused: _confirmFocused,
                          onFocusChange: (v) {
                            setState(() => _confirmFocused = v);
                            if (v) HapticFeedback.lightImpact();
                          },
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _handleRegister(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: const Color(0xFF6B7280),
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() => _obscureConfirm = !_obscureConfirm);
                              HapticFeedback.lightImpact();
                            },
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Please confirm your password';
                            }
                            if (v != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),

                        if (_error != null) ...[
                          const SizedBox(height: 20),
                          _ErrorBanner(message: _error!),
                        ],

                        const SizedBox(height: 32),

                        _RegisterButton(
                          isLoading: _isLoading,
                          onTap: _handleRegister,
                        ),

                        const SizedBox(height: 24),
                        _BackToLogin(onTap: () => context.pop()),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Background
// ─────────────────────────────────────────────────────────────────────────────

class _BackgroundDecoration extends StatelessWidget {
  final Size size;
  const _BackgroundDecoration({required this.size});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -80,
          right: -60,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                const Color(0xFFFF6B35).withOpacity(0.18),
                Colors.transparent,
              ]),
            ),
          ),
        ),
        Positioned(
          bottom: -100,
          left: -80,
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                const Color(0xFF3B82F6).withOpacity(0.12),
                Colors.transparent,
              ]),
            ),
          ),
        ),
        CustomPaint(size: size, painter: _GridPainter()),
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.025)
      ..strokeWidth = 1;
    const spacing = 48.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Top Badge
// ─────────────────────────────────────────────────────────────────────────────

class _TopBadge extends StatelessWidget {
  final Animation<double> pulseAnim;
  const _TopBadge({required this.pulseAnim});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ScaleTransition(
          scale: pulseAnim,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFF6B35), Color(0xFFFF3B30)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6B35).withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.fitness_center_rounded,
                color: Colors.white, size: 28),
          ),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'GYM COACH',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.5,
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 3),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B35).withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
                border:
                    Border.all(color: const Color(0xFFFF6B35).withOpacity(0.3)),
              ),
              child: const Text(
                'CREATE ACCOUNT',
                style: TextStyle(
                  color: Color(0xFFFF6B35),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Headline
// ─────────────────────────────────────────────────────────────────────────────

class _Headline extends StatelessWidget {
  const _Headline();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFFFFFFF), Color(0xFFAAAAAA)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(bounds),
          child: const Text(
            'START YOUR',
            style: TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              height: 1.1,
            ),
          ),
        ),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFFF6B35), Color(0xFFFF3B30)],
          ).createShader(bounds),
          child: const Text(
            'JOURNEY.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              height: 1.1,
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Create your trainee account and get\nmatched with the perfect coach.',
          style: TextStyle(
            color: Color(0xFF9CA3AF),
            fontSize: 14,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Text Field — Advanced version with smart animations
// ─────────────────────────────────────────────────────────────────────────────

class _GymTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool isFocused;
  final ValueChanged<bool> onFocusChange;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final ValueChanged<String>? onChanged;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const _GymTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.isFocused,
    required this.onFocusChange,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onFieldSubmitted,
    this.onChanged,
    this.suffixIcon,
    this.validator,
  });

  @override
  State<_GymTextField> createState() => _GymTextFieldState();
}

class _GymTextFieldState extends State<_GymTextField>
    with SingleTickerProviderStateMixin {
  bool _hasText = false;
  String? _errorText;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    
    // Shake animation for errors
    _shakeController = AnimationController(
      vsync: this,
      duration: AppAnimation.medium,
    );
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: AppAnimation.easeOutBack),
    );
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _shakeController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
    if (widget.onChanged != null) {
      widget.onChanged!(widget.controller.text);
    }
    // Trigger shake when error appears
    if (_errorText != null && hasText) {
      _shakeController.forward().then((_) => _shakeController.reverse());
    }
  }

  @override
  void didUpdateWidget(_GymTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Trigger shake when error state changes
    if (_errorText != null && oldWidget.isFocused && !widget.isFocused) {
      _shakeController.forward().then((_) => _shakeController.reverse());
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasError = _errorText != null;
    final borderRadius = BorderRadius.circular(18);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Floating label with fluid animation
        AnimatedOpacity(
          duration: AppAnimation.microDuration,
          curve: AppAnimation.microCurve,
          opacity: widget.isFocused || _hasText ? 1.0 : 0.7,
          child: Row(
            children: [
              Text(
                widget.label.toUpperCase(),
                style: TextStyle(
                  color: widget.isFocused
                      ? const Color(0xFFFF6B35)
                      : hasError
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF6B7280),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.6,
                ),
              ),
              if (widget.obscureText && _hasText) ...[
                const SizedBox(width: 8),
                // Typing indicator with color transition
                AnimatedDefaultTextStyle(
                  duration: AppAnimation.microDuration,
                  curve: AppAnimation.microCurve,
                  style: TextStyle(
                    color: widget.controller.text.length >= 6
                        ? const Color(0xFF10B981)
                        : const Color(0xFF6B7280),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                  child: Text('${widget.controller.text.length}/6+'),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Shake animation wrapper
        AnimatedBuilder(
          animation: _shakeAnim,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(
                math.sin(_shakeAnim.value * math.pi * 4) * 8 * (1 - _shakeAnim.value),
                0,
              ),
              child: Focus(
                onFocusChange: widget.onFocusChange,
                child: AnimatedContainer(
                  duration: AppAnimation.secondaryDuration,
                  curve: AppAnimation.secondaryCurve,
                  decoration: BoxDecoration(
                    borderRadius: borderRadius,
                    // Gradient border on focus
                    gradient: widget.isFocused
                        ? LinearGradient(
                            colors: [
                              const Color(0xFFFF6B35),
                              const Color(0xFFFF3B30),
                              const Color(0xFFFF6B35),
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          )
                        : null,
                    // Solid border for non-focused state
                    border: widget.isFocused
                        ? null
                        : Border.all(
                            color: hasError
                                ? const Color(0xFFEF4444).withOpacity(0.6)
                                : const Color(0xFF1F2937),
                            width: 1.5,
                          ),
                    // Enhanced shadows with glow effect
                    boxShadow: widget.isFocused
                        ? [
                            BoxShadow(
                              color: const Color(0xFFFF6B35).withOpacity(0.15),
                              blurRadius: 24,
                              spreadRadius: 0,
                            ),
                            BoxShadow(
                              color: const Color(0xFFFF6B35).withOpacity(0.08),
                              blurRadius: 48,
                              spreadRadius: -8,
                            ),
                          ]
                        : hasError
                            ? [
                                BoxShadow(
                                  color: const Color(0xFFEF4444).withOpacity(0.15),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.25),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                  ),
                  child: Container(
                    // Inner container with padding for gradient border
                    padding: widget.isFocused ? const EdgeInsets.all(2) : EdgeInsets.zero,
                    decoration: BoxDecoration(
                      borderRadius: borderRadius,
                      color: const Color(0xFF111827),
                    ),
                    child: TextFormField(
                      controller: widget.controller,
                      obscureText: widget.obscureText,
                      keyboardType: widget.keyboardType,
                      textInputAction: widget.textInputAction,
                      onFieldSubmitted: widget.onFieldSubmitted,
                      validator: (value) {
                        final result = widget.validator?.call(value);
                        setState(() => _errorText = result);
                        if (result != null) {
                          _shakeController.forward().then((_) => _shakeController.reverse());
                        }
                        return result;
                      },
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                      cursorColor: widget.isFocused
                          ? const Color(0xFFFF6B35)
                          : const Color(0xFF6B7280),
                      cursorWidth: 2.5,
                      cursorHeight: 20,
                      decoration: InputDecoration(
                        hintText: widget.hint,
                        hintStyle: TextStyle(
                          color: const Color(0xFF374151).withOpacity(0.8),
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                        ),
                        // Enhanced icon container with animation
                        prefixIcon: AnimatedContainer(
                          duration: AppAnimation.microDuration,
                          curve: AppAnimation.microCurve,
                          margin: const EdgeInsets.only(left: 6, right: 8, top: 8, bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: widget.isFocused
                                ? const Color(0xFFFF6B35).withOpacity(0.12)
                                : hasError
                                    ? const Color(0xFFEF4444).withOpacity(0.1)
                                    : const Color(0xFF1F2937).withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: widget.isFocused
                                  ? const Color(0xFFFF6B35).withOpacity(0.3)
                                  : Colors.transparent,
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            widget.icon,
                            color: widget.isFocused
                                ? const Color(0xFFFF6B35)
                                : hasError
                                    ? const Color(0xFFEF4444)
                                    : const Color(0xFF6B7280),
                            size: 20,
                          ),
                        ),
                        prefixIconConstraints: const BoxConstraints(minWidth: 56, minHeight: 56),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Success validation icon with pulse
                            if (_hasText && !hasError)
                              TweenAnimationBuilder<double>(
                                duration: AppAnimation.slow,
                                tween: Tween(begin: 0.8, end: 1.2),
                                builder: (context, scale, child) {
                                  return Transform.scale(
                                    scale: scale,
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 12),
                                      child: Icon(
                                        Icons.check_circle_rounded,
                                        color: const Color(0xFF10B981),
                                        size: 20,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            if (widget.suffixIcon != null) widget.suffixIcon!,
                          ],
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        errorStyle: const TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 12,
                          height: 0,
                          fontWeight: FontWeight.w500,
                        ),
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Password Strength Hint
// ─────────────────────────────────────────────────────────────────────────────

class _PasswordStrengthHint extends StatelessWidget {
  final String password;
  const _PasswordStrengthHint({required this.password});

  String get _label {
    if (password.isEmpty) return '';
    if (password.length < 6) return 'Weak';
    if (password.length < 10) return 'Fair';
    return 'Strong';
  }

  Color get _color {
    if (password.isEmpty) return Colors.transparent;
    if (password.length < 6) return const Color(0xFFEF4444);
    if (password.length < 10) return const Color(0xFFFF6B35);
    return const Color(0xFF10B981);
  }

  double get _fraction {
    if (password.isEmpty) return 0;
    if (password.length < 6) return 0.33;
    if (password.length < 10) return 0.66;
    return 1.0;
  }

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) => Stack(
            children: [
              Container(
                height: 3,
                width: constraints.maxWidth,
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2937),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 3,
                width: constraints.maxWidth * _fraction,
                decoration: BoxDecoration(
                  color: _color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Password strength: $_label',
          style: TextStyle(
            color: _color,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error Banner
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Color(0xFFEF4444), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFEF4444),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Register Button — Advanced interaction
// ─────────────────────────────────────────────────────────────────────────────

class _RegisterButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onTap;
  const _RegisterButton({required this.isLoading, required this.onTap});

  @override
  State<_RegisterButton> createState() => _RegisterButtonState();
}

class _RegisterButtonState extends State<_RegisterButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _shadowAnim;
  late final Animation<double> _rippleAnim;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: AppAnimation.microDuration,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _pressController, curve: AppAnimation.microCurve),
    );
    _shadowAnim = Tween<double>(begin: 1.0, end: 0.7).animate(
      CurvedAnimation(parent: _pressController, curve: AppAnimation.microCurve),
    );
    _rippleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pressController, curve: AppAnimation.easeOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: GestureDetector(
        onTapDown: (_) {
          setState(() => _isPressed = true);
          _pressController.forward();
          HapticFeedback.lightImpact();
        },
        onTapUp: (_) {
          setState(() => _isPressed = false);
          _pressController.reverse();
          if (!widget.isLoading) widget.onTap();
        },
        onTapCancel: () {
          setState(() => _isPressed = false);
          _pressController.reverse();
        },
        child: AnimatedContainer(
          duration: AppAnimation.secondaryDuration,
          curve: AppAnimation.secondaryCurve,
          width: double.infinity,
          height: 58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.isLoading
                  ? [
                      const Color(0xFFFF6B35).withOpacity(0.6),
                      const Color(0xFFFF3B30).withOpacity(0.6),
                    ]
                  : [
                      const Color(0xFFFF6B35),
                      const Color(0xFFFF3B30),
                    ],
            ),
            boxShadow: _isPressed || widget.isLoading
                ? [
                    BoxShadow(
                      color: const Color(0xFFFF6B35).withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: const Color(0xFFFF6B35).withOpacity(0.5),
                      blurRadius: 28,
                      offset: const Offset(0, 12),
                    ),
                    BoxShadow(
                      color: const Color(0xFFFF6B35).withOpacity(0.3),
                      blurRadius: 48,
                      offset: const Offset(0, 0),
                    ),
                  ],
          ),
          child: Stack(
            children: [
              // Ripple effect
              if (_isPressed)
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _rippleAnim,
                    builder: (context, child) {
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          color: Colors.white.withOpacity(0.1 * (1 - _rippleAnim.value)),
                        ),
                      );
                    },
                  ),
                ),
              // Button content
              Center(
                child: widget.isLoading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.rocket_launch_rounded,
                              color: Colors.white, size: 20),
                          SizedBox(width: 12),
                          Text(
                            'CREATE ACCOUNT',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.2,
                            ),
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Back to Login
// ─────────────────────────────────────────────────────────────────────────────

class _BackToLogin extends StatelessWidget {
  final VoidCallback onTap;
  const _BackToLogin({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'Already have an account? ',
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
              ),
              TextSpan(
                text: 'Sign In',
                style: TextStyle(
                  color: Color(0xFFFF6B35),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
