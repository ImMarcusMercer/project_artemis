import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/app_models.dart';
import '../../core/services/firestore_service.dart';

enum EmergencyLevel { critical, high, moderate }

class SOSModal extends StatefulWidget {
  const SOSModal({
    super.key,
    required this.user,
    required this.firestoreService,
  });

  final AppUser user;
  final FirestoreService firestoreService;

  static Future<void> show(
    BuildContext context, {
    required AppUser user,
    required FirestoreService firestoreService,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (_) => SOSModal(user: user, firestoreService: firestoreService),
    );
  }

  @override
  State<SOSModal> createState() => _SOSModalState();
}

enum _SosView { select, locating, confirmHigh, moderateForm, success }

class _SOSModalState extends State<SOSModal>
    with TickerProviderStateMixin {
  final GlobalKey _trackKey = GlobalKey();

  _SosView _view = _SosView.select;
  EmergencyLevel? _selectedLevel;
  String? _statusMsg;
  Timer? _dragEndTimer;
  Timer? _autoTriggerTimer;
  Timer? _heartbeatStageTimer;
  int _heartbeatStage = 0;
  bool _autoTriggerCancelled = false;
  String? _detectedLocation;

  Offset _knobPosition = Offset.zero;
  bool _isDragging = false;

  late AnimationController _snapController;
  late AnimationController _pulseController;
  Offset _snapStart = Offset.zero;
  Offset _snapEnd = Offset.zero;
  Color _snapColor = Colors.transparent;

  @override
  void initState() {
    super.initState();
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _startAutoTriggerCountdown();
  }

  @override
  void dispose() {
    _dragEndTimer?.cancel();
    _autoTriggerTimer?.cancel();
    _heartbeatStageTimer?.cancel();
    _snapController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final dialogWidth = screenSize.width < 360
        ? screenSize.width - 32
        : screenSize.width < 480
        ? 380.0
        : 460.0;
    final dialogMaxHeight = screenSize.height * 0.88;
    final selectorSize = math.min(320.0, dialogWidth - 56);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: AppColors.white,
      elevation: 16,
      shadowColor: Colors.black.withOpacity(0.18),
      child: SizedBox(
        width: dialogWidth,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: dialogWidth,
                  maxHeight: dialogMaxHeight,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                  child: switch (_view) {
                    _SosView.select => _SelectView(
                      trackKey: _trackKey,
                      selectorSize: selectorSize,
                      knobPosition: _knobPosition,
                      isDragging: _isDragging,
                      snapController: _snapController,
                      pulseAnimation: _pulseController,
                      heartbeatStage: _heartbeatStage,
                      snapStart: _snapStart,
                      snapEnd: _snapEnd,
                      snapColor: _snapColor,
                      onPanStart: _handlePanStart,
                      onPanUpdate: _handlePanUpdate,
                      onPanEnd: _handlePanEnd,
                    ),
                    _SosView.locating => _LocatingView(
                      statusMsg: _statusMsg,
                      onTimeout: _onLocateTimeout,
                    ),
                    _SosView.confirmHigh => _HighFormView(
                      user: widget.user,
                      firestoreService: widget.firestoreService,
                      onCancel: _backToSelect,
                      onSent: _onHighSent,
                    ),
                    _SosView.moderateForm => _ModerateFormView(
                      user: widget.user,
                      firestoreService: widget.firestoreService,
                      onCancel: _backToSelect,
                      onSent: _onModerateSent,
                    ),
                    _SosView.success => _SuccessView(
                      level: _selectedLevel,
                      onClose: _closeAll,
                    ),
                  },
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: SizedBox(
                width: 36,
                height: 36,
                child: Material(
                  color: Colors.transparent,
                  shape: const CircleBorder(),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: _closeAll,
                    child: const Center(
                      child: Icon(
                        Icons.close,
                        color: Color(0xFF333333),
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onSelect(EmergencyLevel level) async {
    if (_selectedLevel != null) return;
    setState(() {
      _selectedLevel = level;
    });

    final address = widget.user.address ?? 'Location unavailable';

    if (level == EmergencyLevel.moderate) {
      await Future.delayed(const Duration(milliseconds: 120));
      if (!mounted) return;
      setState(() {
        _view = _SosView.moderateForm;
        _statusMsg = 'Fill in emergency details...';
      });
      return;
    }

    if (level == EmergencyLevel.high) {
      await Future.delayed(const Duration(milliseconds: 120));
      if (!mounted) return;
      setState(() {
        _view = _SosView.confirmHigh;
        _statusMsg = 'Provide additional details or submit your alert.';
      });
      return;
    }

    await _sendAndShow(
      message:
          'CRITICAL EMERGENCY — immediate dispatch required. Location: $address',
      address: address,
      priority: 'CRITICAL',
    );
  }

  Future<void> _confirmHigh() async {
    final address =
        _detectedLocation ??
        widget.user.address ??
        'Current location unavailable.';
    setState(() {
      _view = _SosView.locating;
      _statusMsg = 'Sending HIGH alert...';
    });
    await widget.firestoreService.createSosAlert(
      user: widget.user,
      message: 'HIGH EMERGENCY — urgent assistance required.',
      address: address,
      priority: 'HIGH',
    );
    if (!mounted) return;
    setState(() {
      _view = _SosView.success;
      _statusMsg = null;
    });
  }

  Future<void> _sendAndShow({
    required String message,
    required String address,
    required String priority,
  }) async {
    setState(() {
      _view = _SosView.locating;
      _statusMsg = 'Sending emergency alert...';
    });
    await widget.firestoreService.createSosAlert(
      user: widget.user,
      message: message,
      address: address,
      priority: priority,
    );
    if (!mounted) return;
    setState(() {
      _view = _SosView.success;
      _statusMsg = null;
    });
  }

  void _onModerateSent() {
    setState(() {
      _view = _SosView.success;
      _statusMsg = null;
    });
  }

  void _onHighSent() {
    setState(() {
      _view = _SosView.success;
      _statusMsg = null;
    });
  }

  void _onLocateTimeout() {
    _backToSelect();
  }

  void _backToSelect() {
    setState(() {
      _view = _SosView.select;
      _selectedLevel = null;
      _knobPosition = Offset.zero;
      _statusMsg = null;
      _detectedLocation = null;
    });
    _startAutoTriggerCountdown();
  }

  void _closeAll() {
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _startAutoTriggerCountdown() {
    _autoTriggerTimer?.cancel();
    _heartbeatStageTimer?.cancel();
    _autoTriggerCancelled = false;
    setState(() {
      _heartbeatStage = 1;
    });

    _heartbeatStageTimer = Timer(const Duration(seconds: 1), () {
      if (!mounted || _view != _SosView.select || _autoTriggerCancelled) return;
      setState(() {
        _heartbeatStage = 2;
      });
    });

    _autoTriggerTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted || _view != _SosView.select || _autoTriggerCancelled) return;
      _heartbeatStageTimer?.cancel();
      setState(() {
        _heartbeatStage = 0;
      });
      _onSelect(EmergencyLevel.critical);
    });
  }

  void _cancelAutoTriggerCountdown() {
    _autoTriggerCancelled = true;
    _autoTriggerTimer?.cancel();
    _heartbeatStageTimer?.cancel();
    _autoTriggerTimer = null;
    _heartbeatStageTimer = null;
    setState(() {
      _heartbeatStage = 0;
    });
  }

  Offset _getTrackPoint(EmergencyLevel level, Size size) {
    final center = _getCenterNode(size);
    final trackWidth = size.width * 0.5;
    final step = trackWidth / 2;

    switch (level) {
      case EmergencyLevel.moderate:
        return Offset(center.dx - step, center.dy);
      case EmergencyLevel.critical:
        return Offset(center.dx, center.dy);
      case EmergencyLevel.high:
        return Offset(center.dx + step, center.dy);
    }
  }

  Offset _getCenterNode(Size size) {
    return Offset(size.width / 2, size.height / 2);
  }

  EmergencyLevel? _getNearestEndpoint(Offset position, Size size) {
    const maxDistance = 56.0;
    for (final level in EmergencyLevel.values) {
      final endpoint = _getTrackPoint(level, size);
      if ((position - endpoint).distance < maxDistance) {
        return level;
      }
    }
    return null;
  }

  Offset _constrainToPath(Offset position, Size size) {
    final center = _getCenterNode(size);
    final minX = _getTrackPoint(EmergencyLevel.moderate, size).dx;
    final maxX = _getTrackPoint(EmergencyLevel.high, size).dx;
    final clampedX = position.dx.clamp(minX, maxX);
    return Offset(clampedX, center.dy);
  }

  void _handlePanStart(DragStartDetails details) {
    if (_selectedLevel != null || _view != _SosView.select) return;
    _cancelAutoTriggerCountdown();
    setState(() => _isDragging = true);
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_selectedLevel != null || _view != _SosView.select) return;

    final renderBox =
        _trackKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final localOffset = renderBox.globalToLocal(details.globalPosition);
    final newOffset = _constrainToPath(localOffset, renderBox.size);

    setState(() {
      _knobPosition = newOffset - _getCenterNode(renderBox.size);
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    if (_selectedLevel != null || _view != _SosView.select) return;
    setState(() => _isDragging = false);

    final renderBox =
        _trackKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      _animateToCenter();
      return;
    }

    final center = _getCenterNode(renderBox.size);
    final currentPosition = center + _knobPosition;
    final nearest = _getNearestEndpoint(currentPosition, renderBox.size);
    if (nearest == null) {
      _animateToCenter();
      return;
    }

    _snapToEndpoint(nearest, renderBox.size);
  }

  void _animateToCenter() {
    final renderBox =
        _trackKey.currentContext?.findRenderObject() as RenderBox?;
    final center = renderBox != null
        ? _getCenterNode(renderBox.size)
        : _getCenterNode(const Size(320, 320));
    _snapStart = center + _knobPosition;
    _snapEnd = center;
    _snapColor = Colors.transparent;

    _snapController
      ..reset()
      ..forward().then((_) {
        if (mounted) {
          setState(() {
            _knobPosition = Offset.zero;
          });
        }
      });
  }

  void _snapToEndpoint(EmergencyLevel level, Size size) {
    final center = _getCenterNode(size);
    final endpoint = _getTrackPoint(level, size);

    _snapStart = center + _knobPosition;
    _snapEnd = endpoint;
    _snapColor = _getLevelColor(level);

    _snapController
      ..reset()
      ..forward().then((_) {
        if (mounted) {
          setState(() {
            _knobPosition = endpoint - center;
          });
          _onSelect(level);
        }
      });
  }

  Color _getLevelColor(EmergencyLevel level) {
    switch (level) {
      case EmergencyLevel.critical:
        return const Color(0xFFD32F2F);
      case EmergencyLevel.high:
        return const Color(0xFFF57C00);
      case EmergencyLevel.moderate:
        return const Color(0xFFFBC02D);
    }
  }
}

class _SelectView extends StatelessWidget {
  const _SelectView({
    required this.trackKey,
    required this.selectorSize,
    required this.knobPosition,
    required this.isDragging,
    required this.snapController,
    required this.pulseAnimation,
    required this.heartbeatStage,
    required this.snapStart,
    required this.snapEnd,
    required this.snapColor,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
  });

  final GlobalKey trackKey;
  final double selectorSize;
  final Offset knobPosition;
  final bool isDragging;
  final AnimationController snapController;
  final Animation<double> pulseAnimation;
  final int heartbeatStage;
  final Offset snapStart;
  final Offset snapEnd;
  final Color snapColor;
  final GestureDragStartCallback onPanStart;
  final GestureDragUpdateCallback onPanUpdate;
  final GestureDragEndCallback onPanEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'EMERGENCY SOS',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFD32F2F),
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                  shadows: [
                    Shadow(
                      color: Color(0x33D32F2F),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD32F2F),
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0x33D32F2F),
                      blurRadius: 14,
                      spreadRadius: 0.5,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: _GearShifterSelector(
            trackKey: trackKey,
            selectorSize: selectorSize,
            knobPosition: knobPosition,
            isDragging: isDragging,
            snapController: snapController,
            pulseAnimation: pulseAnimation,
            heartbeatStage: heartbeatStage,
            snapStart: snapStart,
            snapEnd: snapEnd,
            snapColor: snapColor,
            onPanStart: onPanStart,
            onPanUpdate: onPanUpdate,
            onPanEnd: onPanEnd,
          ),
        ),
        const SizedBox(height: 20),
        if (heartbeatStage > 0) ...[
          Center(
            child: Text(
              'Auto-alert in progress',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.navy.withOpacity(0.65),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _HeartbeatDot(active: heartbeatStage >= 1),
              const SizedBox(width: 10),
              _HeartbeatDot(active: heartbeatStage >= 2),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _LocatingView extends StatelessWidget {
  const _LocatingView({required this.statusMsg, required this.onTimeout});

  final String? statusMsg;
  final VoidCallback onTimeout;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.navy.withOpacity(0.06),
            border: Border.all(color: AppColors.navy.withOpacity(0.12)),
          ),
          child: const Center(
            child: SizedBox(
              width: 44,
              height: 44,
              child: CircularProgressIndicator(
                strokeWidth: 3.2,
                color: AppColors.navy,
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          statusMsg ?? 'Locating...',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.navy.withOpacity(0.7),
            fontSize: 13,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),
        TextButton(
          onPressed: onTimeout,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.navy.withOpacity(0.7),
          ),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

class _HighFormView extends StatefulWidget {
  const _HighFormView({
    required this.user,
    required this.firestoreService,
    required this.onCancel,
    required this.onSent,
  });

  final AppUser user;
  final FirestoreService firestoreService;
  final VoidCallback onCancel;
  final VoidCallback onSent;

  @override
  State<_HighFormView> createState() => _HighFormViewState();
}

class _HighFormViewState extends State<_HighFormView> {
  final _msg = TextEditingController(
    text: 'Require urgent assistance. Please respond quickly.',
  );
  bool _sending = false;

  @override
  void dispose() {
    _msg.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => _sending = true);
    await widget.firestoreService.createSosAlert(
      user: widget.user,
      message: _msg.text.trim().isEmpty
          ? 'URGENT ASSISTANCE REQUIRED.'
          : _msg.text.trim(),
      address: widget.user.address ?? 'Location unavailable',
      priority: 'HIGH',
    );
    if (!mounted) return;
    setState(() => _sending = false);
    widget.onSent();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFF57C00).withOpacity(0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_rounded,
                color: Color(0xFFF57C00),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'High Alert',
                style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _msg,
          maxLines: 4,
          style: const TextStyle(color: AppColors.navy),
          decoration: InputDecoration(
            labelText: 'Additional details',
            labelStyle: TextStyle(color: AppColors.navy.withOpacity(0.7)),
            hintText: 'Describe the emergency...',
            hintStyle: TextStyle(color: AppColors.navy.withOpacity(0.4)),
            filled: true,
            fillColor: AppColors.navy.withOpacity(0.04),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.navy.withOpacity(0.18)),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _sending ? null : widget.onCancel,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.navy,
                  side: BorderSide(color: AppColors.navy.withOpacity(0.35)),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Cancel'),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: _sending ? null : _send,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFF57C00),
                  foregroundColor: Colors.white,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(_sending ? 'Sending...' : 'Send High Alert'),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ModerateFormView extends StatefulWidget {
  const _ModerateFormView({
    required this.user,
    required this.firestoreService,
    required this.onCancel,
    required this.onSent,
  });

  final AppUser user;
  final FirestoreService firestoreService;
  final VoidCallback onCancel;
  final VoidCallback onSent;

  @override
  State<_ModerateFormView> createState() => _ModerateFormViewState();
}

class _ModerateFormViewState extends State<_ModerateFormView> {
  final _msg = TextEditingController(
    text: 'Need non-critical medical assistance.',
  );
  bool _sending = false;

  @override
  void dispose() {
    _msg.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => _sending = true);
    await widget.firestoreService.createSosAlert(
      user: widget.user,
      message: _msg.text.trim(),
      address: widget.user.address ?? 'Current location unavailable.',
      priority: 'MODERATE',
    );
    if (!mounted) return;
    setState(() => _sending = false);
    widget.onSent();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFFBC02D).withOpacity(0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.info_outline_rounded,
                color: Color(0xFFFBC02D),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Moderate Emergency',
                style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _msg,
          maxLines: 4,
          style: const TextStyle(color: AppColors.navy),
          decoration: InputDecoration(
            labelText: 'Incident description',
            labelStyle: TextStyle(color: AppColors.navy.withOpacity(0.7)),
            hintText: 'Describe your emergency...',
            hintStyle: TextStyle(color: AppColors.navy.withOpacity(0.4)),
            filled: true,
            fillColor: AppColors.navy.withOpacity(0.04),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.navy.withOpacity(0.18)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          maxLines: 1,
          style: const TextStyle(color: AppColors.navy),
          decoration: InputDecoration(
            labelText: 'Location (optional)',
            labelStyle: TextStyle(color: AppColors.navy.withOpacity(0.7)),
            hintText: 'Enter your location...',
            hintStyle: TextStyle(color: AppColors.navy.withOpacity(0.4)),
            filled: true,
            fillColor: AppColors.navy.withOpacity(0.04),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.navy.withOpacity(0.18)),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _sending ? null : widget.onCancel,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.navy,
                  side: BorderSide(color: AppColors.navy.withOpacity(0.35)),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Cancel'),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: _sending ? null : _send,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFBC02D),
                  foregroundColor: Colors.white,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(_sending ? 'Sending...' : 'Submit Emergency'),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.level, required this.onClose});

  final EmergencyLevel? level;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final icon = level == EmergencyLevel.critical
        ? Icons.sos_rounded
        : level == EmergencyLevel.high
        ? Icons.warning_rounded
        : Icons.check_circle_rounded;
    final color = level == EmergencyLevel.critical
        ? const Color(0xFFD32F2F)
        : level == EmergencyLevel.high
        ? const Color(0xFFF57C00)
        : const Color(0xFFFBC02D);
    final title = level == EmergencyLevel.critical
        ? 'Emergency Signal Sent'
        : level == EmergencyLevel.high
        ? 'High Alert Sent'
        : 'Moderate Alert Sent';
    final message = level == EmergencyLevel.critical
        ? 'Your location has been sent to the nearest health responder. Help is on the way.'
        : level == EmergencyLevel.high
        ? 'Your location has been forwarded to emergency responders. Stay safe.'
        : 'Your emergency details and location have been submitted.';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: color.withOpacity(0.18),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 44),
        ),
        const SizedBox(height: 14),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.navy.withOpacity(0.65),
            height: 1.4,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: onClose,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.teal,
              foregroundColor: Colors.white,
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Close'),
            ),
          ),
        ),
      ],
    );
  }
}

