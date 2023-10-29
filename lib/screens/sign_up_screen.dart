import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logger/logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:athlosight/screens/login_screen.dart';
import 'package:athlosight/screens/register_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  SignUpScreenState createState() => SignUpScreenState();
}

class SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final Logger _logger = Logger();
  bool _showPassword = false;

  void toggleShowPassword() {
    setState(() {
      _showPassword = !_showPassword;
    });
  }

  Future<void> signUp(String email, String password) async {
    try {
      // Create a new user with email and password
      final UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save user data to Firestore
      saveUserData(email, userCredential.user!.uid);

      // Navigate to the register screen after successful sign-up
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (BuildContext context) => const RegisterScreen()),
      );
    } on FirebaseAuthException catch (e) {
      // Handle sign-up errors here
      if (e.code == 'weak-password') {
        // Handle weak password error
        _logger.i('The password provided is too weak.');
        showErrorMessage('The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        // Handle email already in use error
        _logger.i('The account already exists for that email.');
        showErrorMessage('The account already exists for that email.');
      } else {
        // Handle other errors
        _logger.i('Error occurred: ${e.message}');
        showErrorMessage('An error occurred: ${e.message}');
      }
    } catch (e) {
      _logger.i('Error occurred: $e');
      showErrorMessage('An error occurred: $e');
    }
  }

  Future<void> saveUserData(String email, String uid) async {
    try {
      // Create a Firestore instance
      final FirebaseFirestore firestore = FirebaseFirestore.instance;

      // Get a reference to the user document using the UID
      final DocumentReference userRef = firestore.collection('users').doc(uid);

      // Check if the user document already exists
      final DocumentSnapshot userSnapshot = await userRef.get();
      if (userSnapshot.exists) {
        // User document already exists, no need to save again
        _logger.i('User data already exists in Firestore.');
        return;
      }

      // Create a new user document with the email and UID
      await userRef.set({
        'email': email,
        'uid': uid,
      });

      _logger.i('User data saved successfully.');
    } catch (e) {
      _logger.e('Error saving user data: $e');
    }
  }

  void showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }
Future<void> signInWithGoogle() async {
  try {
    // Trigger the authentication flow
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

    // Check if the user cancelled the sign-in process
    if (googleUser == null) {
      return;
    }

    // Obtain the auth details from the request
    final GoogleSignInAuthentication? googleAuth = await googleUser.authentication;

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );

    // Sign in to Firebase with the Google credential
    final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

    // Use the userCredential for further processing if needed
    // For example, you can get the user's email and UID like this:
    final String email = userCredential.user?.email ?? '';
    final String uid = userCredential.user?.uid ?? '';

    // Save user data to Firestore
    await saveUserData(email, uid);

    // The user is now signed in, you can handle the sign-in success here
    // For example, navigate to the next screen or save user data to Firestore.
    // In this case, you can call the saveUserData method as before.

    Navigator.push(
      context,
      MaterialPageRoute(builder: (BuildContext context) => const RegisterScreen()),
    );
  } catch (e) {
    _logger.i('Error occurred during Google Sign-In: $e');
    showErrorMessage('An error occurred during Google Sign-In.');
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          automaticallyImplyLeading: false, // Remove the default back arrow
        backgroundColor: Colors.deepPurple,
        title: const Text('Sign Up'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
             ClipRRect(
              borderRadius: BorderRadius.circular(
                  30), // Adjust the radius value as needed
              child: Image.asset(
                'assets/IMG-20230529-WA0107.jpg',
                width: 100,
                height: 100,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              obscureText: !_showPassword,
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  icon: Icon(
                    _showPassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: toggleShowPassword,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final String email = _emailController.text.trim();
                final String password = _passwordController.text.trim();
      
                // Call the sign-up method
                signUp(email, password);
              },
              child: const Text('Sign Up'),
            ),
             const SizedBox(height: 5),
   Stack(
      alignment: Alignment.center,
      children: [
        const Divider(
          color: Colors.deepPurple, // Set the divider color to deep purple
          height: 1,
        ),
        Container(
          color: Colors.white, // Set the background color of the "or" text container
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: const Text(
            'or',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.deepPurple, // Set the text color to deep purple
            ),
          ),
        ),
      ],
    ),
                 const SizedBox(height: 5),
        ElevatedButton(
      onPressed: signInWithGoogle, // Call the googleSignIn method when the button is pressed
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/7711fc11b51a844a4e9bd61569e39350.jpg', // Replace this with the path to your Google logo image
            height: 24,
            width: 24,
          ),
          const SizedBox(width: 8),
          const Text('Sign Up with Google'),
        ],
      ),
        ),
            const SizedBox(
              height: 12,
            ),
            Flexible(
              flex: 2,
              child: Container(),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                  ),
                  child: const Text("Already have an Account?"),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (BuildContext context) => const LoginScreen(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                    ),
                    child: const Text(
                      "Login",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}