import 'package:flutter/material.dart';
import 'package:athlosight/policies_with_dialogs/policy_dialog.dart';
import 'package:athlosight/widgets/visible_screen.dart';

class TermsAndPrivacyScreen extends StatefulWidget {
  const TermsAndPrivacyScreen({super.key});

  @override
  TermsAndPrivacyScreenState createState() => TermsAndPrivacyScreenState();
}

class TermsAndPrivacyScreenState extends State<TermsAndPrivacyScreen> {
  bool _termsAccepted = false;
  bool _privacyAccepted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: const Text('Terms of Use and Privacy Policy'),
          leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: const Text("Click to read →"),
                ),
                GestureDetector(
                  onTap: () {
                    showDialog(
                        context: context,
                        builder: (context) {
                          return PolicyDialog(mdFileName: 'terms_of_use.md');
                        });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: const Text(
                      "Terms of Use",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple),
                    ),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: const Text("Click to read →"),
                ),
                GestureDetector(
                  onTap: () {
                    showDialog(
                        context: context,
                        builder: (context) {
                          return PolicyDialog(mdFileName: 'privacy_policy.md');
                        });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: const Text(
                      "Privacy Policy",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple),
                    ),
                  ),
                ),
              ],
            ),
            CheckboxListTile(
              title: const Text('I accept the Terms of Use'),
              subtitle: const Text('Tap checkbox to accept the Terms of Use'),
              value: _termsAccepted,
              onChanged: (bool? value) {
                setState(() {
                  _termsAccepted = value!;
                });
              },
            ),
            CheckboxListTile(
              title: const Text('I accept the Privacy Policy'),
              subtitle: const Text('Tap checkbox to accept the Privacy Policy'),
              value: _privacyAccepted,
              onChanged: (bool? value) {
                setState(() {
                  _privacyAccepted = value!;
                });
              },
            ),
            ElevatedButton(
              onPressed: (_termsAccepted && _privacyAccepted)
                  ? () {
                      // Navigate to the sign-up screen
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const VisibleScreen(initialIndex: 0, userProfileImageUrl: '',),
                        ),
                      );
                    }
                  : null,
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}