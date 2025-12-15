import 'package:flutter/material.dart';
import 'package:flutter_codelab/api/auth_api.dart';
import 'package:flutter_codelab/models/user_data.dart'; // Using the UserDetails class from here
import 'package:flutter_codelab/main.dart'; // Import the Feed structure

// Define a new page for the login screen
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final AuthApi _authApi = AuthApi();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- Login Logic Handler ---
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return; // Stop if form is invalid
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Call the API login method
      final userData = await _authApi.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      // 2. Map the returned JSON user data (which includes user details)
      //    to the UserDetails model.
      final UserDetails loggedInUser = UserDetails.fromJson(userData);

      // 3. On successful login, navigate to the main application feed
      if (mounted) {
        // Use pushReplacement to remove the Login page from the navigation stack
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            // NOTE: The Feed widget expects a 'User' type.
            // We must now pass the UserDetails object instead.
            // You will need to ensure your main.dart 'Feed' widget accepts UserDetails.
            builder: (context) => Feed(currentUser: loggedInUser),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // --- START FIX: Logic to clean the error message for display ---
        String errorMessage = e.toString();

        // 1. Check for specific unwanted technical prefixes/codes and replace with a generic message.
        //    This prevents revealing internal structure errors (like 302 redirects).
        if (errorMessage.contains('302') ||
            errorMessage.contains('Server Error')) {
          errorMessage =
              'A network or server configuration error occurred. Please try again.';
        } else if (errorMessage.startsWith('Exception: ')) {
          // 2. Only clean the general Dart prefix for expected exceptions (e.g., failed credentials)
          errorMessage = errorMessage.substring('Exception: '.length);
        }

        // 4. Show error message (e.g., incorrect credentials)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            // ✅ CORRECTION: Use the cleaned 'errorMessage' variable here
            content: Text('Login Failed: $errorMessage'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        // --- END FIX ---
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // --- UI Build Method ---
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // Logo/App Title
                  Image.asset('assets/CodePlay.png', height: 80),
                  const SizedBox(height: 20),
                  Text(
                    'CodePlay',
                    style: textTheme.headlineMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  // 1. Email Field (Material 3: TextFormField)
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'user@example.com',
                      prefixIcon: const Icon(Icons.email),
                      border: const OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: colorScheme.outline),
                      ),
                    ),
                    validator: (value) {
                      if (value == null ||
                          value.isEmpty ||
                          !value.contains('@')) {
                        return 'Please enter a valid email address.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // 2. Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _handleLogin(),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty || value.length < 6) {
                        return 'Password must be at least 6 characters long.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 30),

                  // 3. Login Button (Material 3: FilledButton)
                  _isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: colorScheme.primary,
                          ),
                        )
                      : FilledButton.icon(
                          onPressed: _handleLogin,
                          icon: const Icon(Icons.login),
                          label: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12.0),
                            child: Text(
                              'Log In',
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                        ),

                  const SizedBox(height: 20),

                  // 4. Forgot Password/Sign Up Link (Material 3: TextButton)
                  TextButton(
                    onPressed: () {
                      // TODO: Implement navigation to registration page
                      print('Navigate to Registration');
                    },
                    child: const Text('Don\'t have an account? Sign Up'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
