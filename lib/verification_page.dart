import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'login_page.dart';

class VerificationPage extends StatefulWidget {
  const VerificationPage({super.key});

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  
  final List<TextEditingController> _otpControllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(4, (_) => FocusNode());
  
  bool _isOtpComplete = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1), // Start from bottom (off-screen)
      end: Offset.zero, // End at normal position
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
    
    // Generate initial OTP
    _generateNewOtp();
  }

  @override
  void dispose() {
    _controller.dispose();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _otpFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _generateNewOtp() {
    // Generate a new OTP (in a real app, this would be sent to the user's email)
    // For now, we just clear the fields and reset the state
    
    // Clear all OTP fields
    for (var controller in _otpControllers) {
      controller.clear();
    }
    // Reset focus to first field
    _otpFocusNodes[0].requestFocus();
    setState(() {
      _isOtpComplete = false;
    });
  }

  void _handleOtpInput(int index, String value) {
    // Only allow digits
    if (value.isNotEmpty && !RegExp(r'^[0-9]$').hasMatch(value)) {
      _otpControllers[index].clear();
      return;
    }

    // Move to next field if digit entered
    if (value.isNotEmpty && index < 3) {
      _otpFocusNodes[index + 1].requestFocus();
    }

    // Move to previous field if backspace pressed and current field is empty
    if (value.isEmpty && index > 0) {
      _otpFocusNodes[index - 1].requestFocus();
    }

    // Check if OTP is complete
    _checkOtpComplete();
  }

  void _checkOtpComplete() {
    String enteredOtp = '';
    for (var controller in _otpControllers) {
      enteredOtp += controller.text;
    }
    
    setState(() {
      _isOtpComplete = enteredOtp.length == 4;
    });
  }

  void _handleVerify() {
    String enteredOtp = '';
    for (var controller in _otpControllers) {
      enteredOtp += controller.text;
    }

    if (enteredOtp.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the complete OTP code')),
      );
      return;
    }

    // Here you would typically verify the OTP with your backend
    // For now, just show a success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('OTP verified successfully!')),
    );
    
    // Navigate to Login Page
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          // Background image - f.png covering the top portion
          Positioned.fill(
            child: Image.asset(
              'images/f.png',
              fit: BoxFit.fitHeight,
              alignment: Alignment.topCenter,
            ),
          ),

          // App bar with back button on left and Welcome text
          SafeArea(
            child: Stack(
              children: [
                // Back button positioned at the top left
                Positioned(
                  left: 20,
                  top: 20,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Image.asset(
                      'images/back.png',
                      width: 24,
                      height: 24,
                    ),
                  ),
                ),
                // Welcome text positioned after back button
                Positioned(
                  left: 160,
                  top: 20,
                  child: const Text(
                    'Welcome',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500, // Poppins Medium
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom box with rounded top corners - positioned to fit bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SlideTransition(
              position: _slideAnimation,
              child: Container(
                constraints: BoxConstraints(minHeight: screenHeight * 0.52),
                decoration: const BoxDecoration(
                  color: Color(0xFFF4F5F9),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 30, 20, 30),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Verify your Email text (center)
                          const Text(
                            'Verify your Email',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 25,
                              fontWeight: FontWeight.w600, // Inter Semi Bold
                              fontFamily: 'Inter',
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 12),

                          // Enter your OTP code below text (center)
                          const Text(
                            'Enter your OTP code below',
                            style: TextStyle(
                              color: Color(0xFF868889),
                              fontSize: 16,
                              fontWeight: FontWeight.normal, // Open Sans Regular
                              fontFamily: 'Open Sans',
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 40),

                          // OTP input fields (4 boxes)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(4, (index) {
                              return Container(
                                width: 60,
                                height: 60,
                                margin: EdgeInsets.only(
                                  right: index < 3 ? 12 : 0,
                                ),
                                child: TextField(
                                  controller: _otpControllers[index],
                                  focusNode: _otpFocusNodes[index],
                                  textAlign: TextAlign.center,
                                  keyboardType: TextInputType.number,
                                  maxLength: 1,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  decoration: InputDecoration(
                                    counterText: '',
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFE0E0E0),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFE0E0E0),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                        color: Colors.black,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  onChanged: (value) {
                                    _handleOtpInput(index, value);
                                  },
                                ),
                              );
                            }),
                          ),

                          const SizedBox(height: 30),

                          // Didn't receive the code ? text (center)
                          const Text(
                            "Didn't receive the code ?",
                            style: TextStyle(
                              color: Color(0xFF868889),
                              fontSize: 15,
                              fontWeight: FontWeight.normal, // Poppins Regular
                              fontFamily: 'Poppins',
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 8),

                          // Resend a new code button (center)
                          TextButton(
                            onPressed: () {
                              _generateNewOtp();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('New OTP code generated. Please enter the new code.'),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Resend a new code',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 15,
                                fontWeight: FontWeight.w500, // Poppins Medium
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),

                          const SizedBox(height: 30),

                          // Verify Button (354x60) - centered
                          Center(
                            child: SizedBox(
                              width: 354,
                              height: 60,
                              child: ElevatedButton(
                                onPressed: _isOtpComplete ? _handleVerify : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: Colors.grey,
                                  disabledForegroundColor: Colors.white70,
                                  padding: EdgeInsets.zero,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: const Text(
                                  'Verify',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500, // Poppins Medium
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 30),

                          // Already have an account ? Login (centered)
                          Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Already have an account ? ',
                                  style: TextStyle(
                                    color: Color(0xFF868889),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500, // Poppins Mixed
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const LoginPage(),
                                      ),
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text(
                                    'Login',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500, // Poppins Mixed
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

