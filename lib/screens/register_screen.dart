import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:athlosight/policies_with_dialogs/terms_and_privacy.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  RegisterScreenState createState() => RegisterScreenState();
}

class RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _usernameController = TextEditingController();
  DateTime? _selectedDate;
  int? _age;
  File? _profileImage;
  final ImagePicker _imagePicker = ImagePicker();
  final Logger _logger = Logger();
  String? _currentCountry;
  bool _isLocationAvailable = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _calculateAge();
      });
    }
  }

  Future<void> _selectProfileImage() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                GestureDetector(
                  child: const Text('Gallery'),
                  onTap: () async {
                    Navigator.pop(context);
                    final List<XFile> pickedImages = await _imagePicker.pickMultiImage(
                      imageQuality: 80,
                      maxWidth: 500,
                      maxHeight: 500,
                    );

                    if (pickedImages.isNotEmpty) {
                      setState(() {
                        _profileImage = File(pickedImages[0].path);
                      });
                    }
                  },
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  child: const Text('Camera'),
                  onTap: () async {
                    Navigator.pop(context);
                    final XFile? pickedImage = await _imagePicker.pickImage(
                      source: ImageSource.camera,
                      imageQuality: 80,
                      maxWidth: 500,
                      maxHeight: 500,
                    );

                    if (pickedImage != null) {
                      setState(() {
                        _profileImage = File(pickedImage.path);
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _validateFields() {
    if (_profileImage == null || _usernameController.text.trim().isEmpty || _selectedDate == null) {
      return false;
    }
    return true;
  }

  void _calculateAge() {
    if (_selectedDate != null) {
      final currentDate = DateTime.now();
      final difference = currentDate.difference(_selectedDate!);
      final age = difference.inDays ~/ 365;
      setState(() {
        _age = age;
      });
    }
  }

  void _getCurrentLocation() async {
    final PermissionStatus permissionStatus = await _requestLocationPermissions();
    if (permissionStatus == PermissionStatus.granted) {
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        setState(() {
          _isLocationAvailable = true;
        });
        await _updateCountry(position.latitude, position.longitude);
      } catch (error) {
        _logger.e('Error getting current location: $error');
      }
    } else {
      // Permission not granted, handle accordingly
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Location Permission'),
          content: const Text('Please grant location permission to use this feature and to complete your registration'),
          actions: <Widget>[
            GestureDetector(
              child: const Text('OK'),
              onTap: () {
                Navigator.of(context).pop();
                _getCurrentLocation(); // Retry getting location
              },
            ),
          ],
        ),
      );
    }
  }

  Future<PermissionStatus> _requestLocationPermissions() async {
    final status = await Permission.location.request();
    return status;
  }

  Future<void> _updateLocation(String uid) async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'country': _currentCountry,
      });
    } catch (error) {
      _logger.e('Error updating location: $error');
    }
  }

  Future<void> _updateCountry(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks[0];
        setState(() {
          _currentCountry = placemark.country;
        });

        // If the user has completed registration before location became available,
        // update the location in Firestore now
        if (_isLocationAvailable) {
          final String uid = FirebaseAuth.instance.currentUser!.uid;
          await _updateLocation(uid);
        }
      }
    } catch (error) {
      _logger.e('Error getting country: $error');
    }
  }

  Future<void> saveUserData(
    String username,
    DateTime? selectedDate,
    int? age,
    String email,
    String uid,
  ) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'username': username,
        'selectedDate': selectedDate,
        'age': age,
        'email': email,
        'uid': uid,
      });

      if (_profileImage != null) {
        final String fileName = '${uid}_profile_image.jpg';
        final firebase_storage.Reference ref =
            firebase_storage.FirebaseStorage.instance.ref().child('profile_pictures/$fileName');
        await ref.putFile(_profileImage!);

        final String imageUrl = await ref.getDownloadURL();

        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'profileImageUrl': imageUrl,
        });
      }

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Registration Complete'),
            content: const Text('User data saved successfully.'),
            actions: [
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          );
        },
      );
    } catch (error) {
      _logger.e('Error saving user data: $error');
    }
  }

 Future<bool> isUsernameTaken(String username) async {
    final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('username', isEqualTo: username)
        .get();

    return querySnapshot.docs.isNotEmpty;
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: const Text('Register'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _selectProfileImage,
              child: CircleAvatar(
                radius: 64,
                backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                child: _profileImage == null ? const Icon(Icons.add_a_photo, size: 48) : null,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => _selectDate(context),
              child: Container(
                margin: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _selectedDate != null
                      ? 'Date of Birth: ${DateFormat('dd/MM/yyyy').format(_selectedDate!)}'
                      : 'Select Date of Birth',
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _age != null ? 'Age: $_age years' : '',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final PermissionStatus permissionStatus = await _requestLocationPermissions();
                if (permissionStatus == PermissionStatus.granted) {
                  if (_validateFields()) {
                    final String username = _usernameController.text.trim();
                    final String email = FirebaseAuth.instance.currentUser!.email!;
                    final String uid = FirebaseAuth.instance.currentUser!.uid;

                    // Check if the username is already taken
                    final bool isTaken = await isUsernameTaken(username);
                    if (isTaken) {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Username Taken'),
                            content: const Text('The chosen username is already taken. Please choose a different username.'),
                            actions: [
                              TextButton(
                                child: const Text('OK'),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                              ),
                            ],
                          );
                        },
                      );
                      return; // Exit the function without proceeding further
                    }

                    // Save the user data to Firestore and Firebase Storage
                    saveUserData(username, _selectedDate, _age, email, uid);

                    // Navigate to the HomeScreen or any other desired screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (BuildContext context) => const TermsAndPrivacyScreen(),
                      ),
                    );

                    // Update the user's location
                    _updateLocation(uid);
                  } else {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Validation Error'),
                          content: const Text('Please fill in all the required fields.'),
                          actions: [
                            TextButton(
                              child: const Text('OK'),
                              onPressed: () {
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        );
                      },
                    );
                  }
                }
              },
              child: const Text('Complete Registration'),
            ),
            if (_currentCountry != null) ...[
              const SizedBox(height: 10),
              Text(
                'Current Country: $_currentCountry',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    title: 'Username Availability Check',
    home: RegisterScreen(),
  ));
}
