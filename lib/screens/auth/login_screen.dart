// lib/screens/auth/login_screen.dart — SkillBridge AI

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/app_state.dart';
import '../../theme/app_theme.dart';
import '../main_nav.dart';
import 'register_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../auth/forget_password_screen.dart';

const String _defaultEmail = 'bb@gmail.com';
const String _defaultPassword = '123456';
const String _defaultName = 'Arafat Sakib';

// ── LinkedIn OAuth config ─────────────────────────────────────────────────
// Replace with your actual LinkedIn app credentials from developer.linkedin.com
const String _linkedInClientId = 'YOUR_LINKEDIN_CLIENT_ID';
const String _linkedInRedirectUri = 'skillbridge://linkedin-callback';
const String _linkedInScope = 'openid profile email';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController(text: _defaultEmail);
  final _passCtrl = TextEditingController(text: _defaultPassword);

  bool _obscurePass = true;
  bool _isLoading = false;
  bool _rememberMe = false;
  bool _showDemoCreds = false;

  // ── Auth clients ──────────────────────────────────────────────────────────
  // final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final LocalAuthentication _localAuth = LocalAuthentication();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );
  // ── Animations ────────────────────────────────────────────────────────────
  late AnimationController _animCtrl;
  late AnimationController _shakeCtrl;
  late AnimationController _pulseCtrl;

  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _shakeAnim;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));

    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _shakeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn),
    );

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.90, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _animCtrl.forward();
    _loadRememberMe();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _animCtrl.dispose();
    _shakeCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Remember-me ───────────────────────────────────────────────────────────
  Future<void> _loadRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    final remembered = prefs.getBool('rememberMe') ?? false;
    if (!remembered) return;
    final savedEmail = prefs.getString('rememberedEmail') ?? '';
    if (savedEmail.isNotEmpty && mounted) {
      setState(() {
        _emailCtrl.text = savedEmail;
        _rememberMe = true;
      });
    }
  }

  Future<void> _saveRememberMe(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('rememberMe', true);
    await prefs.setString('rememberedEmail', email);
  }

  Future<void> _clearRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('rememberMe', false);
    await prefs.remove('rememberedEmail');
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  void _triggerShake() {
    HapticFeedback.heavyImpact();
    _shakeCtrl.forward(from: 0.0);
  }

  void _showFloatingSnack(
    String message, {
    Color bgColor = const Color(0xFF1E293B),
    IconData icon = Icons.info_outline_rounded,
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message, style: const TextStyle(fontSize: 13)),
            ),
          ],
        ),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _navigateToHome({
    required String name,
    required String email,
  }) async {
    if (_rememberMe) {
      await _saveRememberMe(email.toLowerCase());
    } else {
      await _clearRememberMe();
    }
    HapticFeedback.mediumImpact();
    if (!mounted) return;
    await context.read<AppState>().login(name: name, email: email);
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNav()),
      );
    }
  }

  // ── Email/Password login ──────────────────────────────────────────────────
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      _triggerShake();
      return;
    }

    setState(() => _isLoading = true);

    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text.trim();

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      //
      final user = credential.user;

      if (user != null) {
        await _navigateToHome(
          name: user.email!.split('@')[0], // simple name
          email: user.email!,
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      _triggerShake();

      String message = "Login failed";

      if (e.code == 'user-not-found') {
        message = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        message = 'Wrong password provided.';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email format.';
      } else if (e.code == 'user-disabled') {
        message = 'This user has been disabled.';
      }

      _showFloatingSnack(
        message,
        bgColor: const Color(0xFFDC2626),
        icon: Icons.error_outline_rounded,
      );
    } catch (e) {
      setState(() => _isLoading = false);

      _showFloatingSnack(
        'Something went wrong!',
        bgColor: const Color(0xFFDC2626),
      );
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      setState(() => _isLoading = true);

      UserCredential userCredential;

      if (kIsWeb) {
        // ── Web: Firebase popup ──────────────────────────────────────────
        final googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        userCredential =
            await FirebaseAuth.instance.signInWithPopup(googleProvider);
      } else {
        // ── Android / iOS: google_sign_in ^6.x ──────────────────────────
        await _googleSignIn.signOut(); // force account picker

        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

        if (googleUser == null) {
          setState(() => _isLoading = false);
          return; // user cancelled
        }

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        if (googleAuth.idToken == null) {
          setState(() => _isLoading = false);
          _showFloatingSnack(
            'Google sign-in failed: no ID token received.',
            bgColor: const Color(0xFFDC2626),
            icon: Icons.error_outline_rounded,
          );
          return;
        }

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        userCredential =
            await FirebaseAuth.instance.signInWithCredential(credential);
      }

      final firebaseUser = userCredential.user;

      if (firebaseUser != null && mounted) {
        await _navigateToHome(
          name: firebaseUser.displayName ?? firebaseUser.email!.split('@')[0],
          email: firebaseUser.email ?? '',
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      _showFloatingSnack(
        'Google sign-in failed: ${e.message ?? e.code}',
        bgColor: const Color(0xFFDC2626),
        icon: Icons.error_outline_rounded,
      );
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Google Error: $e");
      _showFloatingSnack(
        'Google sign-in failed',
        bgColor: const Color(0xFFDC2626),
      );
    }
  }

  // ── LinkedIn Sign-In ──────────────────────────────────────────────────────
  // Requires: flutter_web_auth_2 package + LinkedIn app credentials.
  // Register your app at https://developer.linkedin.com and replace
  // _linkedInClientId & _linkedInRedirectUri above.
  Future<void> _signInWithLinkedIn() async {
    if (_linkedInClientId == 'YOUR_LINKEDIN_CLIENT_ID') {
      _showFloatingSnack(
        'LinkedIn client ID not configured yet.',
        icon: Icons.settings_outlined,
      );
      return;
    }

    try {
      setState(() => _isLoading = true);

      final authUrl = Uri.https(
        'www.linkedin.com',
        '/oauth/v2/authorization',
        {
          'response_type': 'code',
          'client_id': _linkedInClientId,
          'redirect_uri': _linkedInRedirectUri,
          'scope': _linkedInScope,
          'state': _generateState(),
        },
      );

      final result = await FlutterWebAuth2.authenticate(
        url: authUrl.toString(),
        callbackUrlScheme: 'skillbridge',
      );

      final code = Uri.parse(result).queryParameters['code'];
      if (code == null) throw Exception('No authorization code returned');

      // NOTE: Exchange `code` for a token via YOUR backend endpoint.
      // Direct client-secret usage in mobile apps is insecure.
      // For demo purposes, we simulate a successful login:
      if (!mounted) return;
      await _navigateToHome(
        name: 'LinkedIn User',
        email: 'linkedin@skillbridge.com',
      );
    } on PlatformException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // flutter_web_auth_2 throws PlatformException with code 'CANCELED'
        // when the user dismisses the browser.
        final isCancelled = e.code.toLowerCase().contains('cancel') ||
            (e.message?.toLowerCase().contains('cancel') ?? false);
        _showFloatingSnack(
          isCancelled
              ? 'LinkedIn sign-in cancelled.'
              : 'LinkedIn sign-in failed: ${e.message ?? 'Unknown error'}',
          bgColor:
              isCancelled ? const Color(0xFF1E293B) : const Color(0xFFDC2626),
          icon: isCancelled
              ? Icons.info_outline_rounded
              : Icons.error_outline_rounded,
        );
      }
    } catch (e) {
      // Catches any other errors (e.g. network, parsing)
      if (mounted) {
        setState(() => _isLoading = false);
        _showFloatingSnack(
          'LinkedIn sign-in failed: ${e.toString().split(':').last.trim()}',
          bgColor: const Color(0xFFDC2626),
          icon: Icons.error_outline_rounded,
        );
      }
    }
  }

  String _generateState() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rand = math.Random.secure();
    return List.generate(16, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  // ── Biometric Sign-In ─────────────────────────────────────────────────────
  Future<void> _signInWithBiometrics() async {
    // ── Step 1: Check device support ──────────────────────────────────────
    bool deviceSupported = false;
    bool canCheckBio = false;
    try {
      deviceSupported = await _localAuth.isDeviceSupported();
      canCheckBio = await _localAuth.canCheckBiometrics;
    } on PlatformException catch (e) {
      if (mounted) {
        _showFloatingSnack(
          'Biometric check failed: ${e.message ?? e.code}',
          bgColor: const Color(0xFFDC2626),
          icon: Icons.error_outline_rounded,
        );
      }
      return;
    }

    if (!deviceSupported) {
      _showFloatingSnack(
        'This device does not support biometric authentication.',
        icon: Icons.fingerprint_rounded,
      );
      return;
    }

    if (!canCheckBio) {
      _showFloatingSnack(
        'No biometric hardware detected. Please use your password.',
        icon: Icons.fingerprint_rounded,
      );
      return;
    }

    // ── Step 2: Check enrolled biometrics ─────────────────────────────────
    // IMPORTANT: canCheckBiometrics can return true even when NO fingerprints
    // are enrolled on some Android OEMs (Samsung, Xiaomi, etc.).
    // getAvailableBiometrics() is the reliable check.
    List<BiometricType> available = [];
    try {
      available = await _localAuth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      if (mounted) {
        _showFloatingSnack(
          'Could not read enrolled biometrics: ${e.message ?? e.code}',
          bgColor: const Color(0xFFDC2626),
          icon: Icons.error_outline_rounded,
        );
      }
      return;
    }

    if (available.isEmpty) {
      _showFloatingSnack(
        'No fingerprint enrolled. Go to Settings → Security → Fingerprint to add one.',
        icon: Icons.fingerprint_rounded,
      );
      return;
    }

    // ── Step 3: Authenticate ───────────────────────────────────────────────
    // biometricOnly: false  → allows device PIN/pattern as fallback.
    //   This is REQUIRED on Android — without it, many devices silently fail
    //   when the user presses "Use password" in the system biometric dialog.
    // stickyAuth: true  → keeps the dialog alive if the app goes to background
    //   (e.g. user opens Settings to check enrolled fingerprints mid-flow).
    // useErrorDialogs: true  → lets the OS show its own error messages.
    bool authenticated = false;
    try {
      authenticated = await _localAuth.authenticate(
        localizedReason:
            'Touch the fingerprint sensor to sign in to SkillBridge AI',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } on PlatformException catch (e) {
      if (!mounted) return;

      // Map well-known local_auth Android/iOS error codes to friendly strings
      final String friendlyMsg = switch (e.code) {
        'NotEnrolled' =>
          'No fingerprint enrolled. Go to Settings → Security → Fingerprint.',
        'NotAvailable' => 'Biometrics are currently unavailable. Try again.',
        'PasscodeNotSet' =>
          'Please set a device PIN or password first (Settings → Security).',
        'LockedOut' =>
          'Too many failed attempts. Wait 30 seconds and try again.',
        'PermanentlyLockedOut' =>
          'Biometrics are locked. Unlock your device with PIN/password first.',
        'authInProgress' => 'Authentication already in progress — please wait.',
        'no_fragment_activity' =>
          'Biometrics require FlutterFragmentActivity. See setup notes.',
        _ => e.message ?? 'Biometric error (code: ${e.code})',
      };

      _showFloatingSnack(
        friendlyMsg,
        bgColor: const Color(0xFFDC2626),
        icon: Icons.error_outline_rounded,
      );
      return;
    }

    // ── Step 4: Navigate on success ───────────────────────────────────────
    if (authenticated && mounted) {
      HapticFeedback.mediumImpact();

      // Use the last signed-in account if one exists, else fall back to demo.
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString('rememberedEmail') ?? '';
      final savedName = prefs.getString('registeredName') ?? _defaultName;

      final loginEmail = savedEmail.isNotEmpty ? savedEmail : _defaultEmail;
      final loginName = savedEmail.isNotEmpty ? savedName : _defaultName;

      await _navigateToHome(name: loginName, email: loginEmail);
    }
    // If authenticated == false the user cancelled; do nothing (no error shown).
  }

  // ══════════════════════════════════════════════════════════════════════════
  // UI HELPERS
  // ══════════════════════════════════════════════════════════════════════════

  InputDecoration _inputDec(
    String label, {
    required IconData icon,
    bool isDark = false,
  }) =>
      InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
        ),
        labelStyle: TextStyle(
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          fontSize: 14,
        ),
      );

  Widget _primaryBtn(String label, VoidCallback? onPressed) => SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryBlue,
            foregroundColor: Colors.white,
            disabledBackgroundColor:
                AppTheme.primaryBlue.withValues(alpha: 0.55),
            elevation: 0,
            shadowColor: Colors.transparent,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
        ),
      );

  Widget _outlineBtn(String label, VoidCallback? onTap) => SizedBox(
        width: double.infinity,
        height: 52,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.primaryBlue,
            side: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
      );

  Widget _buildDemoCredCard(Color subColor, bool isDark) => GestureDetector(
        onTap: () => setState(() => _showDemoCreds = !_showDemoCreds),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border:
                Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: AppTheme.primaryBlue, size: 16),
                  const SizedBox(width: 8),
                  const Text(
                    'Demo Credentials',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _showDemoCreds
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: AppTheme.primaryBlue,
                    size: 18,
                  ),
                ],
              ),
              if (_showDemoCreds) ...[
                const SizedBox(height: 10),
                _credRow('Email', _defaultEmail, subColor),
                const SizedBox(height: 4),
                _credRow('Password', _defaultPassword, subColor),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _emailCtrl.text = _defaultEmail;
                        _passCtrl.text = _defaultPassword;
                        _showDemoCreds = false;
                      });
                      HapticFeedback.selectionClick();
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      backgroundColor:
                          AppTheme.primaryBlue.withValues(alpha: 0.10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text(
                      'Auto-fill Demo Credentials',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );

  Widget _credRow(String label, String value, Color subColor) => Row(
        children: [
          Text('$label: ', style: TextStyle(fontSize: 11, color: subColor)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryBlue,
                fontFamily: 'monospace',
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );

  // ── Social row: Google + LinkedIn ─────────────────────────────────────────
  Widget _buildSocialRow(Color subColor, bool isDark) => Row(
        children: [
          Expanded(
            child: _socialBtn(
              icon: Icons.g_mobiledata_rounded,
              label: 'Google',
              isDark: isDark,
              subColor: subColor,
              onTap: _isLoading ? null : _signInWithGoogle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _socialBtn(
              icon: Icons.work_outline_rounded,
              label: 'LinkedIn',
              isDark: isDark,
              subColor: subColor,
              onTap: _isLoading ? null : _signInWithLinkedIn,
            ),
          ),
        ],
      );

  Widget _socialBtn({
    required IconData icon,
    required String label,
    required bool isDark,
    required Color subColor,
    VoidCallback? onTap,
  }) =>
      OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        style: OutlinedButton.styleFrom(
          foregroundColor: subColor,
          padding: const EdgeInsets.symmetric(vertical: 13),
          side: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

  Widget _buildBiometricBtn(Color subColor) => Center(
        child: TextButton.icon(
          onPressed: _isLoading ? null : _signInWithBiometrics,
          icon: Icon(Icons.fingerprint_rounded, size: 20, color: subColor),
          label: Text(
            'Sign in with Biometrics',
            style: TextStyle(
                fontSize: 13, color: subColor, fontWeight: FontWeight.w500),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        ),
      );

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color bgColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final Color cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final Color textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final Color subColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final Color divColor =
        isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final double topH = MediaQuery.of(context).size.height * 0.40;

    return Scaffold(
      backgroundColor: bgColor,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Form(
          key: _formKey,
          child: Stack(
            children: [
              // ── HERO GRADIENT ──────────────────────────────────────────
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: topH,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Stack(
                    children: [
                      // Gradient background
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF1A56DB),
                              Color(0xFF0EA5E9),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),

                      // Decorative bubbles
                      Positioned(
                        top: -40,
                        right: -40,
                        child: Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.07),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        left: -30,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.05),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 24,
                        left: MediaQuery.of(context).size.width * 0.42,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.04),
                          ),
                        ),
                      ),

                      // ── LOGO + TAGLINE ─────────────────────────────
                      SafeArea(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // ── FIX: Clean white card logo ─────────
                              ScaleTransition(
                                scale: _pulseAnim,
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.20),
                                        blurRadius: 24,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  // ClipRRect ensures image respects
                                  // the rounded corners
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Image.asset(
                                        'assets/logo.png',
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'SkillBridge AI',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Your career starts here',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.82),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ── THEME TOGGLE ──────────────────────────────
                      Positioned(
                        top: 48,
                        right: 16,
                        child: SafeArea(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25),
                                width: 1,
                              ),
                            ),
                            child: IconButton(
                              tooltip: isDark
                                  ? 'Switch to Light Mode'
                                  : 'Switch to Dark Mode',
                              icon: Icon(
                                isDark
                                    ? Icons.light_mode_rounded
                                    : Icons.dark_mode_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                              padding: const EdgeInsets.all(6),
                              constraints: const BoxConstraints(
                                  minWidth: 36, minHeight: 36),
                              onPressed: () => appState.toggleTheme(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── BOTTOM CARD ────────────────────────────────────────────
              Positioned(
                top: topH - 28,
                left: 0,
                right: 0,
                bottom: 0,
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(32)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 30,
                          offset: const Offset(0, -8),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Headline
                          Text(
                            'Welcome back ',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Sign in to continue your journey',
                            style: TextStyle(
                              fontSize: 14,
                              color: subColor,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Shake wrapper
                          AnimatedBuilder(
                            animation: _shakeAnim,
                            builder: (context, child) {
                              final offset =
                                  math.sin(_shakeAnim.value * math.pi * 6) *
                                      9.0;
                              return Transform.translate(
                                offset: Offset(offset, 0),
                                child: child,
                              );
                            },
                            child: Column(
                              children: [
                                // Email field
                                TextFormField(
                                  controller: _emailCtrl,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  style:
                                      TextStyle(color: textColor, fontSize: 14),
                                  decoration: _inputDec(
                                    'Email',
                                    icon: Icons.email_outlined,
                                    isDark: isDark,
                                  ),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Please enter your email';
                                    }
                                    if (!v.contains('@')) {
                                      return 'Enter a valid email';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),

                                // Password field
                                TextFormField(
                                  controller: _passCtrl,
                                  obscureText: _obscurePass,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _login(),
                                  style:
                                      TextStyle(color: textColor, fontSize: 14),
                                  decoration: _inputDec(
                                    'Password',
                                    icon: Icons.lock_outline_rounded,
                                    isDark: isDark,
                                  ).copyWith(
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePass
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        size: 20,
                                        color: subColor,
                                      ),
                                      onPressed: () => setState(
                                          () => _obscurePass = !_obscurePass),
                                    ),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return 'Please enter your password';
                                    }
                                    if (v.length < 6) {
                                      return 'Password must be at least 6 characters';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Remember me + Forgot password
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () =>
                                    setState(() => _rememberMe = !_rememberMe),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: Checkbox(
                                        value: _rememberMe,
                                        activeColor: AppTheme.primaryBlue,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(5),
                                        ),
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        visualDensity: VisualDensity.compact,
                                        onChanged: (v) => setState(
                                            () => _rememberMe = v ?? false),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Remember me',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: subColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const ForgotPasswordScreen(),
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 2),
                                ),
                                child: const Text(
                                  'Forgot password?',
                                  style: TextStyle(
                                    color: AppTheme.primaryBlue,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          _primaryBtn('Sign In →', _isLoading ? null : _login),
                          const SizedBox(height: 12),

                          _buildBiometricBtn(subColor),
                          const SizedBox(height: 4),

                          // OR divider
                          Row(
                            children: [
                              Expanded(child: Divider(color: divColor)),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  'OR',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: subColor,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                              Expanded(child: Divider(color: divColor)),
                            ],
                          ),
                          const SizedBox(height: 14),

                          _buildSocialRow(subColor, isDark),
                          const SizedBox(height: 14),

                          _outlineBtn(
                            'Create New Account',
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const RegisterScreen()),
                            ),
                          ),
                          const SizedBox(height: 24),

                          _buildDemoCredCard(subColor, isDark),
                          const SizedBox(height: 16),

                          Center(
                            child: Text(
                              'By signing in, you agree to our Terms & Privacy Policy',
                              style: TextStyle(
                                fontSize: 11,
                                color: subColor,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // SDG-8 badge
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppTheme.accentGreen
                                    .withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppTheme.accentGreen
                                      .withValues(alpha: 0.30),
                                ),
                              ),
                              child: const Text(
                                ' Supporting UN SDG-8: Decent Work & Economic Growth',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.accentGreen,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
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
