import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter/services.dart';
import '../../../core/theme/ios_colors.dart';
import '../../../core/widgets/ios_button.dart';
import '../../../core/widgets/ios_card.dart';
import '../../../core/widgets/ios_toast.dart';
import '../../view_models/auth_view_model.dart';
import '../../view_models/generate_view_model.dart';
import '../../view_models/history_view_model.dart';
import '../../view_models/settings_view_model.dart';
import '../main_navigation_screen.dart';

class AuthScreen extends StatefulWidget {
  final AuthViewModel authViewModel;
  final GenerateViewModel? generateViewModel;
  final HistoryViewModel? historyViewModel;
  final SettingsViewModel? settingsViewModel;
  final VoidCallback? onAuthenticated;

  const AuthScreen({
    super.key,
    required this.authViewModel,
    this.generateViewModel,
    this.historyViewModel,
    this.settingsViewModel,
    this.onAuthenticated,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  // 0: Login, 1: Register
  int _selectedTab = 0;
  bool _isSubmitting = false;

  // Controllers
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _switchTab(int index) {
    if (_isSubmitting || widget.authViewModel.isLoading) return;
    if (_selectedTab != index) {
      HapticFeedback.selectionClick();
      setState(() {
        _selectedTab = index;
      });
      widget.authViewModel.clearMessages();
    }
  }

  void _navigateToHome() {
    widget.generateViewModel?.init();
    widget.historyViewModel?.loadEntries();
    widget.settingsViewModel?.loadSettings();
    widget.onAuthenticated?.call();

    if (!mounted) return;

    if (widget.generateViewModel != null &&
        widget.historyViewModel != null &&
        widget.settingsViewModel != null) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 650),
          pageBuilder: (context, animation, secondaryAnimation) =>
              MainNavigationScreen(
            generateViewModel: widget.generateViewModel!,
            historyViewModel: widget.historyViewModel!,
            settingsViewModel: widget.settingsViewModel!,
            authViewModel: widget.authViewModel,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
            );
            return FadeTransition(
              opacity: curved,
              child: child,
            );
          },
        ),
      );
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting || widget.authViewModel.isLoading) return;

    widget.authViewModel.clearMessages();
    FocusScope.of(context).unfocus();

    if (_selectedTab == 0) {
      // Login
      final identifier = _usernameController.text.trim();
      final password = _passwordController.text;

      if (identifier.isEmpty || password.isEmpty) {
        IosToast.show(
          context,
          'Harap isi username/email dan kata sandi.',
          type: ToastType.warning,
        );
        return;
      }

      setState(() {
        _isSubmitting = true;
      });

      final stopwatch = Stopwatch()..start();
      final success = await widget.authViewModel.login(
        usernameOrEmail: identifier,
        password: password,
      );

      // Keep iOS activity spinner visible smoothly for at least 650ms
      final elapsed = stopwatch.elapsedMilliseconds;
      if (elapsed < 650) {
        await Future.delayed(Duration(milliseconds: 650 - elapsed));
      }

      if (!mounted) return;

      if (success) {
        IosToast.show(
          context,
          'Selamat datang kembali, ${widget.authViewModel.currentUser?.displayName}!',
          type: ToastType.success,
        );
        await Future.delayed(const Duration(milliseconds: 250));
        if (!mounted) return;
        _navigateToHome();
      } else {
        setState(() {
          _isSubmitting = false;
        });
      }
    } else {
      // Register
      final username = _usernameController.text.trim();
      final email = _emailController.text.trim();
      final name = _nameController.text.trim();
      final password = _passwordController.text;
      final confirmPassword = _confirmPasswordController.text;

      if (username.isEmpty || email.isEmpty || password.isEmpty) {
        IosToast.show(
          context,
          'Harap isi semua kolom bertanda wajib.',
          type: ToastType.warning,
        );
        return;
      }

      if (password != confirmPassword) {
        IosToast.show(
          context,
          'Konfirmasi kata sandi tidak cocok.',
          type: ToastType.warning,
        );
        return;
      }

      setState(() {
        _isSubmitting = true;
      });

      final stopwatch = Stopwatch()..start();
      final success = await widget.authViewModel.register(
        username: username,
        email: email,
        password: password,
        name: name.isNotEmpty ? name : null,
      );

      // Keep iOS activity spinner visible smoothly for at least 650ms
      final elapsed = stopwatch.elapsedMilliseconds;
      if (elapsed < 650) {
        await Future.delayed(Duration(milliseconds: 650 - elapsed));
      }

      if (!mounted) return;

      if (success) {
        IosToast.show(
          context,
          'Akun berhasil dibuat! Selamat bergabung.',
          type: ToastType.success,
        );
        await Future.delayed(const Duration(milliseconds: 250));
        if (!mounted) return;
        _navigateToHome();
      } else {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return CupertinoPageScaffold(
      backgroundColor: IosColors.darkBackground,
      child: Stack(
        children: [
          // Background ambient gradient
          Positioned(
            top: -60,
            left: 0,
            right: 0,
            height: size.height * 0.45,
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.4),
                  radius: 0.9,
                  colors: [
                    const Color(0xFF30D158).withValues(alpha: 0.14),
                    const Color(0xFF0A84FF).withValues(alpha: 0.04),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // App Logo
                    Center(
                      child: Container(
                        width: 78,
                        height: 78,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF1E2922),
                              Color(0xFF0F1511),
                            ],
                          ),
                          border: Border.all(
                            color: const Color(0xFF30D158).withValues(alpha: 0.4),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF30D158).withValues(alpha: 0.25),
                              blurRadius: 20,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.asset(
                          'assets/icon/app_icon.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(
                                CupertinoIcons.book_fill,
                                color: IosColors.statusGreen,
                                size: 36,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // App Title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Absen MagangHub',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                            color: CupertinoColors.white,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: IosColors.statusGreen,
                            boxShadow: [
                              BoxShadow(
                                color: IosColors.statusGreen.withValues(alpha: 0.8),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    Text(
                      _selectedTab == 0
                          ? 'Masuk untuk mengakses riwayat logbook kamu'
                          : 'Daftar akun baru untuk mulai pencatatan',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: IosColors.secondaryLabel(context),
                      ),
                    ),
                    const SizedBox(height: 26),

                    // Segmented Control (Masuk / Daftar)
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1C1E),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF2C2C2E),
                          width: 0.8,
                        ),
                      ),
                      padding: const EdgeInsets.all(3),
                      child: Row(
                        children: [
                          Expanded(
                            child: _AuthTabButton(
                              label: 'Masuk',
                              icon: CupertinoIcons.arrow_right_to_line,
                              isSelected: _selectedTab == 0,
                              onTap: () => _switchTab(0),
                            ),
                          ),
                          Expanded(
                            child: _AuthTabButton(
                              label: 'Daftar Akun',
                              icon: CupertinoIcons.person_badge_plus,
                              isSelected: _selectedTab == 1,
                              onTap: () => _switchTab(1),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Form Card
                    ListenableBuilder(
                      listenable: widget.authViewModel,
                      builder: (context, _) {
                        final isBusy = _isSubmitting || widget.authViewModel.isLoading;
                        return IosCard(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Error Banner
                              if (widget.authViewModel.errorMessage != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: IosColors.statusRed.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: IosColors.statusRed.withValues(alpha: 0.5),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        CupertinoIcons.exclamationmark_circle_fill,
                                        color: IosColors.statusRed,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          widget.authViewModel.errorMessage!,
                                          style: const TextStyle(
                                            color: IosColors.statusRed,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Fields for Register
                              if (_selectedTab == 1) ...[
                                _FieldLabel(label: 'Nama Lengkap (Opsional)'),
                                CupertinoTextField(
                                  key: const Key('auth_input_name'),
                                  controller: _nameController,
                                  readOnly: _isSubmitting || widget.authViewModel.isLoading,
                                  placeholder: 'cth: Alif Nur',
                                  prefix: const Padding(
                                    padding: EdgeInsets.only(left: 12),
                                    child: Icon(
                                      CupertinoIcons.person,
                                      size: 16,
                                      color: Color(0xFF8E8E93),
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                  decoration: _fieldDecoration(isDark),
                                  style: const TextStyle(fontSize: 14, color: CupertinoColors.white),
                                  placeholderStyle: const TextStyle(fontSize: 14, color: Color(0xFF636366)),
                                ),
                                const SizedBox(height: 14),

                                _FieldLabel(label: 'Email Aktif *'),
                                CupertinoTextField(
                                  key: const Key('auth_input_email'),
                                  controller: _emailController,
                                  readOnly: _isSubmitting || widget.authViewModel.isLoading,
                                  keyboardType: TextInputType.emailAddress,
                                  placeholder: 'cth: alif@gmail.com',
                                  prefix: const Padding(
                                    padding: EdgeInsets.only(left: 12),
                                    child: Icon(
                                      CupertinoIcons.mail,
                                      size: 16,
                                      color: Color(0xFF8E8E93),
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                  decoration: _fieldDecoration(isDark),
                                  style: const TextStyle(fontSize: 14, color: CupertinoColors.white),
                                  placeholderStyle: const TextStyle(fontSize: 14, color: Color(0xFF636366)),
                                ),
                                const SizedBox(height: 14),
                              ],

                              // Username (or Identifier for Login)
                              _FieldLabel(
                                label: _selectedTab == 0 ? 'Username atau Email *' : 'Username *',
                              ),
                              CupertinoTextField(
                                key: const Key('auth_input_username'),
                                controller: _usernameController,
                                readOnly: _isSubmitting || widget.authViewModel.isLoading,
                                placeholder: _selectedTab == 0 ? 'Masukkan username atau email' : 'cth: zalzdarkent',
                                prefix: const Padding(
                                    padding: EdgeInsets.only(left: 12),
                                    child: Icon(
                                      CupertinoIcons.at,
                                      size: 16,
                                      color: Color(0xFF8E8E93),
                                    ),
                                  ),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                decoration: _fieldDecoration(isDark),
                                style: const TextStyle(fontSize: 14, color: CupertinoColors.white),
                                placeholderStyle: const TextStyle(fontSize: 14, color: Color(0xFF636366)),
                              ),
                              const SizedBox(height: 14),

                              // Password
                              _FieldLabel(label: 'Kata Sandi *'),
                              CupertinoTextField(
                                key: const Key('auth_input_password'),
                                controller: _passwordController,
                                readOnly: _isSubmitting || widget.authViewModel.isLoading,
                                obscureText: _obscurePassword,
                                placeholder: 'Minimal 6 karakter',
                                prefix: const Padding(
                                  padding: EdgeInsets.only(left: 12),
                                  child: Icon(
                                    CupertinoIcons.lock,
                                    size: 16,
                                    color: Color(0xFF8E8E93),
                                  ),
                                ),
                                suffix: CupertinoButton(
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  minimumSize: Size.zero,
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                  child: Icon(
                                    _obscurePassword
                                        ? CupertinoIcons.eye_slash
                                        : CupertinoIcons.eye,
                                    size: 17,
                                    color: const Color(0xFF8E8E93),
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                decoration: _fieldDecoration(isDark),
                                style: const TextStyle(fontSize: 14, color: CupertinoColors.white),
                                placeholderStyle: const TextStyle(fontSize: 14, color: Color(0xFF636366)),
                              ),

                              // Confirm Password for Register
                              if (_selectedTab == 1) ...[
                                const SizedBox(height: 14),
                                _FieldLabel(label: 'Ulangi Kata Sandi *'),
                                CupertinoTextField(
                                  key: const Key('auth_input_confirm_password'),
                                  controller: _confirmPasswordController,
                                  readOnly: _isSubmitting || widget.authViewModel.isLoading,
                                  obscureText: _obscureConfirmPassword,
                                  placeholder: 'Ketik ulang kata sandi',
                                  prefix: const Padding(
                                    padding: EdgeInsets.only(left: 12),
                                    child: Icon(
                                      CupertinoIcons.lock_shield,
                                      size: 16,
                                      color: Color(0xFF8E8E93),
                                    ),
                                  ),
                                  suffix: CupertinoButton(
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    minimumSize: Size.zero,
                                    onPressed: () {
                                      setState(() {
                                        _obscureConfirmPassword = !_obscureConfirmPassword;
                                      });
                                    },
                                    child: Icon(
                                      _obscureConfirmPassword
                                          ? CupertinoIcons.eye_slash
                                          : CupertinoIcons.eye,
                                      size: 17,
                                      color: const Color(0xFF8E8E93),
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                  decoration: _fieldDecoration(isDark),
                                  style: const TextStyle(fontSize: 14, color: CupertinoColors.white),
                                  placeholderStyle: const TextStyle(fontSize: 14, color: Color(0xFF636366)),
                                ),
                              ],
                              const SizedBox(height: 22),

                              // Submit Button
                              IosButton(
                                key: const Key('auth_btn_submit'),
                                text: _selectedTab == 0 ? 'Masuk' : 'Daftar Sekarang',
                                loadingText: _selectedTab == 0 ? 'Sedang Masuk...' : 'Sedang Mendaftar...',
                                icon: Icon(
                                  _selectedTab == 0
                                      ? CupertinoIcons.arrow_right_circle_fill
                                      : CupertinoIcons.checkmark_seal_fill,
                                  size: 18,
                                ),
                                variant: IosButtonVariant.primary,
                                size: IosButtonSize.large,
                                isLoading: isBusy,
                                onPressed: isBusy ? null : _submit,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    // Privacy & Database info badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          CupertinoIcons.lock_shield,
                          size: 13,
                          color: IosColors.statusGreen,
                        ),
                        const SizedBox(width: 6),
                      ],
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

  BoxDecoration _fieldDecoration(bool isDark) {
    return BoxDecoration(
      color: isDark ? const Color(0xFF141416) : const Color(0xFFF2F2F7),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
        width: 1,
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;

  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 2),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF8E8E93),
        ),
      ),
    );
  }
}

class _AuthTabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _AuthTabButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2C2C2E) : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          border: isSelected
              ? Border.all(
                  color: const Color(0xFF30D158).withValues(alpha: 0.3),
                  width: 0.8,
                )
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? IosColors.statusGreen : const Color(0xFF8E8E93),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? CupertinoColors.white : const Color(0xFF8E8E93),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
