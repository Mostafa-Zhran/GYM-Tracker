import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:Gym/features/auth/providers/auth_provider.dart';
import 'package:Gym/core/navigation/app_router.dart';

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

class GymLoginPage extends ConsumerStatefulWidget {
  const GymLoginPage({super.key});

  @override
  ConsumerState<GymLoginPage> createState() => _GymLoginPageState();
}

class _GymLoginPageState extends ConsumerState<GymLoginPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _emailFocused = false;
  bool _passwordFocused = false;

  // ── Animation Controllers ─────────────────────────────────────────────────
  late final AnimationController _fadeController;
  late final AnimationController _slideController;
  late final AnimationController _pulseController;
  late final AnimationController _particleController;

  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _pulseAnim;

  final List<Particle> _particles = [];

  @override
  void initState() {
    super.initState();

    // Initialize particles
    _initParticles();

    // Primary animation - page entrance
    _fadeController = AnimationController(
      vsync: this,
      duration: AppAnimation.primaryDuration,
    );
    _fadeAnim = CurvedAnimation(
      parent: _fadeController,
      curve: AppAnimation.primaryCurve,
    );

    // Secondary animation - slide up
    _slideController = AnimationController(
      vsync: this,
      duration: AppAnimation.secondaryDuration,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: AppAnimation.secondaryCurve,
    ));

    // Micro animation - subtle pulse for badge
    _pulseController = AnimationController(
      vsync: this,
      duration: AppAnimation.verySlow,
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: AppAnimation.easeInOut),
    );

    // Background animation - very slow ambient motion
    _particleController = AnimationController(
      vsync: this,
      duration: AppAnimation.micro,
    )..repeat();

    // Staggered animations for smooth entrance
    Future.delayed(AppAnimation.micro, () => _fadeController.forward());
    Future.delayed(AppAnimation.fast, () => _slideController.forward());
  }

  void _initParticles() {
    for (int i = 0; i < 30; i++) {
      _particles.add(Particle.random());
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Haptic feedback
    HapticFeedback.lightImpact();
    
    await ref.read(authStateProvider.notifier).login(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Stack(
        children: [
          // ── Background ─────────────────────────────────────────────────
          RepaintBoundary(
            child: _BackgroundDecoration(size: size),
          ),

          SafeArea(
            child: RepaintBoundary(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: RepaintBoundary(
                  child: SlideTransition(
                    position: _slideAnim,
                    child: SingleChildScrollView(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Top Badge ───────────────────────────────────
                            RepaintBoundary(
                              child: _TopBadge(pulseAnim: _pulseAnim),
                            ),

                            const SizedBox(height: 40),

                            // ── Headline ────────────────────────────────────
                            const _Headline(),

                            const SizedBox(height: 52),

                            // ── Email ───────────────────────────────────────
                            RepaintBoundary(
                              child: _GymTextField(
                                controller: _emailController,
                                label: 'Email Address',
                                hint: 'you@example.com',
                                icon: Icons.alternate_email_rounded,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                isFocused: _emailFocused,
                                onFocusChange: (v) {
                                  setState(() => _emailFocused = v);
                                  if (v) HapticFeedback.lightImpact();
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Email is required';
                                  }
                                  if (!value.contains('@')) {
                                    return 'Enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                            ),

                            const SizedBox(height: 24),

                            // ── Password ────────────────────────────────────
                            RepaintBoundary(
                              child: _GymTextField(
                                controller: _passwordController,
                                label: 'Password',
                                hint: '••••••••',
                                icon: Icons.lock_outline_rounded,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                isFocused: _passwordFocused,
                                onFocusChange: (v) {
                                  setState(() => _passwordFocused = v);
                                  if (v) HapticFeedback.lightImpact();
                                },
                                onFieldSubmitted: (_) => _handleLogin(),
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
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Password is required';
                                  }
                                  if (value.length < 6) {
                                    return 'Minimum 6 characters';
                                  }
                                  return null;
                                },
                              ),
                            ),

                            const SizedBox(height: 16),

                            // ── Forgot Password ─────────────────────────────
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  'Forgot password?',
                                  style: TextStyle(
                                    color: Color(0xFFFF6B35),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),

                            // ── Error Banner ────────────────────────────────
                            if (authState.error != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 20),
                                child: _ErrorBanner(message: authState.error!),
                              ),

                            const SizedBox(height: 40),

                            // ── Sign In Button ──────────────────────────────
                            RepaintBoundary(
                              child: _SignInButton(
                                isLoading: authState.isLoading,
                                onPressed: _handleLogin,
                              ),
                            ),

                            const SizedBox(height: 20),

                            // ── Register Link ───────────────────────────────
                            _RegisterLink(
                              onTap: () => context.push(AppRoutes.register),
                            ),

                            const SizedBox(height: 32),

                            // ── Divider ─────────────────────────────────────
                            const _OrDivider(),

                            const SizedBox(height: 32),

                            // ── Stats Row ───────────────────────────────────
                            const _StatsRow(),

                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
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

// ── Background Decoration ─────────────────────────────────────────────────

class _BackgroundDecoration extends StatelessWidget {
  final Size size;
  const _BackgroundDecoration({required this.size});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ── Animated Gradient Orbs ─────────────────────────────
        Positioned(
          top: -100,
          right: -80,
          child: _AnimatedOrb(
            size: 320,
            color: const Color(0xFFFF6B35),
            opacity: 0.22,
          ),
        ),
        Positioned(
          bottom: -120,
          left: -100,
          child: _AnimatedOrb(
            size: 380,
            color: const Color(0xFF3B82F6),
            opacity: 0.15,
          ),
        ),
        Positioned(
          top: size.height * 0.4,
          left: -60,
          child: _AnimatedOrb(
            size: 200,
            color: const Color(0xFF8B5CF6),
            opacity: 0.1,
          ),
        ),
        
        // ── Grid Background ───────────────────────────────────
        CustomPaint(size: size, painter: _GridPainter()),
      ],
    );
  }
}

// ── Animated Orb ────────────────────────────────────────────────────────────

class _AnimatedOrb extends StatefulWidget {
  final double size;
  final Color color;
  final double opacity;
  const _AnimatedOrb({
    required this.size,
    required this.color,
    required this.opacity,
  });

  @override
  State<_AnimatedOrb> createState() => _AnimatedOrbState();
}

class _AnimatedOrbState extends State<_AnimatedOrb>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimation.verySlow * 3, // Much slower for subtle effect
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: AppAnimation.easeInOut),
    );
    _opacity = Tween<double>(begin: widget.opacity * 0.8, end: widget.opacity)
        .animate(CurvedAnimation(parent: _controller, curve: AppAnimation.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scale.value,
          child: Opacity(
            opacity: _opacity.value,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  widget.color.withOpacity(_opacity.value),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.02)
      ..strokeWidth = 1;
    const spacing = 56.0;
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

// ── Top Badge ─────────────────────────────────────────────────────────────

class _TopBadge extends StatelessWidget {
  final Animation<double> pulseAnim;
  const _TopBadge({
    required this.pulseAnim,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ScaleTransition(
          scale: pulseAnim,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFF6B35), Color(0xFFFF3B30)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6B35).withOpacity(0.5),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: const Color(0xFFFF6B35).withOpacity(0.3),
                  blurRadius: 40,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
            child: const Icon(Icons.fitness_center_rounded,
                color: Colors.white, size: 32),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'GYM COACH',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.8,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B35).withOpacity(0.18),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: const Color(0xFFFF6B35).withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: const Text(
                  'PRO PLATFORM',
                  style: TextStyle(
                    color: Color(0xFFFF6B35),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.8,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Headline ──────────────────────────────────────────────────────────────

class _Headline extends StatelessWidget {
  const _Headline();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFFFFFFF), Color(0xFFBBBBBB)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(bounds),
          child: const Text(
            'PUSH YOUR',
            style: TextStyle(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
              height: 1.15,
            ),
          ),
        ),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFFF6B35), Color(0xFFFF3B30)],
          ).createShader(bounds),
          child: const Text(
            'LIMITS.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
              height: 1.15,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Sign in to access your coaching dashboard\nand track your performance.',
          style: TextStyle(
            color: Color(0xFF9CA3AF),
            fontSize: 15,
            height: 1.6,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

// ── Gym Text Field ────────────────────────────────────────────────────────

class _GymTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool isFocused;
  final ValueChanged<bool> onFocusChange;
  final ValueChanged<String>? onFieldSubmitted;
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

// ── Error Banner ──────────────────────────────────────────────────────────

class _ErrorBanner extends StatefulWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  State<_ErrorBanner> createState() => _ErrorBannerState();
}

class _ErrorBannerState extends State<_ErrorBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideIn = Tween<double>(begin: -1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, -0.5), end: Offset.zero)
          .animate(_slideIn),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFEF4444).withOpacity(0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFEF4444).withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.error_outline_rounded,
                  color: Color(0xFFEF4444), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.message,
                style: const TextStyle(
                  color: Color(0xFFEF4444),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sign In Button ────────────────────────────────────────────────────────

class _SignInButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onPressed;
  const _SignInButton({required this.isLoading, required this.onPressed});

  @override
  State<_SignInButton> createState() => _SignInButtonState();
}

class _SignInButtonState extends State<_SignInButton>
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
          if (!widget.isLoading) widget.onPressed();
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
                          Text(
                            'SIGN IN',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.2,
                            ),
                          ),
                          SizedBox(width: 12),
                          Icon(Icons.arrow_forward_rounded,
                              color: Colors.white, size: 20),
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

// ── Register Link ─────────────────────────────────────────────────────────
// ✅ ADDED — takes user to registration page

class _RegisterLink extends StatefulWidget {
  final VoidCallback onTap;
  const _RegisterLink({required this.onTap});

  @override
  State<_RegisterLink> createState() => _RegisterLinkState();
}

class _RegisterLinkState extends State<_RegisterLink>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) {
          _controller.reverse();
          widget.onTap();
        },
        onTapCancel: () => _controller.reverse(),
        child: ScaleTransition(
          scale: _scale,
          child: RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: "Don't have an account? ",
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                TextSpan(
                  text: 'Sign Up',
                  style: TextStyle(
                    color: Color(0xFFFF6B35),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── OR Divider ────────────────────────────────────────────────────────────

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Color(0xFF1F2937)],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'PLATFORM STATS',
            style: TextStyle(
              color: Colors.white.withOpacity(0.2),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1F2937), Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Stats Row ─────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatItem(value: '2.4K', label: 'Athletes'),
        _StatDivider(),
        _StatItem(value: '180+', label: 'Coaches'),
        _StatDivider(),
        _StatItem(value: '98%', label: 'Satisfaction'),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFFFF6B35), Color(0xFFFFAA80)],
            ).createShader(bounds),
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF4B5563),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            const Color(0xFF1F2937),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

// ── Particle Class for Background Animation ─────────────────────────────────

class Particle {
  double x;
  double y;
  double size;
  double speedX;
  double speedY;
  double opacity;

  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speedX,
    required this.speedY,
    required this.opacity,
  });

  factory Particle.random() {
    final random = math.Random();
    return Particle(
      x: random.nextDouble() * 400,
      y: random.nextDouble() * 800,
      size: random.nextDouble() * 3 + 1,
      speedX: (random.nextDouble() - 0.5) * 0.5,
      speedY: (random.nextDouble() - 0.5) * 0.5,
      opacity: random.nextDouble() * 0.3 + 0.1,
    );
  }

  void update() {
    x += speedX;
    y += speedY;
    if (x < 0 || x > 400) speedX *= -1;
    if (y < 0 || y > 800) speedY *= -1;
  }
}
