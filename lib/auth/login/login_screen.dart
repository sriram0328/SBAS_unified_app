import 'package:flutter/material.dart';
import 'login_controller.dart';
import '../role_router.dart'; // We will create this next

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

  @override
  void initState() {
    super.initState();
    _loginController.addListener(() {
      if (_loginController.state == LoginState.success) {
        // Navigate on successful login
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => RoleRouter(userData: _loginController.userData!),
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
        padding: const EdgeInsets.all(24.0),
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
              TextFormField(
                controller: _userIdController,
                decoration: const InputDecoration(
                  labelText: "Student/Faculty ID",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) => (value?.isEmpty ?? true) ? "Please enter your ID" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (value) => (value?.isEmpty ?? true) ? "Please enter your password" : null,
              ),
              const SizedBox(height: 24),
              AnimatedBuilder(
                animation: _loginController,
                builder: (context, child) {
                  if (_loginController.state == LoginState.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return ElevatedButton(
                    onPressed: _performLogin,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blue,
                    ),
                    child: const Text("Login", style: TextStyle(color: Colors.white, fontSize: 16)),
                  );
                },
              ),
              const SizedBox(height: 16),
               AnimatedBuilder(
                 animation: _loginController,
                 builder: (context, child) {
                   if (_loginController.state == LoginState.error && _loginController.errorMessage != null) {
                     return Text(
                       _loginController.errorMessage!,
                       style: TextStyle(color: Theme.of(context).colorScheme.error),
                       textAlign: TextAlign.center,
                     );
                   }
                   return const SizedBox.shrink();
                 }
               ),
            ],
          ),
        ),
      ),
    );
  }
}