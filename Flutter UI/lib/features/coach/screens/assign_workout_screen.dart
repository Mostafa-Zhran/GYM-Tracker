import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:Gym/features/coach/models/trainee_model.dart';
import 'package:Gym/features/coach/providers/coach_provider.dart';

class AssignWorkoutScreen extends ConsumerStatefulWidget {
  final TraineeModel? preSelectedTrainee;
  const AssignWorkoutScreen({super.key, this.preSelectedTrainee});

  @override
  ConsumerState<AssignWorkoutScreen> createState() =>
      _AssignWorkoutScreenState();
}

class _AssignWorkoutScreenState extends ConsumerState<AssignWorkoutScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  TraineeModel? _selectedTrainee;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));

  bool _titleFocused = false;
  bool _descriptionFocused = false;

  // ── Same entrance animations as login + workout screen ───────────────────
  late final AnimationController _fadeCtrl;
  late final AnimationController _slideCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _selectedTrainee = widget.preSelectedTrainee;

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));

    _fadeCtrl.forward();
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        // Style date picker to match dark theme
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFFF6B35),
              onPrimary: Colors.white,
              surface: Color(0xFF111827),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTrainee == null) {
      _showSnack('Please select a trainee', isError: true);
      return;
    }

    await ref.read(assignWorkoutProvider.notifier).assign(
          traineeId: _selectedTrainee!.id,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          date: _selectedDate,
        );

    final state = ref.read(assignWorkoutProvider);
    if (state.isSuccess && mounted) {
      _showSnack('Workout assigned successfully!', isError: false);
      context.pop();
    }
  }

  void _showSnack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Text(msg,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ],
        ),
        backgroundColor:
            isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final assignState = ref.watch(assignWorkoutProvider);
    final traineesAsync = ref.watch(traineesProvider);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Stack(
        children: [
          // ── Same background as login + workout screen ──────────────────
          _BackgroundDecoration(size: size),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Column(
                  children: [
                    // ── Top Bar ──────────────────────────────────────────
                    _TopBar(onBack: () => context.pop()),

                    // ── Scrollable Form ──────────────────────────────────
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ── Page Headline ────────────────────────
                              const _PageHeadline(),
                              const SizedBox(height: 32),

                              // ── Select Trainee ───────────────────────
                              const _FieldLabel('Select Trainee'),
                              const SizedBox(height: 8),
                              traineesAsync.when(
                                loading: () => const _DropdownSkeleton(),
                                error: (e, _) => _ErrorChip(
                                    message: 'Could not load trainees'),
                                data: (trainees) => _TraineeDropdown(
                                  trainees: trainees,
                                  selected: _selectedTrainee,
                                  onChanged: (v) =>
                                      setState(() => _selectedTrainee = v),
                                ),
                              ),

                              const SizedBox(height: 24),

                              // ── Title ────────────────────────────────
                              const _FieldLabel('Workout Title'),
                              const SizedBox(height: 8),
                              _DarkTextField(
                                controller: _titleController,
                                hint: 'e.g. Upper Body Strength',
                                icon: Icons.fitness_center_rounded,
                                isFocused: _titleFocused,
                                onFocusChange: (v) =>
                                    setState(() => _titleFocused = v),
                                textInputAction: TextInputAction.next,
                                validator: (v) => (v == null || v.isEmpty)
                                    ? 'Title is required'
                                    : null,
                              ),

                              const SizedBox(height: 24),

                              // ── Description ──────────────────────────
                              const _FieldLabel('Description'),
                              const SizedBox(height: 8),
                              _DarkTextField(
                                controller: _descriptionController,
                                hint: 'Describe the workout plan...',
                                icon: Icons.notes_rounded,
                                isFocused: _descriptionFocused,
                                onFocusChange: (v) =>
                                    setState(() => _descriptionFocused = v),
                                maxLines: 4,
                                textInputAction: TextInputAction.newline,
                                validator: (v) => (v == null || v.isEmpty)
                                    ? 'Description is required'
                                    : null,
                              ),

                              const SizedBox(height: 24),

                              // ── Date Picker ──────────────────────────
                              const _FieldLabel('Workout Date'),
                              const SizedBox(height: 8),
                              _DatePickerField(
                                date: _selectedDate,
                                onTap: _pickDate,
                              ),

                              // ── Error ─────────────────────────────────
                              if (assignState.error != null) ...[
                                const SizedBox(height: 20),
                                _ErrorBanner(message: assignState.error!),
                              ],

                              const SizedBox(height: 36),

                              // ── Submit Button ─────────────────────────
                              _AssignButton(
                                isLoading: assignState.isLoading,
                                onTap: _submit,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Background (identical to login + workout pages) ───────────────────────

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
                const Color(0xFFFF6B35).withOpacity(0.15),
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
                const Color(0xFF3B82F6).withOpacity(0.10),
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

// ── Top Bar ───────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final VoidCallback onBack;
  const _TopBar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 24, 12),
      child: Row(
        children: [
          // Back button — same icon button style as other screens
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF1F2937)),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Color(0xFF9CA3AF), size: 15),
            ),
          ),

          const SizedBox(width: 14),

          // Same logo badge as login + workout
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFF6B35), Color(0xFFFF3B30)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6B35).withOpacity(0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.fitness_center_rounded,
                color: Colors.white, size: 18),
          ),

          const SizedBox(width: 10),

          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'GYM COACH',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.0,
                ),
              ),
              Text(
                'ASSIGN WORKOUT',
                style: TextStyle(
                  color: Color(0xFFFF6B35),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Page Headline (same ShaderMask style as login "PUSH YOUR / LIMITS.") ──

class _PageHeadline extends StatelessWidget {
  const _PageHeadline();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // White gradient line
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFFFFFFF), Color(0xFFAAAAAA)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(bounds),
          child: const Text(
            'BUILD THE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              height: 1.1,
            ),
          ),
        ),
        // Orange gradient line
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFFF6B35), Color(0xFFFF3B30)],
          ).createShader(bounds),
          child: const Text(
            'PERFECT PLAN.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              height: 1.1,
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Assign a tailored workout to your trainee\nand track their progress.',
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

// ── Field Label (ALL-CAPS, same as login field labels) ────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: Color(0xFF6B7280),
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
      ),
    );
  }
}