class _GearShifterSelector extends StatelessWidget {
  const _GearShifterSelector({
    required GlobalKey trackKey,
    required this.selectorSize,
    required this.knobPosition,
    required this.isDragging,
    required this.snapController,
    required this.pulseAnimation,
    required this.heartbeatStage,
    required this.snapStart,
    required this.snapEnd,
    required this.snapColor,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
  }) : super(key: trackKey);

  final double selectorSize;
  final Offset knobPosition;
  final bool isDragging;
  final AnimationController snapController;
  final Animation<double> pulseAnimation;
  final int heartbeatStage;
  final Offset snapStart;
  final Offset snapEnd;
  final Color snapColor;
  final GestureDragStartCallback onPanStart;
  final GestureDragUpdateCallback onPanUpdate;
  final GestureDragEndCallback onPanEnd;

  @override
  Widget build(BuildContext context) {
    final selectorSize = this.selectorSize;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanStart: onPanStart,
      onPanUpdate: onPanUpdate,
      onPanEnd: onPanEnd,
      onPanCancel: () => onPanEnd(DragEndDetails()),
      child: Container(
        width: selectorSize,
        height: selectorSize,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Stack(
          children: [
            CustomPaint(
              size: Size(selectorSize, selectorSize),
              painter: _GearShifterPainter(
                knobOffset: knobPosition,
                snapProgress: snapController.value,
                snapStart: snapStart,
                snapEnd: snapEnd,
                snapColor: snapColor,
              ),
            ),
            Center(
              child: Transform.translate(
                offset: knobPosition,
                child: _GearKnob(
                  isDragging: isDragging,
                  pulseAnimation: pulseAnimation,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GearShifterPainter extends CustomPainter {
  _GearShifterPainter({
    required this.knobOffset,
    required this.snapProgress,
    required this.snapStart,
    required this.snapEnd,
    required this.snapColor,
  });

  final Offset knobOffset;
  final double snapProgress;
  final Offset snapStart;
  final Offset snapEnd;
  final Color snapColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final nodeDistance = size.width * 0.28;
    final moderateNode = Offset(center.dx - nodeDistance, center.dy);
    final criticalNode = Offset(center.dx, center.dy);
    final highNode = Offset(center.dx + nodeDistance, center.dy);

    final trackPaint = Paint()
      ..color = const Color(0xFFE3E3E3)
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(moderateNode, highNode, trackPaint);

    final highlightPaint = Paint()
      ..color = const Color(0xFFEFEFEF)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(moderateNode, highNode, highlightPaint);

    final nodePaint = Paint()..style = PaintingStyle.fill;
    const nodeRadius = 8.0;

    nodePaint.color = const Color(0xFFFBC02D);
    canvas.drawCircle(moderateNode, nodeRadius, nodePaint);
    nodePaint.color = const Color(0xFFD32F2F);
    canvas.drawCircle(criticalNode, nodeRadius, nodePaint);
    nodePaint.color = const Color(0xFFF57C00);
    canvas.drawCircle(highNode, nodeRadius, nodePaint);

    final labelStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: AppColors.navy,
    );

    _drawLabel(
      canvas,
      'MODERATE',
      moderateNode.translate(0, 26),
      const Color(0xFFFBC02D),
      labelStyle,
      size,
    );
    _drawLabel(
      canvas,
      'CRITICAL',
      criticalNode.translate(0, 26),
      const Color(0xFFD32F2F),
      labelStyle,
      size,
    );
    _drawLabel(
      canvas,
      'HIGH',
      highNode.translate(0, 26),
      const Color(0xFFF57C00),
      labelStyle,
      size,
    );

    if (snapProgress > 0.0) {
      final trackPath = Path()
        ..moveTo(snapStart.dx, snapStart.dy)
        ..lineTo(snapEnd.dx, snapEnd.dy);
      final dashPaint = Paint()
        ..color = snapColor.withOpacity(0.6)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;
      final current =
          Offset.lerp(snapStart, snapEnd, snapProgress) ?? snapStart;
      canvas.drawLine(snapStart, current, dashPaint);
    }
  }

  void _drawLabel(
    Canvas canvas,
    String text,
    Offset offset,
    Color color,
    TextStyle style,
    Size canvasSize,
  ) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: style.copyWith(color: color),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    final double x = offset.dx - textPainter.width / 2;
    final double y = offset.dy;
    final double clampedX = x.clamp(
      8.0,
      canvasSize.width - textPainter.width - 8.0,
    );
    final double clampedY = y.clamp(
      8.0,
      canvasSize.height - textPainter.height - 8.0,
    );
    textPainter.paint(canvas, Offset(clampedX, clampedY));
  }

  @override
  bool shouldRepaint(covariant _GearShifterPainter oldDelegate) {
    return oldDelegate.knobOffset != knobOffset ||
        oldDelegate.snapProgress != snapProgress;
  }
}

class _GearKnob extends StatelessWidget {
  const _GearKnob({required this.isDragging, required this.pulseAnimation});
  final bool isDragging;
  final Animation<double> pulseAnimation;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(
          color: isDragging
              ? const Color(0xFFD32F2F)
              : AppColors.navy.withOpacity(0.2),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD32F2F).withOpacity(isDragging ? 0.22 : 0.08),
            blurRadius: isDragging ? 16 : 8 + pulseAnimation.value * 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.drag_indicator_rounded,
          color: isDragging ? const Color(0xFFD32F2F) : AppColors.navy,
          size: 24,
        ),
      ),
    );
  }
}

class _CriticalPulseRing extends StatelessWidget {
  const _CriticalPulseRing({
    required this.pulseAnimation,
    required this.heartbeatStage,
  });

