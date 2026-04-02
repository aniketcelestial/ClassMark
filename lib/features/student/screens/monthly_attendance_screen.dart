import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/attendance_model.dart';
import '../../../shared/services/otp_service.dart';
import '../../../shared/widgets/animated_bg.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../teacher/controllers/teacher_controller.dart';

final monthlyAttendanceProvider = FutureProvider.family<
    List<AttendanceRecord>, ({String studentId, DateTime month})>(
      (ref, params) async {
    return ref.read(otpServiceProvider).getStudentMonthlyAttendance(
      studentId: params.studentId,
      month: params.month,
    );
  },
);

class MonthlyAttendanceScreen extends ConsumerStatefulWidget {
  const MonthlyAttendanceScreen({super.key});

  @override
  ConsumerState<MonthlyAttendanceScreen> createState() =>
      _MonthlyAttendanceScreenState();
}

class _MonthlyAttendanceScreenState
    extends ConsumerState<MonthlyAttendanceScreen> {
  DateTime _selectedMonth = DateTime.now();

  void _previousMonth() {
    setState(() {
      _selectedMonth =
          DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
  }

  void _nextMonth() {
    final now = DateTime.now();
    if (_selectedMonth.year < now.year ||
        (_selectedMonth.year == now.year &&
            _selectedMonth.month < now.month)) {
      setState(() {
        _selectedMonth =
            DateTime(_selectedMonth.year, _selectedMonth.month + 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Scaffold();

    final attendanceAsync = ref.watch(monthlyAttendanceProvider(
        (studentId: user.uid, month: _selectedMonth)));

    final isCurrentMonth = _selectedMonth.year == DateTime.now().year &&
        _selectedMonth.month == DateTime.now().month;

    return Scaffold(
      body: AnimatedMeshBackground(
        colors: const [AppTheme.primaryPurple, AppTheme.primaryBlue],
        child: SafeArea(
          child: Column(
            children: [
              // App bar
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
                        'My Attendance',
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      // Month selector
                      GlassCard(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              onPressed: _previousMonth,
                              icon: const Icon(
                                  Icons.chevron_left_rounded,
                                  color: AppTheme.textPrimary),
                            ),
                            Text(
                              DateFormat('MMMM yyyy')
                                  .format(_selectedMonth),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            IconButton(
                              onPressed: isCurrentMonth ? null : _nextMonth,
                              icon: Icon(
                                Icons.chevron_right_rounded,
                                color: isCurrentMonth
                                    ? AppTheme.textMuted
                                    : AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 400.ms),
                      const SizedBox(height: 20),
                      attendanceAsync.when(
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40),
                            child: CircularProgressIndicator(
                                color: AppTheme.primaryBlue),
                          ),
                        ),
                        error: (e, _) => Center(
                          child: Text('Error: $e',
                              style:
                              const TextStyle(color: AppTheme.errorRed)),
                        ),
                        data: (records) {
                          final totalDays = DateUtils.getDaysInMonth(
                              _selectedMonth.year, _selectedMonth.month);
                          final presentDays = records.length;
                          final percentage = totalDays > 0
                              ? (presentDays / totalDays * 100)
                              .clamp(0, 100)
                              .toDouble()
                              : 0.0;

                          return Column(
                            children: [
                              // Stats row
                              Row(
                                children: [
                                  Expanded(
                                    child: _StatCard(
                                      label: 'Present',
                                      value: '$presentDays',
                                      color: AppTheme.accentGreen,
                                      icon: Icons.check_circle_rounded,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _StatCard(
                                      label: 'Absent',
                                      value:
                                      '${totalDays - presentDays}',
                                      color: AppTheme.errorRed,
                                      icon: Icons.cancel_rounded,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _StatCard(
                                      label: 'Rate',
                                      value:
                                      '${percentage.toStringAsFixed(0)}%',
                                      color: AppTheme.primaryBlue,
                                      icon: Icons.pie_chart_rounded,
                                    ),
                                  ),
                                ],
                              ).animate(delay: 200.ms).fadeIn(),
                              const SizedBox(height: 20),
                              // Circular progress
                              _AttendanceRing(
                                percentage: percentage / 100,
                                present: presentDays,
                                total: totalDays,
                              ).animate(delay: 300.ms).fadeIn().scale(
                                  begin: const Offset(0.9, 0.9)),
                              const SizedBox(height: 20),
                              // Calendar grid
                              _CalendarGrid(
                                month: _selectedMonth,
                                presentDates: records
                                    .map((r) => r.markedAt)
                                    .toList(),
                              ).animate(delay: 400.ms).fadeIn(),
                              const SizedBox(height: 20),
                              // Recent list
                              if (records.isNotEmpty) ...[
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: const Text(
                                    'Recent Sessions',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ...records.reversed
                                    .take(10)
                                    .toList()
                                    .asMap()
                                    .entries
                                    .map((e) => _AttendanceListItem(
                                  record: e.value,
                                  index: e.key,
                                )),
                              ] else
                                _EmptyAttendance(month: _selectedMonth),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 32),
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

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceRing extends StatelessWidget {
  final double percentage;
  final int present;
  final int total;

  const _AttendanceRing({
    required this.percentage,
    required this.present,
    required this.total,
  });

  Color get _color {
    if (percentage >= 0.75) return AppTheme.accentGreen;
    if (percentage >= 0.50) return AppTheme.accentOrange;
    return AppTheme.errorRed;
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Row(
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: percentage,
                    strokeWidth: 10,
                    backgroundColor: AppTheme.glassWhite,
                    valueColor: AlwaysStoppedAnimation<Color>(_color),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Text(
                  '${(percentage * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  percentage >= 0.75
                      ? 'Excellent!'
                      : percentage >= 0.50
                      ? 'Needs Improvement'
                      : 'Critical',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _color,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$present out of $total days attended',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                if (percentage < 0.75)
                  Text(
                    'Need ${((0.75 * total) - present).ceil()} more days for 75%',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.accentOrange,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  final DateTime month;
  final List<DateTime> presentDates;

  const _CalendarGrid(
      {required this.month, required this.presentDates});

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth =
    DateUtils.getDaysInMonth(month.year, month.month);
    final startWeekday = firstDay.weekday % 7; // Sunday = 0

    final presentSet = presentDates.map((d) => d.day).toSet();
    final today = DateTime.now();

    return GlassCard(
      child: Column(
        children: [
          // Weekday headers
          Row(
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                .map((d) => Expanded(
              child: Center(
                child: Text(
                  d,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ))
                .toList(),
          ),
          const SizedBox(height: 8),
          // Days grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: daysInMonth + startWeekday,
            itemBuilder: (ctx, i) {
              if (i < startWeekday) return const SizedBox();
              final day = i - startWeekday + 1;
              final isPresent = presentSet.contains(day);
              final isToday = month.year == today.year &&
                  month.month == today.month &&
                  day == today.day;
              final isFuture = DateTime(month.year, month.month, day)
                  .isAfter(today);

              return Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isPresent
                      ? AppTheme.accentGreen.withOpacity(0.2)
                      : isToday
                      ? AppTheme.primaryBlue.withOpacity(0.15)
                      : null,
                  border: isToday
                      ? Border.all(
                      color: AppTheme.primaryBlue.withOpacity(0.5))
                      : isPresent
                      ? Border.all(
                      color:
                      AppTheme.accentGreen.withOpacity(0.5))
                      : null,
                ),
                child: Center(
                  child: Text(
                    '$day',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isPresent || isToday
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: isPresent
                          ? AppTheme.accentGreen
                          : isToday
                          ? AppTheme.primaryBlue
                          : isFuture
                          ? AppTheme.textMuted
                          : AppTheme.textSecondary,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendItem(
                  color: AppTheme.accentGreen, label: 'Present'),
              const SizedBox(width: 16),
              _LegendItem(
                  color: AppTheme.primaryBlue, label: 'Today'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: AppTheme.textSecondary)),
      ],
    );
  }
}

class _AttendanceListItem extends StatelessWidget {
  final AttendanceRecord record;
  final int index;

  const _AttendanceListItem(
      {required this.record, required this.index});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppTheme.accentGreen.withOpacity(0.15),
              border: Border.all(
                  color: AppTheme.accentGreen.withOpacity(0.3)),
            ),
            child: Center(
              child: Text(
                DateFormat('dd').format(record.markedAt),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.accentGreen,
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
                  record.subject,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('EEE, MMM dd · hh:mm a')
                      .format(record.markedAt),
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
              const Icon(Icons.check_circle_rounded,
                  color: AppTheme.accentGreen, size: 18),
              const SizedBox(height: 2),
              Text(
                '${record.distanceFromTeacher.toStringAsFixed(0)}m',
                style: const TextStyle(
                    fontSize: 11, color: AppTheme.textMuted),
              ),
            ],
          ),
        ],
      ),
    ).animate(delay: Duration(milliseconds: index * 60)).fadeIn().slideX(begin: 0.1);
  }
}

class _EmptyAttendance extends StatelessWidget {
  final DateTime month;
  const _EmptyAttendance({required this.month});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        children: [
          const Icon(Icons.event_busy_rounded,
              color: AppTheme.textMuted, size: 40),
          const SizedBox(height: 12),
          Text(
            'No attendance in ${DateFormat('MMMM').format(month)}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Your attendance records for this month\nwill appear here.',
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