// ── Dark Text Field (identical to login page _GymTextField) ───────────────

class _DarkTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool isFocused;
  final ValueChanged<bool> onFocusChange;
  final int maxLines;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;

  const _DarkTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.isFocused,
    required this.onFocusChange,
    this.maxLines = 1,
    this.textInputAction,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: onFocusChange,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isFocused
                ? const Color(0xFFFF6B35).withOpacity(0.7)
                : const Color(0xFF1F2937),
            width: isFocused ? 1.5 : 1,
          ),
          color: const Color(0xFF111827),
          boxShadow: isFocused
              ? [
                  BoxShadow(
                    color: const Color(0xFFFF6B35).withOpacity(0.08),
                    blurRadius: 16,
                    spreadRadius: 2,
                  )
                ]
              : [],
        ),
        child: TextFormField(
          controller: controller,
          maxLines: maxLines,
          textInputAction: textInputAction,
          validator: validator,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
          cursorColor: const Color(0xFFFF6B35),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: Color(0xFF374151),
              fontSize: 15,
            ),
            prefixIcon: maxLines == 1
                ? Padding(
                    padding: const EdgeInsets.only(left: 16, right: 12),
                    child: Icon(
                      icon,
                      color: isFocused
                          ? const Color(0xFFFF6B35)
                          : const Color(0xFF4B5563),
                      size: 20,
                    ),
                  )
                : null,
            prefixIconConstraints: const BoxConstraints(
              minWidth: 48,
              minHeight: 48,
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
              horizontal: maxLines > 1 ? 16 : 0,
              vertical: 16,
            ),
            errorStyle: const TextStyle(
              color: Color(0xFFEF4444),
              fontSize: 12,
            ),
            errorBorder: InputBorder.none,
            focusedErrorBorder: InputBorder.none,
          ),
        ),
      ),
    );
  }
}

