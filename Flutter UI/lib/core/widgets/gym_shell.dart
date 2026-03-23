import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:Gym/core/navigation/app_router.dart';
import 'package:Gym/features/auth/providers/auth_provider.dart';

// ── Trainee Shell ─────────────────────────────────────────────────────────

class TraineeShell extends ConsumerStatefulWidget {
  final Widget child;
  final int currentIndex;

  const TraineeShell({
    super.key,
    required this.child,
    required this.currentIndex,
  });

  @override
  ConsumerState<TraineeShell> createState() => _TraineeShellState();
}

class _TraineeShellState extends ConsumerState<TraineeShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fabCtrl;
  late final Animation<double> _fabScale;
  bool _fabPressed = false;

  @override
  void initState() {
    super.initState();
    _fabCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _fabScale = Tween<double>(begin: 1.0, end: 0.93)
        .animate(CurvedAnimation(parent: _fabCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _fabCtrl.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    if (index == widget.currentIndex) return;
    switch (index) {
      case 0:
        context.go(AppRoutes.traineeHome);
        break;
      case 1:
        final coachId = ref.read(authStateProvider).coachId ?? '';
        context.push(AppRoutes.chat,
            extra: ChatArgs(otherUserId: coachId, otherUserName: 'My Coach'));
        break;
      // case 2: profile — coming soon
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final coachId = authState.coachId ?? '';
    final userName = authState.userName ?? 'Athlete';

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      extendBody: true,

      drawer: _TraineeDrawer(
        userName: userName,
        coachId: coachId,
        onLogout: () => ref.read(authStateProvider.notifier).logout(),
      ),

      body: widget.child,

      floatingActionButton: widget.currentIndex == 0
          ? ScaleTransition(
              scale: _fabScale,
              child: GestureDetector(
                onTapDown: (_) {
                  setState(() => _fabPressed = true);
                  _fabCtrl.forward();
                },
                onTapUp: (_) {
                  setState(() => _fabPressed = false);
                  _fabCtrl.reverse();
                  context.push(AppRoutes.logWorkout);
                },
                onTapCancel: () {
                  setState(() => _fabPressed = false);
                  _fabCtrl.reverse();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFF6B35), Color(0xFFFF3B30)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: _fabPressed
                        ? []
                        : [
                            BoxShadow(
                              color: const Color(0xFFFF6B35).withOpacity(0.5),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                  ),
                  child: const Icon(Icons.edit_note_rounded,
                      color: Colors.white, size: 26),
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      // 2 items only — Home + Chat (profile removed)
      bottomNavigationBar: _GymBottomNav(
        currentIndex: widget.currentIndex,
        onTap: _onNavTap,
        items: const [
          _NavItem(icon: Icons.home_rounded, label: 'Home'),
          _NavItem(icon: Icons.chat_bubble_rounded, label: 'Chat'),
        ],
      ),
    );
  }
}

// ── Coach Shell ───────────────────────────────────────────────────────────

class CoachShell extends ConsumerStatefulWidget {
  final Widget child;
  final int currentIndex;

  const CoachShell({
    super.key,
    required this.child,
    required this.currentIndex,
  });

  @override
  ConsumerState<CoachShell> createState() => _CoachShellState();
}

class _CoachShellState extends ConsumerState<CoachShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fabCtrl;
  late final Animation<double> _fabScale;
  bool _fabPressed = false;

  @override
  void initState() {
    super.initState();
    _fabCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _fabScale = Tween<double>(begin: 1.0, end: 0.93)
        .animate(CurvedAnimation(parent: _fabCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _fabCtrl.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    if (index == widget.currentIndex) return;
    switch (index) {
      case 0:
        context.go(AppRoutes.coachHome);
        break;
      case 1:
        context.push(AppRoutes.assignWorkout);
        break;
      // case 2: profile — coming soon
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final userName = authState.userName ?? 'Coach';

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      extendBody: true,

      drawer: _CoachDrawer(
        userName: userName,
        onLogout: () => ref.read(authStateProvider.notifier).logout(),
      ),

      body: widget.child,

      floatingActionButton: ScaleTransition(
        scale: _fabScale,
        child: GestureDetector(
          onTapDown: (_) {
            setState(() => _fabPressed = true);
            _fabCtrl.forward();
          },
          onTapUp: (_) {
            setState(() => _fabPressed = false);
            _fabCtrl.reverse();
            context.push(AppRoutes.assignWorkout);
          },
          onTapCancel: () {
            setState(() => _fabPressed = false);
            _fabCtrl.reverse();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFF6B35), Color(0xFFFF3B30)],
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: _fabPressed
                  ? []
                  : [
                      BoxShadow(
                        color: const Color(0xFFFF6B35).withOpacity(0.5),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      // 2 items only — Trainees + Assign (profile removed)
      bottomNavigationBar: _GymBottomNav(
        currentIndex: widget.currentIndex,
        onTap: _onNavTap,
        items: const [
          _NavItem(icon: Icons.people_rounded, label: 'Trainees'),
          _NavItem(icon: Icons.assignment_rounded, label: 'Assign'),
        ],
      ),
    );
  }
}

// ── Trainee Drawer ────────────────────────────────────────────────────────

class _TraineeDrawer extends ConsumerWidget {
  final String userName;
  final String coachId;
  final VoidCallback onLogout;

  const _TraineeDrawer({
    required this.userName,
    required this.coachId,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      backgroundColor: const Color(0xFF0A0A0F),
      child: Column(
        children: [
          _DrawerHeader(userName: userName, role: 'TRAINEE'),
          const SizedBox(height: 8),
          _DrawerItem(
            icon: Icons.home_rounded,
            label: 'Home',
            onTap: () {
              Navigator.pop(context);
              context.go(AppRoutes.traineeHome);
            },
          ),
          _DrawerItem(
            icon: Icons.fitness_center_rounded,
            label: 'Today\'s Workout',
            onTap: () {
              Navigator.pop(context);
              context.go(AppRoutes.traineeHome);
            },
          ),
          _DrawerItem(
            icon: Icons.edit_note_rounded,
            label: 'Log Workout',
            onTap: () {
              Navigator.pop(context);
              context.push(AppRoutes.logWorkout);
            },
          ),
          _DrawerItem(
            icon: Icons.chat_bubble_rounded,
            label: 'Chat with Coach',
            onTap: () {
              Navigator.pop(context);
              context.push(AppRoutes.chat,
                  extra: ChatArgs(
                      otherUserId: coachId, otherUserName: 'My Coach'));
            },
          ),
          const Spacer(),
          Container(
            height: 1,
            color: const Color(0xFF1F2937),
            margin: const EdgeInsets.symmetric(horizontal: 24),
          ),
          const SizedBox(height: 12),
          _DrawerItem(
            icon: Icons.logout_rounded,
            label: 'Logout',
            isRed: true,
            onTap: () {
              Navigator.pop(context);
              onLogout();
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Coach Drawer ──────────────────────────────────────────────────────────

class _CoachDrawer extends StatelessWidget {
  final String userName;
  final VoidCallback onLogout;

  const _CoachDrawer({required this.userName, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF0A0A0F),
      child: Column(
        children: [
          _DrawerHeader(userName: userName, role: 'COACH'),
          const SizedBox(height: 8),
          _DrawerItem(
            icon: Icons.people_rounded,
            label: 'My Trainees',
            onTap: () {
              Navigator.pop(context);
              context.go(AppRoutes.coachHome);
            },
          ),
          _DrawerItem(
            icon: Icons.assignment_rounded,
            label: 'Assign Workout',
            onTap: () {
              Navigator.pop(context);
              context.push(AppRoutes.assignWorkout);
            },
          ),
          const Spacer(),
          Container(
            height: 1,
            color: const Color(0xFF1F2937),
            margin: const EdgeInsets.symmetric(horizontal: 24),
          ),
          const SizedBox(height: 12),
          _DrawerItem(
            icon: Icons.logout_rounded,
            label: 'Logout',
            isRed: true,
            onTap: () {
              Navigator.pop(context);
              onLogout();
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Drawer Header ─────────────────────────────────────────────────────────

class _DrawerHeader extends StatelessWidget {
  final String userName;
  final String role;
  const _DrawerHeader({required this.userName, required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 56, 24, 28),
      decoration: const BoxDecoration(
        color: Color(0xFF111827),
        border: Border(
          bottom: BorderSide(color: Color(0xFF1F2937)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFF6B35), Color(0xFFFF3B30)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6B35).withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.fitness_center_rounded,
                color: Colors.white, size: 26),
          ),
          const SizedBox(height: 16),
          Text(
            userName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B35).withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
              border:
                  Border.all(color: const Color(0xFFFF6B35).withOpacity(0.3)),
            ),
            child: Text(
              role,
              style: const TextStyle(
                color: Color(0xFFFF6B35),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Drawer Item ───────────────────────────────────────────────────────────

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isRed;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isRed = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isRed ? const Color(0xFFEF4444) : const Color(0xFF9CA3AF);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      splashColor: const Color(0xFFFF6B35).withOpacity(0.08),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isRed
                    ? const Color(0xFFEF4444).withOpacity(0.10)
                    : const Color(0xFF1F2937),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bottom Navigation Bar ─────────────────────────────────────────────────

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

class _GymBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<_NavItem> items;

  const _GymBottomNav({
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0D1117),
        border: Border(
          top: BorderSide(color: Color(0xFF1F2937), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 24,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: List.generate(items.length, (i) {
              final item = items[i];
              final isSelected = i == currentIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFFF6B35).withOpacity(0.08)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFFFF6B35),
                                      Color(0xFFFF3B30),
                                    ],
                                  )
                                : null,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            item.icon,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF4B5563),
                            size: 20,
                          ),
                        ),
                        const SizedBox(height: 4),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            color: isSelected
                                ? const Color(0xFFFF6B35)
                                : const Color(0xFF4B5563),
                            fontSize: 10,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                          child: Text(item.label),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
