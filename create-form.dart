import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class User {
  final String username;
  final String password;
  final String email;
  final String role;
  final String otp;

  User({
    required this.username,
    required this.password,
    required this.email,
    required this.role,
    required this.otp,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
      'email': email,
      'role': role,
      'otp': otp,
    };
  }
}

class CreateUserPage extends StatefulWidget {
  @override
  _CreateUserPageState createState() => _CreateUserPageState();
}

class _CreateUserPageState extends State
{
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _roleController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  Future<void> _createUser() async {
    final user = User(
      username: _usernameController.text,
      password: _passwordController.text,
      email: _emailController.text,
      role: _roleController.text,
      otp: _otpController.text,
    );

    final response = await http.post(
      Uri.parse('http://127.0.0.1:8000/users/'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(user.toJson()),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      final status = responseData['status'];
      final String message = responseData['msg'];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create user')),
      );
    }
    Navigator.of(context).pop(); // Close the dialog
    _usernameController.text = "";
    _passwordController.text = "";
    _emailController.text = "";
    _roleController.text = "";
    _otpController.text = "";
  }

  void _dialogOtpSendingLoading() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('OTP Sending'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircularProgressIndicator(), // Spinner/loader
              SizedBox(height: 16), // Spacer
              Text('Please wait...'), // Text indicating waiting
            ],
          ),
        );
      },
    );
  }

  Future<void> _verifyOtp() async {
    _dialogOtpSendingLoading();
    final response = await http.post(
      Uri.parse('http://127.0.0.1:8000/generate_otp/?email=${_emailController.text}'),
    );
    if (response.statusCode == 200) {
      Navigator.of(context).pop(); // Close loading dialog
      _dialogEnterOtpForVerification();
    } else {
      Navigator.of(context).pop(); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send OTP')),
      );
    }
  }

  void _dialogEnterOtpForVerification() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Verify OTP'),
          content: TextField(
            controller: _otpController,
            decoration: InputDecoration(
              labelText: 'Enter OTP',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                _submitOtp();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightGreen, // Light green color
                textStyle: TextStyle(fontWeight: FontWeight.bold), // Bold text
              ),
              child: Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  void _submitOtp() {
    _createUser();
    Navigator.of(context).pop(); // Close the dialog
    _dialogOtpVerifyingLoading();
  }

  void _dialogOtpVerifyingLoading() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('OTP Verifying'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircularProgressIndicator(), // Spinner/loader
              SizedBox(height: 16), // Spacer
              Text('Please wait...'), // Text indicating waiting
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.purple, // Violet background for appbar
        title: Text(
          'Create User',
          style: TextStyle(
            fontWeight: FontWeight.bold, // Bold text
            color: Colors.white, // White text color
          ),
        ),
      ),
      body: Container(
        color: Colors.greenAccent, // Custom color for form background
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _usernameController,
                style: TextStyle(
                  color: Colors.white, // White text color
                  fontWeight: FontWeight.bold, // Bold text
                ),
                decoration: InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                style: TextStyle(
                  color: Colors.white, // White text color
                  fontWeight: FontWeight.bold, // Bold text
                ),
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              SizedBox(height: 12),
              TextField(
                controller: _emailController,
                style: TextStyle(
                  color: Colors.white, // White text color
                  fontWeight: FontWeight.bold, // Bold text
                ),
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: _roleController,
                style: TextStyle(
                  color: Colors.white, // White text color
                  fontWeight: FontWeight.bold, // Bold text
                ),
                decoration: InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12),
              ElevatedButton(
                onPressed: _verifyOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white, // Light green color
                  textStyle: TextStyle(fontWeight: FontWeight.bold), // Bold text
                ),
                child: Text('Create User'),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