  final Animation<double> pulseAnimation;
  final int heartbeatStage;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseAnimation,
      builder: (context, child) {
        final ring1 = Curves.easeOut.transform(pulseAnimation.value);
        final ring2 = Curves.easeOut.transform((pulseAnimation.value + 0.5) % 1.0);

        return Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              _buildRing(ring1, 66.0, 34.0),
              _buildRing(ring2, 66.0, 34.0),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRing(double progress, double baseSize, double range) {
    final size = baseSize + progress * range;
    final opacity = (1 - progress) * 0.28;
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFFD32F2F).withOpacity(opacity),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD32F2F).withOpacity(opacity * 0.7),
              blurRadius: 12 + progress * 16,
              spreadRadius: progress * 4,
            ),
          ],
        ),
      ),
    );
  }
}

class _HeartbeatDot extends StatelessWidget {
  const _HeartbeatDot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? const Color(0xFFD32F2F) : AppColors.navy.withOpacity(0.18),
        boxShadow: active
            ? [
                BoxShadow(
                  color: const Color(0xFFD32F2F).withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
    );
  }
}

class _YTrackSelector extends StatelessWidget {
  const _YTrackSelector({
    required this.key,
    required this.circleSize,
    required this.knobPosition,
    required this.isDragging,
    required this.snapController,
    required this.snapStart,
    required this.snapEnd,
    required this.snapColor,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
  }) : super(key: key);

