// ignore_for_file: use_build_context_synchronously

/* 
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  User? _currentUser;
  String? _profilePictureUrl;
  String _selectedTimezone = 'UTC';

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    _loadProfilePicture();
    _loadUserTimezone();
  }

  Future<void> _loadProfilePicture() async {
    if (_currentUser != null) {
      try {
        final url = await _storage
            .ref('profile_pictures/${_currentUser!.uid}.jpg')
            .getDownloadURL();
        setState(() {
          _profilePictureUrl = url;
        });
      } catch (e) {
        // Handle error if profile picture doesn't exist
      }
    }
  }

  Future<void> _loadUserTimezone() async {
    if (_currentUser != null) {
      final userDoc = await _firestore.collection('users').doc(_currentUser!.uid).get();
      final int timezoneOffset = userDoc.data()?['timezone'] ?? 0;
      final timezones = {
        'UTC': 0,
        'New York': -4,
        'Rio de Janeiro': -3,
        'London': 1,
        'Berlin': 2,
        'Tokyo': 9,
        // Add more timezones and major cities as needed
      };

      final city = timezones.entries.firstWhere(
        (entry) => entry.value == timezoneOffset,
        orElse: () => const MapEntry('UTC', 0),
      ).key;

      setState(() {
        _selectedTimezone = city;
      });
    }
  }

  Future<void> _uploadProfilePicture() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final file = File(pickedFile.path);
      try {
        await _storage.ref('profile_pictures/${_currentUser!.uid}.jpg').putFile(file);
        _loadProfilePicture();
      } catch (e) {
        // Handle error
      }
    }
  }

  Future<void> _updateTimezone(String timezone) async {
    final timezones = {
      'UTC': 0,
      'New York': -4,
      'Rio de Janeiro': -3,
      'London': 1,
      'Berlin': 2,
      'Tokyo': 9,
      // Add more timezones and major cities as needed
    };
    if (_currentUser != null) {
      await _firestore.collection('users').doc(_currentUser!.uid).update({
        'timezone': timezones[timezone],
      });
      setState(() {
        _selectedTimezone = timezone;
      });
    }
  }

  Widget _buildProfileSection() {
    return Column(
      children: [
        _profilePictureUrl != null
            ? CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(_profilePictureUrl!),
              )
            : const CircleAvatar(
                radius: 50,
                child: Icon(Icons.person),
              ),
        TextButton(
          onPressed: _uploadProfilePicture,
          child: const Text('Upload Profile Picture'),
        ),
      ],
    );
  }

  Widget _buildTimezoneDropdown() {
    final timezones = {
      'UTC': 0,
      'New York': -4,
      'Rio de Janeiro': -3,
      'London': 1,
      'Berlin': 2,
      'Tokyo': 9,
      // Add more timezones and major cities as needed
    };

    return DropdownButton<String>(
      value: _selectedTimezone,
      onChanged: (String? newValue) {
        if (newValue != null) {
          _updateTimezone(newValue);
        }
      },
      items: timezones.keys.map<DropdownMenuItem<String>>((String key) {
        return DropdownMenuItem<String>(
          value: key,
          child: Text(key),
        );
      }).toList(),
    );
  }
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildProfileSection(),
              const SizedBox(height: 20),
              _buildTimezoneDropdown(),
              const SizedBox(height: 20),
              const Text('My Posts', style: TextStyle(fontSize: 20)),
                    StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection("posts")
                .orderBy('time', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              var posts = snapshot.data!.docs;
              //posts.removeWhere((element) => element['userId'] == auth.currentUser!.uid);
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  var post = posts[index];
                  //print('Post: ${post.data()}');
                  var userRef = post['user'];
                  if (userRef is DocumentReference && post['userId'] == _currentUser?.uid) {
                    return FutureBuilder<DocumentSnapshot>(
                      future: userRef.get(),
                      builder: (context, userSnapshot) {
                        if (userSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (!userSnapshot.hasData ||
                            !userSnapshot.data!.exists) {
                          return const Center(child: Text("User not found"));
                        }
                        var user = userSnapshot.data;
                        var username = user!['username'];
                        var timestamp = (post['time'] as Timestamp).toDate();
                        var formattedTime = DateFormat.jm().format(timestamp);
                        return PostWidget(
                          username: username,
                          timestamp: formattedTime,
                          message: post['message'],
                        );
                      },
                    );
                  } else {
                    return Container();
                  }
                },
              );
            },
          ),
            ],
          ),
        ),
      ),
    );
  }
}

class PostWidget extends StatelessWidget {
  final String username;
  final String timestamp;
  final String message;

  const PostWidget({
    super.key,
    required this.username,
    required this.timestamp,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
      color: Colors.red.shade100,
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  username,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  timestamp,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(message),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {},
                  child: const Row(
                    children: [
                      Icon(Icons.comment),
                      SizedBox(width: 5),
                      Text('Comment'),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Row(
                    children: [
                      Icon(Icons.thumb_up),
                      SizedBox(width: 5),
                      Text('Like'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} */

