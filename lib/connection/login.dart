import 'package:flutter/material.dart';
import 'package:plastica_suc/connection/register.dart';
import 'package:plastica_suc/controller/auth.dart';
import 'package:plastica_suc/view/admin/home_adm.dart';
import 'package:plastica_suc/view/employer/home_empl.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  TextEditingController passwordController = TextEditingController();
  TextEditingController emailController = TextEditingController();
final _formKey = GlobalKey<FormState>();
  String selectedrole = "user";
  bool isloading = false;
  // bool _forlongin = true;
  bool isPasswordHidden = true;
  //
  final AuthService _auth = AuthService();
  void login() async {
      // if (!_formKey.currentState!.validate()) return;
    setState(() {
      isloading = true;
    });
    String? result = await _auth.login(
      email: emailController.text,
      password: passwordController.text,
    );
    setState(() {
      isloading = true;
    });
    // SUCCES
    if (result == "Admin") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeAdm()),
      );
    }
    // error
    else if (result == "Caissier") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeEmpl()),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("sgnup error $result")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 18,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    // Container(
                    //   width: 62,
                    //   height: 62,
                    //   decoration: BoxDecoration(
                    //     color: const Color(0xFF0EA5E9).withOpacity(0.12),
                    //     borderRadius: BorderRadius.circular(18),
                    //   ),
                    //   child: const Icon(
                    //     Icons.lock_outline_rounded,
                    //     size: 32,
                    //     color: Color(0xFF0EA5E9),
                    //   ),
                    // ),
                    const SizedBox(height: 22),
                    const Text(
                      'Connexion',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Accédez à votre espace de gestion',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Form(
                      key: _formKey,
                      child: Column(
                      children: [
                        const SizedBox(height: 28),
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        hintText: 'exemple@gmail.com',
                        prefixIcon: const Icon(Icons.email_outlined),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFF0EA5E9),
                            width: 1.5,
                          ),
                        ),
                      ),
                    //   validator: (value) {
                    // if (value == null || value.trim().isEmpty) return 'email est requis';
                    // return null;
                  // },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: passwordController,
                      obscureText: isPasswordHidden,
                      decoration: InputDecoration(
                        labelText: 'Mot de passe',
                        hintText: '********',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              isPasswordHidden = !isPasswordHidden;
                            });
                          },
                          icon: Icon(
                            isPasswordHidden
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFF0EA5E9),
                            width: 1.5,
                          ),
                        ),
                      ),
                  //     validator: (value) {
                  //   if (value == null || value.trim().isEmpty) return 'password est requis';
                  //   return null;
                  // },
                    ),
                      ])),
                    
                    const SizedBox(height: 24),
                    isloading
                        ? const Center(
                            child: SizedBox(
                              height: 52,
                              width: 52,
                              child: CircularProgressIndicator(strokeWidth: 3),
                            ),
                          )
                        : SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0F172A),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Se connecter',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                    const SizedBox(height: 18),
                    Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const Register()),
                          );
                        },
                        child: RichText(
                          text: const TextSpan(
                            style: TextStyle(color: Color(0xFF475569)),
                            children: [
                              TextSpan(text: 'Pas de compte ? '),
                              TextSpan(
                                text: 'Créer un compte',
                                style: TextStyle(
                                  color: Color(0xFF0EA5E9),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
