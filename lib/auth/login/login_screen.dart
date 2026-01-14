import 'package:flutter/material.dart';
import 'login_controller.dart';
import '../role_router.dart';
import 'package:flutter/services.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _loginController = LoginController();

  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();

    _loginController.addListener(() {
      if (_loginController.state == LoginState.success) {
        // Tell OS these credentials are valid (for autofill save prompt)
        TextInput.finishAutofillContext();

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) =>
                RoleRouter(userData: _loginController.userData!),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _userIdController.dispose();
    _passwordController.dispose();
    _loginController.dispose();
    super.dispose();
  }

  void _performLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      _loginController.login(
        _userIdController.text.trim(),
        _passwordController.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("SBAS")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: AutofillGroup(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "Welcome",
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                /// USER ID (AUTOFILL ENABLED)
                TextFormField(
                  controller: _userIdController,
                  autofillHints: const [
                    AutofillHints.username,
                    AutofillHints.email,
                  ],
                  decoration: const InputDecoration(
                    labelText: "Student / Faculty ID",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) =>
                      (v?.isEmpty ?? true) ? "Enter your ID" : null,
                ),

                const SizedBox(height: 16),

                /// PASSWORD (AUTOFILL TRIGGER)
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  autofillHints: const [AutofillHints.password],
                  decoration: InputDecoration(
                    labelText: "Password",
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                  validator: (v) =>
                      (v?.isEmpty ?? true) ? "Enter password" : null,
                ),

                const SizedBox(height: 24),

                /// LOGIN BUTTON / LOADER
                AnimatedBuilder(
                  animation: _loginController,
                  builder: (context, _) {
                    if (_loginController.state == LoginState.loading) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    return ElevatedButton(
                      onPressed: _performLogin,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        backgroundColor: Colors.blue,
                      ),
                      child: const Text(
                        "Login",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                /// ERROR MESSAGE
                AnimatedBuilder(
                  animation: _loginController,
                  builder: (context, _) {
                    if (_loginController.state == LoginState.error &&
                        _loginController.errorMessage != null) {
                      return Text(
                        _loginController.errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
