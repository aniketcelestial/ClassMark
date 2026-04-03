import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/animated_bg.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/teacher_controller.dart';

class PresentStudentsScreen extends ConsumerWidget {
  const PresentStudentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(activeSessionProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      body: AnimatedMeshBackground(
        colors: const [AppTheme.accentCyan, AppTheme.accentGreen],
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 24, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: AppTheme.textPrimary),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Present Students',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      if (session == null || session.isExpired) ...[
                        _NoSessionView(),
                      ] else ...[
                        // Session header
                        GlassCard(
                          backgroundColor:
                              AppTheme.accentCyan.withOpacity(0.08),
                          borderColor:
                              AppTheme.accentCyan.withOpacity(0.3),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.accentCyan,
                                ),
                              )
                                  .animate(
                                      onPlay: (c) => c.repeat())
                                  .scaleXY(
                                      end: 1.6, duration: 700.ms)
                                  .then()
                                  .scaleXY(
                                      end: 1.0, duration: 700.ms),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Live Attendance',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.accentCyan,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      '${session.subject} · ${session.className}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(duration: 400.ms),
                        const SizedBox(height: 20),
                        // Live list
                        Consumer(
                          builder: (context, ref, _) {
                            final studentsAsync = ref.watch(
                                presentStudentsProvider(session.id));
                            return studentsAsync.when(
                              loading: () => const Center(
                                  child: CircularProgressIndicator(
                                      color: AppTheme.accentCyan)),
                              error: (e, _) => Center(
                                child: Text(
                                  'Error loading students',
                                  style: TextStyle(
                                      color: AppTheme.errorRed),
                                ),
                              ),
                              data: (students) {
                                if (students.isEmpty) {
                                  return _EmptyStudents();
                                }
                                return Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            'Total: ',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color:
                                                  AppTheme.textSecondary,
                                            ),
                                          ),
                                          Text(
                                            '${students.length} present',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight:
                                                  FontWeight.w700,
                                              color: AppTheme.accentGreen,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Expanded(
                                        child: ListView.separated(
                                          itemCount: students.length,
                                          separatorBuilder:
                                              (_, __) =>
                                                  const SizedBox(
                                                      height: 10),
                                          itemBuilder: (ctx, i) {
                                            final s = students[i];
                                            return _StudentTile(
                                              record: s,
                                              index: i,
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StudentTile extends StatelessWidget {
  final dynamic record;
  final int index;

  const _StudentTile({required this.record, required this.index});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: AppTheme.studentGradient,
              ),
            ),
            child: Center(
              child: Text(
                record.studentName.isNotEmpty
                    ? record.studentName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.studentName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('hh:mm a').format(record.markedAt),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.accentGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppTheme.accentGreen.withOpacity(0.4)),
                ),
                child: const Text(
                  'PRESENT',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.accentGreen,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${record.distanceFromTeacher.toStringAsFixed(1)}m',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate(delay: Duration(milliseconds: index * 60)).fadeIn().slideX(begin: 0.1);
  }
}

class _NoSessionView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: GlassCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.how_to_reg_outlined,
              color: AppTheme.textMuted,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'No Active Session',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Generate an OTP first to see present students.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn();
  }
}

class _EmptyStudents extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.people_outline_rounded,
            color: AppTheme.textMuted,
            size: 48,
          ),
          const SizedBox(height: 16),
          const Text(
            'Waiting for students...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Students who enter the OTP while nearby will appear here in real-time.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    ).animate().fadeIn();
  }
}
