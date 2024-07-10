import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();
  late DateTime _selectedDate;
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  String _viewMode = 'me';
  CalendarFormat _calendarFormat = CalendarFormat.month;
  String? _partnerId;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int? _userTimezone;
  int? _partnerTimezone;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _getUserAndPartnerInfo();
  }

  Future<void> _getUserAndPartnerInfo() async {
    final uid = _auth.currentUser!.uid;
    final userDoc = await _firestore.collection('users').doc(uid).get();
    final partnerId = userDoc.data()?['partner'];
    final userTimezone = userDoc.data()?['timezone'];

    if (partnerId != null) {
      final partnerDoc =
          await _firestore.collection('users').doc(partnerId).get();
      final partnerTimezone = partnerDoc.data()?['timezone'];

      setState(() {
        _partnerId = partnerId;
        _userTimezone = userTimezone;
        _partnerTimezone = partnerTimezone;
      });
    } else {
      setState(() {
        _userTimezone = userTimezone;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _addEvent(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      final String title = _titleController.text;
      final String description = _descriptionController.text;
      final DateTime start = _selectedDate;
      final DateTime end = _selectedDate.add(const Duration(hours: 1));

      await _firestore.collection('calendar_events').add({
        'title': title,
        'start': start,
        'end': end,
        'description': description,
        'userId': _auth.currentUser!.uid,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event added successfully')),
      );

      _titleController.clear();
      _descriptionController.clear();
      Navigator.of(context).pop();
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Widget _buildEventsList(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> events) {
    return ListView.builder(
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index].data();
        final bool isUserEvent = event['userId'] == _auth.currentUser!.uid;
        final DateTime startTime = (event['start'] as Timestamp).toDate();
        final DateTime endTime = (event['end'] as Timestamp).toDate();
        final timeFormat = DateFormat.Hm(); // Format to "HH:mm"
        DateTime partnerStartTime =
            startTime.add(Duration(hours: _partnerTimezone!));
        DateTime partnerEndTime =
            endTime.add(Duration(hours: _partnerTimezone!));
    
        // Calculate the extra times
        if (isUserEvent) {
          if (_userTimezone! < _partnerTimezone!) {
            final userTimeZoneOffset = _userTimezone != null
                ? Duration(hours: (_partnerTimezone! - _userTimezone!))
                : Duration.zero;
            partnerStartTime = startTime.add(userTimeZoneOffset);
            partnerEndTime = endTime.add(userTimeZoneOffset);
          } else {
            final userTimeZoneOffset = _userTimezone != null
                ? Duration(hours: (_userTimezone! - _partnerTimezone!))
                : Duration.zero;
            partnerStartTime = startTime.subtract(userTimeZoneOffset);
            partnerEndTime = endTime.subtract(userTimeZoneOffset);
          }
        } else {
          if (_userTimezone! < _partnerTimezone!) {
            final userTimeZoneOffset = _userTimezone != null
                ? Duration(hours: (_partnerTimezone! - _userTimezone!))
                : Duration.zero;
            partnerStartTime = startTime.subtract(userTimeZoneOffset);
            partnerEndTime = endTime.subtract(userTimeZoneOffset);
          } else {
            final userTimeZoneOffset = _userTimezone != null
                ? Duration(hours: (_userTimezone! - _partnerTimezone!))
                : Duration.zero;
            partnerStartTime = startTime.add(userTimeZoneOffset);
            partnerEndTime = endTime.add(userTimeZoneOffset);
          }
        }

        return Card(
          elevation: 5,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          color: isUserEvent? Colors.pink.shade200 : Colors.red.shade50,
          child: ListTile(
            contentPadding: const EdgeInsets.all(10),
            title: Text(
              event['title'],
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            subtitle: Text(
              'From: ${timeFormat.format(startTime)} (${timeFormat.format(partnerStartTime)})\n'
              'To: ${timeFormat.format(endTime)} (${timeFormat.format(partnerEndTime)})\n'
              '${event['description']}',
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          DropdownButton<String>(
            value: _viewMode,
            icon: const Icon(Icons.arrow_drop_down),
            onChanged: (String? newValue) {
              setState(() {
                _viewMode = newValue!;
              });
            },
            items: <String>['me', 'partner']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar(
            focusedDay: _selectedDate,
            firstDay: DateTime.now().subtract(const Duration(days: 365)),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            calendarFormat: _calendarFormat,
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDate = selectedDay;
              });
            },
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDate, day);
            },
            eventLoader: (day) {
              return [];
            },
          ),
          Expanded(
            child: _viewMode == 'me'
                ? StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _firestore
                        .collection('calendar_events')
                        .where('userId', isEqualTo: _auth.currentUser!.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const CircularProgressIndicator();
                      }
                      final events = snapshot.data!.docs.where((doc) =>
                          isSameDay(doc['start'].toDate(), _selectedDate));
                      return _buildEventsList(events.toList());
                    },
                  )
                : Row(
                    children: [
                      Expanded(
                        child:
                            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                          stream: _firestore
                              .collection('calendar_events')
                              .where('userId',
                                  isEqualTo: _auth.currentUser!.uid)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const CircularProgressIndicator();
                            }
                            final events = snapshot.data!.docs.where((doc) =>
                                isSameDay(
                                    doc['start'].toDate(), _selectedDate));
                            return _buildEventsList(events.toList());
                          },
                        ),
                      ),
                      const VerticalDivider(),
                      Expanded(
                        child:
                            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                          stream: _firestore
                              .collection('calendar_events')
                              .where('userId', isEqualTo: _partnerId)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const CircularProgressIndicator();
                            }
                            final events = snapshot.data!.docs.where((doc) =>
                                isSameDay(
                                    doc['start'].toDate(), _selectedDate));
                            return _buildEventsList(events.toList());
                          },
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Add Event'),
                content: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(labelText: 'Title'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _descriptionController,
                        decoration:
                            const InputDecoration(labelText: 'Description'),
                      ),
                      Row(
                        children: [
                          Text(
                              'Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}'),
                          TextButton(
                            onPressed: () => _selectDate(context),
                            child: const Text('Change'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => _addEvent(context),
                    child: const Text('Add'),
                  ),
                ],
              );
            },
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