  final GlobalKey key;
  final double circleSize;
  final Offset knobPosition;
  final bool isDragging;
  final AnimationController snapController;
  final Offset snapStart;
  final Offset snapEnd;
  final Color snapColor;
  final GestureDragStartCallback onPanStart;
  final GestureDragUpdateCallback onPanUpdate;
  final GestureDragEndCallback onPanEnd;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onPanStart: onPanStart,
          onPanUpdate: onPanUpdate,
          onPanEnd: onPanEnd,
          onPanCancel: () => onPanEnd(DragEndDetails()),
          child: SizedBox(
            height: double.infinity,
            child: Stack(
              children: [
                CustomPaint(
                  size: Size.infinite,
                  painter: _YTrackPainter(
                    circleCenter:
                        Offset(
                          constraints.maxWidth / 2,
                          constraints.maxHeight * 0.5,
                        ) +
                        knobPosition,
                    circleRadius: circleSize / 2,
                  ),
                ),
                AnimatedBuilder(
                  animation: snapController,
                  builder: (context, child) {
                    final progress = snapController.value;
                    if (progress > 0 && snapEnd != Offset.zero) {
                      return CustomPaint(
                        size: Size.infinite,
                        painter: _SnapTrackPainter(
                          progress: progress,
                          startOffset: snapStart,
                          endOffset: snapEnd,
                          color: snapColor,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                Positioned.fill(
                  child: Center(
                    child: Transform.translate(
                      offset: knobPosition,
                      child: _DraggingKnob(
                        size: circleSize,
                        isDragging: isDragging,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _YTrackPainter extends CustomPainter {
  _YTrackPainter({required this.circleCenter, required this.circleRadius});

  final Offset circleCenter;
  final double circleRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.navy.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final stemTop = size.height * 0.10;
    final barY = size.height * 0.85;
    final junction = Offset(size.width / 2, barY);
    final leftEndpoint = Offset(size.width * 0.25, barY);
    final rightEndpoint = Offset(size.width * 0.75, barY);
    final topEndpoint = Offset(size.width / 2, stemTop);

    canvas.drawLine(leftEndpoint, rightEndpoint, paint);
    canvas.drawLine(topEndpoint, junction, paint);

    final dotPaint = Paint()
      ..color = AppColors.navy.withOpacity(0.15)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(leftEndpoint, 6, dotPaint);
    canvas.drawCircle(rightEndpoint, 6, dotPaint);
    canvas.drawCircle(junction, 6, dotPaint);
    canvas.drawCircle(topEndpoint, 6, dotPaint);

    if (circleCenter != junction) {
      canvas.drawCircle(
        circleCenter,
        circleRadius * 0.15,
        dotPaint..color = AppColors.navy.withOpacity(0.4),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _YTrackPainter oldDelegate) {
    return oldDelegate.circleCenter != circleCenter;
  }
}

class _SnapTrackPainter extends CustomPainter {
  _SnapTrackPainter({
    required this.progress,
    required this.startOffset,
    required this.endOffset,
    required this.color,
  });

  final double progress;
  final Offset startOffset;
  final Offset endOffset;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final current = Offset.lerp(
      startOffset,
      endOffset,
      Curves.easeInOut.transform(progress),
    )!;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(startOffset, current, paint);

    final glowPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawLine(startOffset, current, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _SnapTrackPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _DraggingKnob extends StatelessWidget {
  const _DraggingKnob({required this.size, required this.isDragging});

  final double size;
  final bool isDragging;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDragging ? Colors.white : const Color(0xFFF5F7FB),
        border: Border.all(
          color: isDragging
              ? AppColors.navy.withOpacity(0.2)
              : AppColors.navy.withOpacity(0.15),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDragging ? 0.25 : 0.12),
            blurRadius: isDragging ? 20 : 16,
            spreadRadius: isDragging ? 2 : 1,
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.drag_indicator_rounded,
          color: AppColors.navy,
          size: size * 0.32,
        ),
      ),
    );
  }
}

class _ZoneLabel extends StatelessWidget {
  const _ZoneLabel({
    required this.label,
    required this.color,
    this.left = false,
    this.top = false,
    this.fontSize = 12,
  });

  final String label;
  final Color color;
  final bool left;
  final bool top;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: left ? MainAxisAlignment.start : MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: fontSize,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}