// ── Trainee Dropdown ──────────────────────────────────────────────────────

class _TraineeDropdown extends StatelessWidget {
  final List<TraineeModel> trainees;
  final TraineeModel? selected;
  final ValueChanged<TraineeModel?> onChanged;

  const _TraineeDropdown({
    required this.trainees,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1F2937)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<TraineeModel>(
          value: selected,
          dropdownColor: const Color(0xFF111827),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF4B5563)),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
          decoration: const InputDecoration(
            border: InputBorder.none,
            prefixIcon: Icon(Icons.person_outline_rounded,
                color: Color(0xFF4B5563), size: 20),
            prefixIconConstraints: BoxConstraints(minWidth: 36, minHeight: 48),
            hintText: 'Choose a trainee',
            hintStyle: TextStyle(color: Color(0xFF374151), fontSize: 15),
          ),
          items: trainees.map((t) {
            return DropdownMenuItem<TraineeModel>(
              value: t,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: const Color(0xFFFF6B35).withOpacity(0.15),
                    child: Text(
                      t.name.isNotEmpty ? t.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Color(0xFFFF6B35),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(t.name),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
          validator: (v) => v == null ? 'Please select a trainee' : null,
        ),
      ),
    );
  }
}

// ── Date Picker Field ─────────────────────────────────────────────────────

class _DatePickerField extends StatelessWidget {
  final DateTime date;
  final VoidCallback onTap;
  const _DatePickerField({required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF1F2937)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded,
                color: Color(0xFF4B5563), size: 20),
            const SizedBox(width: 14),
            Text(
              '${date.day} ${months[date.month - 1]} ${date.year}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B35).withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
                border:
                    Border.all(color: const Color(0xFFFF6B35).withOpacity(0.3)),
              ),
              child: const Text(
                'CHANGE',
                style: TextStyle(
                  color: Color(0xFFFF6B35),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error Banner (same as login page) ────────────────────────────────────

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

// ── Assign Button (same as Sign In button on login page) ──────────────────

class _AssignButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onTap;
  const _AssignButton({required this.isLoading, required this.onTap});

  @override
  State<_AssignButton> createState() => _AssignButtonState();
}

class _AssignButtonState extends State<_AssignButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTapDown: (_) {
          setState(() => _pressed = true);
          _ctrl.forward();
        },
        onTapUp: (_) {
          setState(() => _pressed = false);
          _ctrl.reverse();
          if (!widget.isLoading) widget.onTap();
        },
        onTapCancel: () {
          setState(() => _pressed = false);
          _ctrl.reverse();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.isLoading
                  ? [
                      const Color(0xFFFF6B35).withOpacity(0.5),
                      const Color(0xFFFF3B30).withOpacity(0.5),
                    ]
                  : [
                      const Color(0xFFFF6B35),
                      const Color(0xFFFF3B30),
                    ],
            ),
            boxShadow: _pressed || widget.isLoading
                ? []
                : [
                    BoxShadow(
                      color: const Color(0xFFFF6B35).withOpacity(0.45),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.rocket_launch_rounded,
                          color: Colors.white, size: 18),
                      SizedBox(width: 10),
                      Text(
                        'ASSIGN WORKOUT',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.8,
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

// ── Dropdown Loading Skeleton ─────────────────────────────────────────────

class _DropdownSkeleton extends StatelessWidget {
  const _DropdownSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1F2937)),
      ),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFFFF6B35),
          ),
        ),
      ),
    );
  }
}

// ── Error Chip ────────────────────────────────────────────────────────────

class _ErrorChip extends StatelessWidget {
  final String message;
  const _ErrorChip({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Color(0xFFEF4444), size: 16),
          const SizedBox(width: 8),
          Text(message,
              style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13)),
        ],
      ),
    );
  }
}
