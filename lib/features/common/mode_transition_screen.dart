import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:async';
import 'package:photopia/controller/client/role_switch_controller.dart';
import 'package:photopia/controller/provider/provider_onboarding_controller.dart';
import 'package:provider/provider.dart';
import 'package:photopia/core/localization/app_localizations.dart';
import 'package:photopia/core/routes/app_routes.dart';

class ModeTransitionScreen extends StatefulWidget {
  final String targetRole; // 'client' or 'professional'
  final String targetRoute;
  final List<String>? selectedCategories;

  const ModeTransitionScreen({
    super.key,
    required this.targetRole,
    required this.targetRoute,
    this.selectedCategories,
  });

  @override
  State<ModeTransitionScreen> createState() => _ModeTransitionScreenState();
}

class _ModeTransitionScreenState extends State<ModeTransitionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.2), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 1.2, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 3.1415926535897932 * 2, // Full 360 degree rotation
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.repeat(); // Continuous rotation

    // Start API call with a minimum delay
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final startTime = DateTime.now();
      final roleController = context.read<RoleSwitchController>();

      // Perform the API call
      final success = await roleController.switchRole(
        widget.targetRole,
        specialties: widget.selectedCategories,
      );

      // Calculate how much time has passed
      final endTime = DateTime.now();
      final elapsed = endTime.difference(startTime);
      const minDuration = Duration(seconds: 3);

      // If API call was faster than minDuration, wait for the remaining time
      if (elapsed < minDuration) {
        await Future.delayed(minDuration - elapsed);
      }

      if (success && mounted) {
        bool needsOnboarding = false;

        // Check if this is a professional and onboarding is not done locally
        if (widget.targetRole == 'professional') {
          if (!ProviderOnboardingController.isOnboardingCompleted()) {
            // Verify with the server in case they logged in on a new device
            final bool serverCompleted =
                await ProviderOnboardingController.checkOnboardingStatusFromServer();
            if (serverCompleted) {
              await ProviderOnboardingController.markOnboardingCompleted();
              needsOnboarding = false;
            } else {
              needsOnboarding = true;
            }
          }
        }

        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            needsOnboarding ? AppRoutes.provider_onboarding : widget.targetRoute,
            (route) => false,
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.failedToSwitchMode),
          ),
        );
        Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String message = widget.targetRole == 'professional'
        ? context.l10n.switchingToProfessional
        : context.l10n.switchingToClient;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40.w),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.002) // Perspective
                        ..rotateY(_rotationAnimation.value),
                      child: Icon(
                        Icons.camera_alt_outlined,
                        size: 80.sp.clamp(60, 100),
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 32.h),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17.sp.clamp(15, 19),
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                  (index) => Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    child: _LoadingDot(delay: index * 0.2),
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

class _LoadingDot extends StatefulWidget {
  final double delay;
  const _LoadingDot({required this.delay});

  @override
  State<_LoadingDot> createState() => _LoadingDotState();
}

class _LoadingDotState extends State<_LoadingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _animation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    Future.delayed(Duration(milliseconds: (widget.delay * 1000).toInt()), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 6.w,
        height: 6.w,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurface,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
