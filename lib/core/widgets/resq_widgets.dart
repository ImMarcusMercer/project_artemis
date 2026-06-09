import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/app_models.dart';

class GradientBackground extends StatelessWidget {
  const GradientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.navy, AppColors.navy2, AppColors.teal],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: -80,
            bottom: -60,
            child: _Glow(color: AppColors.yellow.withOpacity(0.20), size: 260),
          ),
          Positioned(
            right: -70,
            top: -60,
            child: _Glow(color: AppColors.red.withOpacity(0.20), size: 240),
          ),
          child,
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [BoxShadow(color: color, blurRadius: 80, spreadRadius: 30)],
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.color = Colors.white,
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
    if (onTap == null) return card;
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: card,
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.fullWidth = true,
    this.color = AppColors.red,
    this.textSize,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool fullWidth;
  final Color color;
  final double? textSize;

  @override
  Widget build(BuildContext context) {
    final button = FilledButton.icon(
      onPressed: onPressed,
      icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 18),
      label: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Text(label, style: TextStyle(fontWeight: FontWeight.w800, fontSize: textSize)),
      ),
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    this.color = AppColors.navy,
    this.subtitle,
  });

  final String value;
  final String label;
  final String icon;
  final Color color;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(child: Text(icon, style: const TextStyle(fontSize: 20))),
              ),
              const Spacer(),
              Icon(Icons.trending_up_rounded, color: color, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color, height: 1)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w600, height: 1.1)),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(subtitle!, style: const TextStyle(fontSize: 10, color: AppColors.muted, height: 1.1)),
          ],
        ],
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final resolved = color ?? statusColor(label);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: resolved.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(fontSize: 11, color: resolved, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class ProfileSummaryCard extends StatelessWidget {
  const ProfileSummaryCard({super.key, required this.user});

  final AppUser user;

  Color get _backgroundColor {
    switch (user.role) {
      case AppRole.citizen:
        return AppColors.blue;
      case AppRole.responder:
        return AppColors.red;
      case AppRole.professional:
        return AppColors.teal;
      case AppRole.admin:
        return AppColors.purple;
    }
  }

  String get _title {
    return user.role == AppRole.admin ? 'Welcome Admin' : 'Welcome Back';
  }

  String get _subtitle {
    switch (user.role) {
      case AppRole.citizen:
        return 'Citizen User';
      case AppRole.responder:
        return user.position ?? 'Responder';
      case AppRole.professional:
        return user.profession ?? 'Healthcare Professional';
      case AppRole.admin:
        return 'System Management Portal';
    }
  }

  List<Widget> get _details {
    final details = <Widget>[];
    if (user.role == AppRole.citizen) {
      if (user.age != null && user.age!.isNotEmpty) {
        details.add(_detailRow(icon: Icons.cake_rounded, label: 'Age', value: user.age!));
      }
      if (user.address != null && user.address!.isNotEmpty) {
        details.add(_detailRow(icon: Icons.location_on_rounded, label: 'Location', value: user.address!));
      }
    }
    if (user.role == AppRole.professional) {
      if (user.specialty != null && user.specialty!.isNotEmpty) {
        details.add(_detailRow(icon: Icons.health_and_safety_rounded, label: 'Specialty', value: user.specialty!));
      }
    }
    return details;
  }

  Widget _detailRow({required IconData icon, required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white70),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: _backgroundColor.withOpacity(0.28), blurRadius: 26, offset: const Offset(0, 12)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_title, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(user.fullName, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, height: 1.05)),
          const SizedBox(height: 4),
          Text(_subtitle, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
          if (_details.isNotEmpty) ...[
            const SizedBox(height: 12),
            ..._details,
          ],
        ],
      ),
    );
  }
}

Color statusColor(String value) {
  switch (value.toLowerCase()) {
    case 'critical':
    case 'high':
    case 'declined':
    case 'rejected':
      return AppColors.red;
    case 'moderate':
    case 'pending':
    case 'dispatched':
      return AppColors.amber;
    case 'accepted':
    case 'approved':
    case 'completed':
    case 'resolved':
    case 'low':
      return AppColors.green;
    case 'in-progress':
      return AppColors.blue;
    default:
      return AppColors.navy;
  }
}

class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.title, required this.subtitle, this.trailing});

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.text)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({super.key, required this.children, this.minTileWidth = 160, this.gap = 14});

  final List<Widget> children;
  final double minTileWidth;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.maxWidth / minTileWidth).floor().clamp(1, 4);
        return GridView.builder(
          itemCount: children.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: gap,
            mainAxisSpacing: gap,
            childAspectRatio: 1.35,
          ),
          itemBuilder: (context, index) => children[index],
        );
      },
    );
  }
}

String friendlyDateTime(DateTime value) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  final hour = value.hour > 12 ? value.hour - 12 : (value.hour == 0 ? 12 : value.hour);
  final minute = value.minute.toString().padLeft(2, '0');
  final period = value.hour >= 12 ? 'PM' : 'AM';
  return '${months[value.month - 1]} ${value.day}, ${value.year} · $hour:$minute $period';
}

class TwoColumn extends StatelessWidget {
  const TwoColumn({
    super.key,
    required this.left,
    required this.right,
    this.breakpoint = 880,
    this.leftFlex = 1,
    this.rightFlex = 1,
    this.gap = 18,
  });

  final Widget left;
  final Widget right;
  final double breakpoint;
  final int leftFlex;
  final int rightFlex;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= breakpoint) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: leftFlex, child: left),
              SizedBox(width: gap),
              Expanded(flex: rightFlex, child: right),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [left, SizedBox(height: gap), right],
        );
      },
    );
  }
}
