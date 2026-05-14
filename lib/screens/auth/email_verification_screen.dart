// lib/screens/auth/email_verification_screen.dart — SkillBridge AI

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main_nav.dart';
import '../../services/app_state.dart';
import 'package:provider/provider.dart';
import 'login_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final String name;

  const EmailVerificationScreen({
    super.key,
    required this.email,
    required this.name,
  });

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen>
    with TickerProviderStateMixin {
  // ── Timers ─────────────────────────────────────────────────────────────────
  Timer? _autoCheckTimer;      // polls Firebase every 4s silently
  Timer? _resendCooldownTimer; // 60s cooldown after resend
  Timer? _countdownTimer;      // 10s countdown in fail banner

  int _resendCooldown = 0;
  bool _isCheckingVerification = false;
  bool _isResending = false;

  // Screen states: 'waiting' | 'success'
  String _screenState = 'waiting';

  // Not-verified fail banner
  int _failCountdown = 10;
  bool _showFailBanner = false;

  // ── Animations ─────────────────────────────────────────────────────────────
  late AnimationController _pulseCtrl;
  late AnimationController _floatCtrl;
  late AnimationController _shimmerCtrl;
  late AnimationController _successCtrl;
  late AnimationController _failCtrl;

  late Animation<double> _pulseAnim;
  late Animation<double> _floatAnim;
  late Animation<double> _shimmerAnim;
  late Animation<double> _successScaleAnim;
  late Animation<double> _successFadeAnim;
  late Animation<double> _failShakeAnim;

  // ── Colors ─────────────────────────────────────────────────────────────────
  static const _deepNavy  = Color(0xFF0A0F1E);
  static const _royalBlue = Color(0xFF1A56DB);
  static const _skyBlue   = Color(0xFF0EA5E9);
  static const _cyan      = Color(0xFF06B6D4);
  static const _mint      = Color(0xFF10B981);
  static const _coral     = Color(0xFFFF6B6B);
  static const _amber     = Color(0xFFF59E0B);
  static const _violet    = Color(0xFF8B5CF6);
  static const _white     = Colors.white;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAutoCheck();
    // 30s initial cooldown (email was sent by register screen)
    _startResendCooldown(30);
  }

  void _initAnimations() {
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _floatCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3200))
      ..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -10, end: 10).animate(
        CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));

    _shimmerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat();
    _shimmerAnim = Tween<double>(begin: -1.0, end: 2.0).animate(
        CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut));

    _successCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _successScaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _successCtrl, curve: Curves.elasticOut));
    _successFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _successCtrl, curve: Curves.easeIn));

    _failCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _failShakeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _failCtrl, curve: Curves.elasticIn));
  }

  // ── Auto-poll every 4s ─────────────────────────────────────────────────────
  void _startAutoCheck() {
    _autoCheckTimer =
        Timer.periodic(const Duration(seconds: 4), (_) => _silentCheck());
  }

  Future<void> _silentCheck() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      await user.reload();
      if (FirebaseAuth.instance.currentUser?.emailVerified == true && mounted) {
        _autoCheckTimer?.cancel();
        await _goHome();
      }
    } catch (_) {}
  }

  void _startResendCooldown(int seconds) {
    setState(() => _resendCooldown = seconds);
    _resendCooldownTimer?.cancel();
    _resendCooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _resendCooldown--);
      if (_resendCooldown <= 0) t.cancel();
    });
  }

  // ── Navigate home (verified) ───────────────────────────────────────────────
  Future<void> _goHome() async {
  if (!mounted) return;

  final user = FirebaseAuth.instance.currentUser;

  // ✅ ADD THIS PART HERE
  if (user != null) {
    await FirebaseFirestore.instance
        .collection('User')
        .doc(user.uid)
        .update({
      'isVerified': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  _autoCheckTimer?.cancel();
  setState(() => _screenState = 'success');
  _successCtrl.forward();
  HapticFeedback.heavyImpact();

  await Future.delayed(const Duration(milliseconds: 2500));
  if (!mounted) return;

  await context.read<AppState>().login(
        name: widget.name,
        email: widget.email,
      );

  if (!mounted) return;
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => const MainNav()),
    (_) => false,
  );
}

  // ── Navigate to login (not verified / back) ───────────────────────────────
  Future<void> _goLogin() async {
    if (!mounted) return;
    _autoCheckTimer?.cancel();
    _countdownTimer?.cancel();
    try { await FirebaseAuth.instance.signOut(); } catch (_) {}
    if (!mounted) return;
    _showSnack('Please verify your email first, then log in.',
        icon: Icons.info_outline_rounded, color: _amber);
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  // ── Manual verify tap ─────────────────────────────────────────────────────
  Future<void> _manualCheck() async {
    if (_isCheckingVerification) return;
    setState(() => _isCheckingVerification = true);
    HapticFeedback.mediumImpact();
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) { setState(() => _isCheckingVerification = false); return; }
      await user.reload();
      if (FirebaseAuth.instance.currentUser?.emailVerified == true && mounted) {
        setState(() => _isCheckingVerification = false);
        await _goHome();
      } else {
        // Not verified — show fail banner with 10s countdown
        setState(() {
          _isCheckingVerification = false;
          _showFailBanner = true;
          _failCountdown = 10;
        });
        _failCtrl.forward(from: 0);
        HapticFeedback.heavyImpact();
        _countdownTimer?.cancel();
        _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
          if (!mounted) { t.cancel(); return; }
          setState(() => _failCountdown--);
          if (_failCountdown <= 0) {
            t.cancel();
            setState(() => _showFailBanner = false);
          }
        });
        _showSnack('Not verified yet. Open your inbox and click the link.',
            icon: Icons.mail_outline_rounded, color: _amber);
      }
    } catch (e) {
      setState(() => _isCheckingVerification = false);
      _showSnack('Check failed. Please try again.', color: _coral);
    }
  }

  // ── Resend email ───────────────────────────────────────────────────────────
  Future<void> _resend() async {
    if (_resendCooldown > 0 || _isResending) return;
    setState(() => _isResending = true);
    HapticFeedback.mediumImpact();
    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
      _showSnack('Verification email resent to ${widget.email}',
          icon: Icons.mark_email_read_rounded, color: _mint);
      _startResendCooldown(60);
    } catch (e) {
      _showSnack('Failed to resend. Try again.', color: _coral);
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  void _showSnack(String msg,
      {Color color = _royalBlue, IconData icon = Icons.info_outline_rounded}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(icon, color: _white, size: 18),
        const SizedBox(width: 10),
        Expanded(
            child: Text(msg,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 13, color: _white))),
      ]),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    ));
  }

  @override
  void dispose() {
    _autoCheckTimer?.cancel();
    _resendCooldownTimer?.cancel();
    _countdownTimer?.cancel();
    _pulseCtrl.dispose();
    _floatCtrl.dispose();
    _shimmerCtrl.dispose();
    _successCtrl.dispose();
    _failCtrl.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: _deepNavy,
      body: Stack(children: [
        _buildBg(size),
        SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: _screenState == 'success'
                ? _buildSuccess()
                : _buildWaiting(size),
          ),
        ),
      ]),
    );
  }

  // ── Background ─────────────────────────────────────────────────────────────
  Widget _buildBg(Size size) {
    return Stack(children: [
      Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_deepNavy, Color(0xFF050D20), Color(0xFF0A0F1E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      Positioned(
        top: -80, left: -80,
        child: AnimatedBuilder(
          animation: _floatAnim,
          builder: (_, __) => Transform.translate(
            offset: Offset(_floatAnim.value * 0.5, _floatAnim.value),
            child: Container(
              width: 320, height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  _royalBlue.withOpacity(0.22),
                  _royalBlue.withOpacity(0.0),
                ]),
              ),
            ),
          ),
        ),
      ),
      Positioned(
        bottom: -60, right: -60,
        child: AnimatedBuilder(
          animation: _floatAnim,
          builder: (_, __) => Transform.translate(
            offset: Offset(-_floatAnim.value * 0.4, -_floatAnim.value * 0.6),
            child: Container(
              width: 280, height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  _cyan.withOpacity(0.16),
                  _cyan.withOpacity(0.0),
                ]),
              ),
            ),
          ),
        ),
      ),
      ..._dots(size),
    ]);
  }

  List<Widget> _dots(Size size) {
    final data = [
      (0.12, 0.10, 4.0, _cyan,   0.0),
      (0.88, 0.07, 3.0, _violet, 0.5),
      (0.04, 0.42, 5.0, _skyBlue,1.0),
      (0.93, 0.38, 3.5, _mint,   0.3),
      (0.22, 0.88, 4.0, _coral,  0.8),
      (0.76, 0.82, 3.0, _amber,  0.2),
      (0.50, 0.04, 2.5, _white,  0.6),
    ];
    return data.map((d) {
      final (x, y, r, color, delay) = d;
      return Positioned(
        left: size.width * x,
        top: size.height * y,
        child: AnimatedBuilder(
          animation: _floatAnim,
          builder: (_, __) {
            final off =
                math.sin((_floatAnim.value + delay * math.pi) * math.pi) * 8;
            return Transform.translate(
              offset: Offset(0, off),
              child: Container(
                width: r * 2, height: r * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.55),
                  boxShadow: [
                    BoxShadow(
                        color: color.withOpacity(0.6),
                        blurRadius: r * 2,
                        spreadRadius: r * 0.5)
                  ],
                ),
              ),
            );
          },
        ),
      );
    }).toList();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // WAITING STATE
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildWaiting(Size size) {
    return SingleChildScrollView(
      key: const ValueKey('waiting'),
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const SizedBox(height: 48),

          // Back button → login
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: _goLogin,
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: _white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _white.withOpacity(0.15)),
                ),
                child: const Icon(Icons.arrow_back_rounded,
                    color: _white, size: 18),
              ),
            ),
          ),

          const SizedBox(height: 36),
          _buildEnvelope(),
          const SizedBox(height: 32),

          // Headline
          Text('Check Your Inbox',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: _white,
                  letterSpacing: -0.5),
              textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Text('We sent a verification link to',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  color: _white.withOpacity(0.50)),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),

          // Email pill
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                _royalBlue.withOpacity(0.25),
                _cyan.withOpacity(0.15),
              ]),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                  color: _skyBlue.withOpacity(0.35), width: 1.5),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.alternate_email_rounded,
                  color: _skyBlue, size: 16),
              const SizedBox(width: 8),
              Text(widget.email,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _skyBlue)),
            ]),
          ),

          const SizedBox(height: 24),

          // Auto-polling indicator
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _royalBlue.withOpacity(0.10),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: _royalBlue.withOpacity(0.25)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              SizedBox(
                width: 14, height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(_skyBlue),
                ),
              ),
              const SizedBox(width: 10),
              Text('Watching for verification automatically…',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: _skyBlue,
                      fontWeight: FontWeight.w600)),
            ]),
          ),

          const SizedBox(height: 20),

          // Fail banner (conditionally shown)
          if (_showFailBanner) ...[
            _buildFailBanner(),
            const SizedBox(height: 4),
          ],

          // Steps card
          _buildStepsCard(),
          const SizedBox(height: 28),

          // ── GREEN: I've Verified button ──────────────────────────────────
          _buildVerifiedBtn(),
          const SizedBox(height: 14),

          // ── ORANGE: Resend button ────────────────────────────────────────
          _buildResendBtn(),
          const SizedBox(height: 18),

          // Go to login text link
          GestureDetector(
            onTap: _goLogin,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: _white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _white.withOpacity(0.10)),
              ),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.login_rounded,
                        color: _white.withOpacity(0.50), size: 16),
                    const SizedBox(width: 8),
                    Text('Already verified? Go to Login',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: _white.withOpacity(0.50),
                            fontWeight: FontWeight.w600)),
                  ]),
            ),
          ),

          const SizedBox(height: 16),
          Text(
            "Didn't get the email? Check your spam or junk folder.",
            style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: _white.withOpacity(0.28),
                height: 1.6),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // SDG badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _mint.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _mint.withOpacity(0.25)),
            ),
            child: Text(
              ' Supporting UN SDG-8: Decent Work & Economic Growth',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: _mint,
                  fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 36),
        ],
      ),
    );
  }

  // ── Envelope illustration ─────────────────────────────────────────────────
  Widget _buildEnvelope() {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (_, __) => Transform.scale(
        scale: _pulseAnim.value,
        child: Container(
          width: 130, height: 130,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                _royalBlue.withOpacity(0.28),
                _cyan.withOpacity(0.10),
                Colors.transparent,
              ],
              stops: const [0.0, 0.6, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                  color: _royalBlue.withOpacity(0.40),
                  blurRadius: 40, spreadRadius: 8),
              BoxShadow(
                  color: _cyan.withOpacity(0.20),
                  blurRadius: 60),
            ],
          ),
          child: Center(
            child: Stack(alignment: Alignment.center, children: [
              Container(
                width: 96, height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: _skyBlue.withOpacity(0.30), width: 1.5),
                  gradient: LinearGradient(
                    colors: [
                      _royalBlue.withOpacity(0.20),
                      _cyan.withOpacity(0.15),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              ShaderMask(
                shaderCallback: (b) => const LinearGradient(
                  colors: [_skyBlue, _cyan, _mint],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(b),
                child: const Icon(Icons.mark_email_unread_rounded,
                    size: 52, color: _white),
              ),
              Positioned(
                top: 14, right: 14,
                child: AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (_, __) => Container(
                    width: 14, height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _coral,
                      boxShadow: [
                        BoxShadow(
                          color: _coral.withOpacity(
                              0.6 * _pulseCtrl.value + 0.2),
                          blurRadius: 8, spreadRadius: 2,
                        )
                      ],
                    ),
                    child: const Center(
                        child: Text('1',
                            style: TextStyle(
                                color: _white,
                                fontSize: 8,
                                fontWeight: FontWeight.w800))),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  // ── Fail banner ───────────────────────────────────────────────────────────
  Widget _buildFailBanner() {
    return AnimatedBuilder(
      animation: _failShakeAnim,
      builder: (_, child) => Transform.translate(
        offset: Offset(
            math.sin(_failShakeAnim.value * math.pi * 5) * 6.0, 0),
        child: child,
      ),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _coral.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _coral.withOpacity(0.40), width: 1.5),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                color: _coral.withOpacity(0.20), shape: BoxShape.circle),
            child: const Icon(Icons.error_outline_rounded,
                color: _coral, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Email not verified yet',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: _coral)),
                  const SizedBox(height: 4),
                  Text(
                    'Open your inbox, click the link, then tap '
                    '"I\'ve Verified My Email" again.\n'
                    'Banner closes in $_failCountdown second'
                    '${_failCountdown == 1 ? '' : 's'}.',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: _white.withOpacity(0.60),
                        height: 1.5),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _failCountdown / 10.0,
                      backgroundColor: _coral.withOpacity(0.15),
                      valueColor:
                          AlwaysStoppedAnimation(_coral.withOpacity(0.70)),
                      minHeight: 4,
                    ),
                  ),
                ]),
          ),
          GestureDetector(
            onTap: () {
              _countdownTimer?.cancel();
              setState(() => _showFailBanner = false);
            },
            child: Icon(Icons.close_rounded,
                color: _white.withOpacity(0.38), size: 18),
          ),
        ]),
      ),
    );
  }

  // ── Steps card ────────────────────────────────────────────────────────────
  Widget _buildStepsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _white.withOpacity(0.09)),
      ),
      child: Column(children: [
        _step(Icons.touch_app_rounded, 'Open the email',
            'Tap the verification link inside the email.', _violet),
        const SizedBox(height: 14),
        _step(Icons.verified_rounded, "Tap \"I've Verified\" below",
            'Come back here after clicking the link.', _mint),
        const SizedBox(height: 14),
        _step(Icons.rocket_launch_rounded, 'Start your career journey',
            'Get full access to all SkillBridge AI features.', _amber),
      ]),
    );
  }

  Widget _step(IconData icon, String title, String sub, Color color) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _white)),
              const SizedBox(height: 2),
              Text(sub,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: _white.withOpacity(0.42),
                      height: 1.4)),
            ]),
      ),
    ]);
  }

  // ── GREEN: I've Verified button ────────────────────────────────────────────
  Widget _buildVerifiedBtn() {
    final loading = _isCheckingVerification;
    return GestureDetector(
      onTap: loading ? null : _manualCheck,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity, height: 58,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: loading
                ? [_mint.withOpacity(0.45), const Color(0xFF059669).withOpacity(0.45)]
                : [_mint, const Color(0xFF059669)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: loading
              ? []
              : [
                  BoxShadow(
                      color: _mint.withOpacity(0.45),
                      blurRadius: 20, offset: const Offset(0, 8)),
                  BoxShadow(
                      color: _mint.withOpacity(0.20),
                      blurRadius: 40, offset: const Offset(0, 16)),
                ],
        ),
        child: Stack(alignment: Alignment.center, children: [
          // Shimmer overlay
          if (!loading)
            AnimatedBuilder(
              animation: _shimmerAnim,
              builder: (_, __) => ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    begin: Alignment(_shimmerAnim.value - 1, 0),
                    end: Alignment(_shimmerAnim.value, 0),
                    colors: [
                      Colors.transparent,
                      _white.withOpacity(0.13),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ).createShader(bounds),
                  child: Container(color: _white),
                ),
              ),
            ),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (loading)
              const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(
                      color: _white, strokeWidth: 2.5))
            else
              const Icon(Icons.verified_rounded, color: _white, size: 22),
            const SizedBox(width: 10),
            Text(
              loading ? 'Checking…' : "I've Verified My Email",
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _white,
                  letterSpacing: 0.3),
            ),
          ]),
        ]),
      ),
    );
  }

  // ── ORANGE: Resend button ──────────────────────────────────────────────────
  Widget _buildResendBtn() {
    final cooldown = _resendCooldown > 0;
    final loading = _isResending;
    final disabled = cooldown || loading;

    return GestureDetector(
      onTap: disabled ? null : _resend,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity, height: 58,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: disabled
                ? [
                    const Color(0xFFFF6B6B).withOpacity(0.35),
                    const Color(0xFFFF8C42).withOpacity(0.35),
                  ]
                : [const Color(0xFFFF6B6B), const Color(0xFFFF8C42)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: disabled
                ? _coral.withOpacity(0.18)
                : _coral.withOpacity(0.45),
            width: 1.5,
          ),
          boxShadow: disabled
              ? []
              : [
                  BoxShadow(
                      color: _coral.withOpacity(0.40),
                      blurRadius: 20, offset: const Offset(0, 8)),
                  BoxShadow(
                      color: const Color(0xFFFF8C42).withOpacity(0.20),
                      blurRadius: 40, offset: const Offset(0, 16)),
                ],
        ),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (loading)
                const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                        color: _white, strokeWidth: 2.5))
              else if (cooldown)
                Icon(Icons.timer_rounded,
                    color: _white.withOpacity(0.55), size: 20)
              else
                const Icon(Icons.send_rounded, color: _white, size: 20),
              const SizedBox(width: 10),
              Text(
                loading
                    ? 'Sending…'
                    : cooldown
                        ? 'Resend in ${_resendCooldown}s'
                        : 'Resend Verification Email',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: disabled ? _white.withOpacity(0.50) : _white,
                    letterSpacing: 0.3),
              ),
            ]),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SUCCESS STATE
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildSuccess() {
    return Center(
      key: const ValueKey('success'),
      child: FadeTransition(
        opacity: _successFadeAnim,
        child: ScaleTransition(
          scale: _successScaleAnim,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 130, height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      _mint.withOpacity(0.28),
                      _mint.withOpacity(0.06),
                    ]),
                    boxShadow: [
                      BoxShadow(
                          color: _mint.withOpacity(0.55),
                          blurRadius: 55, spreadRadius: 12),
                    ],
                  ),
                  child: const Icon(Icons.verified_rounded,
                      color: _mint, size: 68),
                ),
                const SizedBox(height: 30),
                Text('Email Verified! 🎉',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: _white),
                    textAlign: TextAlign.center),
                const SizedBox(height: 12),
                Text(
                  'Welcome to SkillBridge AI, '
                  '${widget.name.split(' ').first}!\n'
                  'Taking you to your dashboard…',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      color: _white.withOpacity(0.52),
                      height: 1.65),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 36),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) {
                    return AnimatedBuilder(
                      animation: _pulseCtrl,
                      builder: (_, __) {
                        final s = i == 0
                            ? _pulseCtrl.value
                            : i == 1
                                ? (1 - _pulseCtrl.value) * 0.4 + 0.6
                                : _pulseCtrl.value * 0.5 + 0.5;
                        return Transform.scale(
                          scale: s,
                          child: Container(
                            width: 10, height: 10,
                            margin:
                                const EdgeInsets.symmetric(horizontal: 5),
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _mint.withOpacity(0.8)),
                          ),
                        );
                      },
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}