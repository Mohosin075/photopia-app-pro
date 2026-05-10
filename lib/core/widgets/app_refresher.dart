import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class AppRefresher extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final Color? color;
  final Color? backgroundColor;

  const AppRefresher({
    super.key,
    required this.child,
    required this.onRefresh,
    this.color,
    this.backgroundColor,
  });

  @override
  State<AppRefresher> createState() => _AppRefresherState();
}

class _AppRefresherState extends State<AppRefresher> with SingleTickerProviderStateMixin {
  double _dragOffset = 0;
  bool _isRefreshing = false;
  final double _triggerOffset = 80;
  bool _canTrigger = false;

  void _handleScrollNotification(ScrollNotification notification) {
    if (_isRefreshing) return;

    if (notification is ScrollUpdateNotification) {
      // Over-scroll detection
      if (notification.metrics.pixels < 0) {
        setState(() {
          _dragOffset = -notification.metrics.pixels;
        });
        
        if (_dragOffset >= _triggerOffset && !_canTrigger) {
          _canTrigger = true;
          HapticFeedback.mediumImpact();
        } else if (_dragOffset < _triggerOffset && _canTrigger) {
          _canTrigger = false;
        }
      } else {
        if (_dragOffset != 0) {
          setState(() {
            _dragOffset = 0;
            _canTrigger = false;
          });
        }
      }
    } else if (notification is ScrollEndNotification) {
      if (_canTrigger && !_isRefreshing) {
        _startRefresh();
      } else {
        setState(() {
          _dragOffset = 0;
          _canTrigger = false;
        });
      }
    }
  }

  Future<void> _startRefresh() async {
    if (_isRefreshing) return;

    debugPrint('🔄 [AppRefresher] Starting refresh...');
    
    setState(() {
      _isRefreshing = true;
      _dragOffset = _triggerOffset;
      _canTrigger = false;
    });

    try {
      // Ensure the refresh animation lasts at least 1 second for a premium feel
      await Future.wait([
        widget.onRefresh(),
        Future.delayed(const Duration(milliseconds: 1200)),
      ]);
      debugPrint('✅ [AppRefresher] Refresh completed.');
    } catch (e) {
      debugPrint('❌ [AppRefresher] Refresh failed: $e');
    }

    if (mounted) {
      setState(() {
        _isRefreshing = false;
        _dragOffset = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double pullProgress = (_dragOffset / _triggerOffset).clamp(0.0, 1.0);
    final double opacity = pullProgress;
    final double scale = 0.8 + (0.2 * pullProgress);

    return Stack(
      children: [
        // Content
        ScrollConfiguration(
          behavior: const ScrollBehavior().copyWith(
            overscroll: true,
            physics: const BouncingScrollPhysics(),
          ),
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              _handleScrollNotification(notification);
              return false;
            },
            child: widget.child,
          ),
        ),
        
        // Refresher Overlay (Premium Floating Indicator)
        if (_dragOffset > 0 || _isRefreshing)
          Positioned(
            top: MediaQuery.of(context).padding.top + 15,
            left: 0,
            right: 0,
            child: Center(
              child: Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: scale,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (widget.backgroundColor ?? Theme.of(context).colorScheme.surface).withOpacity(0.8),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: _isRefreshing
                            ? SpinKitRing(
                                color: widget.color ?? Theme.of(context).colorScheme.primary,
                                size: 24,
                                lineWidth: 2,
                              )
                            : Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      value: pullProgress,
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        widget.color ?? Theme.of(context).colorScheme.primary,
                                      ),
                                      backgroundColor: Colors.transparent,
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_downward_rounded,
                                    size: 14,
                                    color: (widget.color ?? Theme.of(context).colorScheme.primary).withOpacity(pullProgress),
                                  ),
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
    );
  }
}
