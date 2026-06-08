import 'package:flutter/material.dart';

import '../../bootstrap/backend_bootstrap.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/app_models.dart';
import '../../core/services/auth_service.dart';
import '../../core/widgets/resq_widgets.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    required this.backendState,
    required this.authService,
    required this.onAuthenticated,
    required this.onBack,
  });

  final BackendState backendState;
  final AuthService authService;
  final ValueChanged<AppUser> onAuthenticated;
  final VoidCallback onBack;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  AppRole _role = AppRole.citizen;
  bool _isRegister = false;
  bool _loading = false;
  bool _obscure = true;
  String? _message;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _selectRole(AppRole role) {
    setState(() {
      _role = role;
      _message = null;
    });
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _message = null;
    });

    try {
      final result = _isRegister
          ? await widget.authService.register(
              email: _emailController.text,
              password: _passwordController.text,
              selectedRole: _role,
              fullName: _nameController.text,
              phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
              address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
            )
          : await widget.authService.signIn(
              email: _emailController.text,
              password: _passwordController.text,
              selectedRole: _role,
            );

      if (!mounted) return;
      if (result.notice != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.notice!)));
      }
      widget.onAuthenticated(result.user);
    } catch (error) {
      if (!mounted) return;
      setState(() => _message = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 860;
                  return ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1040),
                    child: wide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(child: _HeroPanel(onBack: widget.onBack)),
                              const SizedBox(width: 28),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(30),
                                    boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 32, offset: Offset(0, 18))],
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          IconButton(onPressed: widget.onBack, icon: const Icon(Icons.arrow_back_rounded)),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _isRegister ? 'Create ResQ Account' : 'Welcome Back',
                                              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.text),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 22),
                                      if (_isRegister) ...[
                                        Wrap(
                                          spacing: 10,
                                          runSpacing: 10,
                                          children: AppRole.values.map((role) {
                                            final active = role == _role;
                                            return InkWell(
                                              borderRadius: BorderRadius.circular(18),
                                              onTap: () => _selectRole(role),
                                              child: AnimatedContainer(
                                                duration: const Duration(milliseconds: 180),
                                                width: 145,
                                                padding: const EdgeInsets.all(14),
                                                decoration: BoxDecoration(
                                                  color: active ? AppColors.navy : AppColors.bg,
                                                  borderRadius: BorderRadius.circular(18),
                                                  border: Border.all(color: active ? AppColors.navy : AppColors.border),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(role.emoji, style: const TextStyle(fontSize: 24)),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      role.label,
                                                      style: TextStyle(
                                                        color: active ? Colors.white : AppColors.text,
                                                        fontWeight: FontWeight.w900,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      _roleDescription(role),
                                                      style: TextStyle(
                                                        color: active ? Colors.white70 : AppColors.muted,
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                        const SizedBox(height: 20),
                                      ],
                                      if (!_isRegister) const SizedBox(height: 20),
                                      if (_isRegister) ...[
                                        TextField(
                                          controller: _nameController,
                                          decoration: const InputDecoration(prefixIcon: Icon(Icons.person_outline), hintText: 'Full name'),
                                        ),
                                        const SizedBox(height: 12),
                                      ],
                                      TextField(
                                        controller: _emailController,
                                        keyboardType: TextInputType.emailAddress,
                                        decoration: const InputDecoration(prefixIcon: Icon(Icons.mail_outline), hintText: 'Email'),
                                      ),
                                      const SizedBox(height: 12),
                                      TextField(
                                        controller: _passwordController,
                                        obscureText: _obscure,
                                        decoration: InputDecoration(
                                          prefixIcon: const Icon(Icons.lock_outline),
                                          hintText: 'Password',
                                          suffixIcon: IconButton(
                                            onPressed: () => setState(() => _obscure = !_obscure),
                                            icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                                          ),
                                        ),
                                      ),
                                      if (_isRegister) ...[
                                        const SizedBox(height: 12),
                                        TextField(
                                          controller: _phoneController,
                                          decoration: const InputDecoration(prefixIcon: Icon(Icons.phone_outlined), hintText: 'Phone number'),
                                        ),
                                        const SizedBox(height: 12),
                                        TextField(
                                          controller: _addressController,
                                          decoration: const InputDecoration(prefixIcon: Icon(Icons.location_on_outlined), hintText: 'Address'),
                                        ),
                                      ],
                                      if (_message != null) ...[
                                        const SizedBox(height: 12),
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: AppColors.red.withOpacity(.08),
                                            borderRadius: BorderRadius.circular(14),
                                            border: Border.all(color: AppColors.red.withOpacity(.18)),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.error_outline, color: AppColors.red, size: 18),
                                              const SizedBox(width: 8),
                                              Expanded(child: Text(_message!, style: const TextStyle(color: AppColors.red, fontWeight: FontWeight.w700))),
                                            ],
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 18),
                                      PrimaryButton(
                                        label: _loading ? 'Please wait...' : (_isRegister ? 'Create Account' : 'Sign In'),
                                        icon: _isRegister ? Icons.person_add_alt_rounded : Icons.login_rounded,
                                        onPressed: _loading ? null : _submit,
                                      ),
                                      const SizedBox(height: 12),
                                      Center(
                                        child: TextButton(
                                          onPressed: _loading ? null : () => setState(() => _isRegister = !_isRegister),
                                          child: Text(
                                            _isRegister ? 'Already have an account? Sign in' : 'Need an account? Register instead',
                                            style: const TextStyle(fontWeight: FontWeight.w800),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _HeroPanel(onBack: widget.onBack),
                              const SizedBox(height: 28),
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 32, offset: Offset(0, 18))],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        IconButton(onPressed: widget.onBack, icon: const Icon(Icons.arrow_back_rounded)),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _isRegister ? 'Create ResQ Account' : 'Welcome Back',
                                            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.text),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 22),
                                    if (_isRegister) ...[
                                      Wrap(
                                        spacing: 10,
                                        runSpacing: 10,
                                        children: AppRole.values.map((role) {
                                          final active = role == _role;
                                          return InkWell(
                                            borderRadius: BorderRadius.circular(18),
                                            onTap: () => _selectRole(role),
                                            child: AnimatedContainer(
                                              duration: const Duration(milliseconds: 180),
                                              width: 145,
                                              padding: const EdgeInsets.all(14),
                                              decoration: BoxDecoration(
                                                color: active ? AppColors.navy : AppColors.bg,
                                                borderRadius: BorderRadius.circular(18),
                                                border: Border.all(color: active ? AppColors.navy : AppColors.border),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(role.emoji, style: const TextStyle(fontSize: 24)),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    role.label,
                                                    style: TextStyle(
                                                      color: active ? Colors.white : AppColors.text,
                                                      fontWeight: FontWeight.w900,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    _roleDescription(role),
                                                    style: TextStyle(
                                                      color: active ? Colors.white70 : AppColors.muted,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                      const SizedBox(height: 20),
                                    ],
                                    if (!_isRegister) const SizedBox(height: 20),
                                    if (_isRegister) ...[
                                      TextField(
                                        controller: _nameController,
                                        decoration: const InputDecoration(prefixIcon: Icon(Icons.person_outline), hintText: 'Full name'),
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                    TextField(
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      decoration: const InputDecoration(prefixIcon: Icon(Icons.mail_outline), hintText: 'Email'),
                                    ),
                                    const SizedBox(height: 12),
                                    TextField(
                                      controller: _passwordController,
                                      obscureText: _obscure,
                                      decoration: InputDecoration(
                                        prefixIcon: const Icon(Icons.lock_outline),
                                        hintText: 'Password',
                                        suffixIcon: IconButton(
                                          onPressed: () => setState(() => _obscure = !_obscure),
                                          icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                                        ),
                                      ),
                                    ),
                                    if (_isRegister) ...[
                                      const SizedBox(height: 12),
                                      TextField(
                                        controller: _phoneController,
                                        decoration: const InputDecoration(prefixIcon: Icon(Icons.phone_outlined), hintText: 'Phone number'),
                                      ),
                                      const SizedBox(height: 12),
                                      TextField(
                                        controller: _addressController,
                                        decoration: const InputDecoration(prefixIcon: Icon(Icons.location_on_outlined), hintText: 'Address'),
                                      ),
                                    ],
                                    if (_message != null) ...[
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: AppColors.red.withOpacity(.08),
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(color: AppColors.red.withOpacity(.18)),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.error_outline, color: AppColors.red, size: 18),
                                            const SizedBox(width: 8),
                                            Expanded(child: Text(_message!, style: const TextStyle(color: AppColors.red, fontWeight: FontWeight.w700))),
                                          ],
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 18),
                                    PrimaryButton(
                                      label: _loading ? 'Please wait...' : (_isRegister ? 'Create Account' : 'Sign In'),
                                      icon: _isRegister ? Icons.person_add_alt_rounded : Icons.login_rounded,
                                      onPressed: _loading ? null : _submit,
                                    ),
                                    const SizedBox(height: 12),
                                    Center(
                                      child: TextButton(
                                        onPressed: _loading ? null : () => setState(() => _isRegister = !_isRegister),
                                        child: Text(
                                          _isRegister ? 'Already have an account? Sign in' : 'Need an account? Register instead',
                                          style: const TextStyle(fontWeight: FontWeight.w800),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _roleDescription(AppRole role) {
    switch (role) {
      case AppRole.citizen:
        return 'SOS & care';
      case AppRole.responder:
        return 'EMS alerts';
      case AppRole.professional:
        return 'Consults';
      case AppRole.admin:
        return 'Monitoring';
    }
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton.icon(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          label: const Text('Back to landing', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        ),
        const SizedBox(height: 32),
        const Text('⚕️', style: TextStyle(fontSize: 54)),
        const SizedBox(height: 18),
        const Text(
          'Healthcare response, triage, and dispatch in one role-based platform.',
          style: TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w900, height: 1.1),
        ),
        const SizedBox(height: 18),
        const Text(
          'The Flutter rebuild keeps the same mockup logic while preparing Firebase Auth, Firestore collections, and Supabase file storage for real implementation.',
          style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.6),
        ),
      ],
    );
  }
}