import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:togetherapart/widgets/posts.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  User? _currentUser;
  late DocumentSnapshot<Map<String, dynamic>> userDoc;
  String? _profilePictureUrl;
  String? _selectedTimezone;
  final _timezones = {
    'UTC': 0,
    'New York': -4,
    'Rio de Janeiro': -3,
    'London': 1,
    'Berlin': 2,
    'Tokyo': 9,
  };

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    _loadUserDoc();
    
  }

  Future<void> _loadUserDoc() async {
    if (_currentUser != null) {
      userDoc =
          await _firestore.collection('users').doc(_currentUser!.uid).get();
    }

    _loadProfilePicture();
    _loadUserTimezone();
  }

  Future<void> _loadProfilePicture() async {
    if (_currentUser != null) {
      try {
        final url = await userDoc.data()?['profile_picture'];

        setState(() {
          _profilePictureUrl = url;
        });
      } catch (e) {
        // Handle error if profile picture doesn't exist
        if (kDebugMode) {
          print('Error loading profile picture: $e');
        }
      }
    }
  }

  Future<void> _loadUserTimezone() async {
    if (_currentUser != null) {
      userDoc =
          await _firestore.collection('users').doc(_currentUser!.uid).get();

      final int timezoneOffset = userDoc.data()?['timezone'] ?? 0;

      final city = _timezones.entries
          .firstWhere(
            (entry) => entry.value == timezoneOffset,
            orElse: () => const MapEntry('UTC', 0),
          )
          .key;

      setState(() {
        _selectedTimezone = city;
      });
    }
  }

  Future<void> _uploadProfilePicture() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final file = File(pickedFile.path);
      try {
        // Upload image to Firebase Storage
        var snapshot = await _storage
            .ref()
            .child('profile_pictures/${_auth.currentUser!.uid}')
            .putFile(file);

        // Get download URL of uploaded image
        String downloadUrl = await snapshot.ref.getDownloadURL();

        // Update user's profile picture in Firestore
        await _firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .update({
          'profile_picture': downloadUrl,
        });

        // Update state to reflect the changes
        setState(() {
          _profilePictureUrl = downloadUrl;
        });

        // Show success message or handle further operations
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated successfully')),
        );
      } catch (e) {
        // Handle errors
        if (kDebugMode) {
          print('Failed to upload profile picture: $e');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload profile picture')),
        );
      }
    }
  }

  Future<void> _updateTimezone(String timezone) async {
    if (_currentUser != null) {
      await _firestore.collection('users').doc(_currentUser!.uid).update({
        'timezone': _timezones[timezone],
        'location': timezone,
      });
      setState(() {
        _selectedTimezone = timezone;
      });
    }
  }

  Widget _buildProfileSection() {
    return Column(
      children: [
        _profilePictureUrl != null
            ? CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(_profilePictureUrl!),
              )
            : const CircleAvatar(
                radius: 50,
                child: Icon(Icons.person),
              ),
        TextButton(
          onPressed: _uploadProfilePicture,
          child: const Text('Upload Profile Picture'),
        ),
      ],
    );
  }

  Widget _buildTimezoneDropdown() {
    return DropdownButton<String>(
      value: _selectedTimezone,
      onChanged: (String? newValue) {
        if (newValue != null) {
          _updateTimezone(newValue);
        }
      },
      items: _timezones.keys.map<DropdownMenuItem<String>>((String key) {
        return DropdownMenuItem<String>(
          value: key,
          child: Text(key),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Profile'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildProfileSection(),
              const SizedBox(height: 20),
              const Text('Your Location'),
              _buildTimezoneDropdown(),
              const SizedBox(height: 20),
              const Text('My Posts', style: TextStyle(fontSize: 20)),
              StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection("posts")
                    .orderBy('time', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  var posts = snapshot.data!.docs;
                  //posts.removeWhere((element) => element['userId'] == auth.currentUser!.uid);
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      var post = posts[index];
                      //print('Post: ${post.data()}');
                      var userRef = post['user'];
                      if (userRef is DocumentReference &&
                          post['userId'] == _currentUser?.uid) {
                        return FutureBuilder<DocumentSnapshot>(
                          future: userRef.get(),
                          builder: (context, userSnapshot) {
                            if (userSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }
                            if (!userSnapshot.hasData ||
                                !userSnapshot.data!.exists) {
                              return const Center(
                                  child: Text("User not found"));
                            }
                            var user = userSnapshot.data;
                            var username = user!['username'];
                            var timestamp =
                                (post['time'] as Timestamp).toDate();
                            var formattedTime =
                                DateFormat.jm().format(timestamp);
                            return PostWidget(
                              username: username,
                              timestamp: formattedTime,
                              message: post['message'],
                            );
                          },
                        );
                      } else {
                        return Container();
                      }
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

