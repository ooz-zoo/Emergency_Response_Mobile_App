import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class LogScreen extends StatefulWidget {
  @override
  _LogScreenState createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  User? currentUser;
  TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  DateTime? startDate;
  DateTime? endDate;

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
  }

  void updateSearchQuery(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
    });
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != (isStartDate ? startDate : endDate)) {
      setState(() {
        if (isStartDate) {
          startDate = picked;
        } else {
          endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Color customBlue = const Color(0xFF007BFF);

    return Scaffold(
      backgroundColor: customBlue,
      body: SafeArea(
        child: Column(
          children: [
            // Header section with the icon and title
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 65,
                    height: 65,
                    decoration: BoxDecoration(
                      image: const DecorationImage(
                        image: AssetImage('lib/pages/ern/assets/log-file.png'),
                        fit: BoxFit.cover,
                      ),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'EMERGENCY LOGS',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            // Search Bar and Date Filters Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  // Search Bar
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      onChanged: updateSearchQuery,
                      decoration: InputDecoration(
                        hintText: 'Search logs...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Start Date Picker Button
                  IconButton(
                    icon: Icon(Icons.calendar_today, color: Colors.white),
                    onPressed: () => _selectDate(context, true),
                  ),
                  const SizedBox(width: 10),
                  // End Date Picker Button
                  IconButton(
                    icon: Icon(Icons.calendar_today, color: Colors.white),
                    onPressed: () => _selectDate(context, false),
                  ),
                ],
              ),
            ),
            // Displaying selected dates
            if (startDate != null || endDate != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Selected dates: ${startDate != null ? startDate!.toLocal().toString().split(' ')[0] : 'No start date'} - ${endDate != null ? endDate!.toLocal().toString().split(' ')[0] : 'No end date'}',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            // Scrollable log list inside a white container
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: Colors.black,
                    width: 3.0,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(25.0),
                    topRight: Radius.circular(25.0),
                  ),
                ),
                padding: const EdgeInsets.all(16.0),
                child: currentUser == null
                    ? Center(child: CircularProgressIndicator())
                    : FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(currentUser!.uid)
                      .get(),
                  builder: (context, userSnapshot) {
                    if (!userSnapshot.hasData) {
                      return Center(child: CircularProgressIndicator());
                    }

                    if (!userSnapshot.data!.exists) {
                      return Center(child: Text('No user data found.'));
                    }

                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(currentUser!.uid)
                          .collection('alertLogs')
                          .snapshots(),
                      builder: (context, logSnapshot) {
                        if (!logSnapshot.hasData) {
                          return Center(child: CircularProgressIndicator());
                        }

                        var logs = logSnapshot.data!.docs;

                        if (logs.isEmpty) {
                          return Center(child: Text('No alert logs found.'));
                        }

                        // Filter logs based on search query and date range
                        var filteredLogs = logs.where((log) {
                          DateTime logDate = log['timestamp'].toDate();
                          bool matchesSearch = log['location']
                              .toLowerCase()
                              .contains(searchQuery) ||
                              log['driverStatus']
                                  .toLowerCase()
                                  .contains(searchQuery) ||
                              log['ResponseType']
                                  .toLowerCase()
                                  .contains(searchQuery);

                          bool matchesDateRange = true;

                          if (startDate != null && logDate.isBefore(startDate!)) {
                            matchesDateRange = false;
                          }

                          if (endDate != null && logDate.isAfter(endDate!)) {
                            matchesDateRange = false;
                          }

                          return matchesSearch && matchesDateRange;
                        }).toList();

                        if (filteredLogs.isEmpty) {
                          return Center(child: Text('No matching logs found.'));
                        }

                        return ListView.builder(
                          itemCount: filteredLogs.length,
                          itemBuilder: (context, index) {
                            var log = filteredLogs[index];
                            return Column(
                              children: [
                                LogCard(
                                  logTitle: 'Log ${index + 1}',
                                  alertId: log.id,
                                  briefSummary:
                                  '${log['driverStatus']} | ${log['location']} | ${log['ResponseType']}',
                                  timestamp: log['timestamp']
                                      .toDate()
                                      .toString(),
                                  location: log['location'],
                                  driverStatus: log['driverStatus'],
                                  responseStatus: log['ResponseType'],
                                  contactName: log['contactName'],
                                  contactId: log['contactID'],
                                ),
                                const SizedBox(height: 16), // Add space between logs
                              ],
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//import 'package:flutter/material.dart';

//import 'package:flutter/material.dart';

//import 'package:flutter/material.dart';

//import 'package:flutter/material.dart';

//import 'package:flutter/material.dart';

//import 'package:flutter/material.dart';

//import 'package:flutter/material.dart';

class LogCard extends StatefulWidget {
  final String logTitle;
  final String alertId;
  final String briefSummary;
  final String timestamp;
  final String location;
  final String driverStatus;
  final String responseStatus;
  final String contactName;
  final String contactId;

  const LogCard({
    required this.logTitle,
    required this.alertId,
    required this.briefSummary,
    required this.timestamp,
    required this.location,
    required this.driverStatus,
    required this.responseStatus,
    required this.contactName,
    required this.contactId,
  });

  @override
  _LogCardState createState() => _LogCardState();
}

class _LogCardState extends State<LogCard> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          isExpanded = !isExpanded;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title & Expand/Collapse Arrow
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: _getWarningColor(widget.driverStatus),
                      size: 30,
                    ),
                    SizedBox(width: 12),
                    Text(
                      widget.logTitle,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: Duration(milliseconds: 200),
                  child: Icon(
                    Icons.arrow_drop_down,
                    size: 30,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            // Brief Summary Display
            if (!isExpanded) ...[
              SizedBox(height: 12),
              // Display Key Information
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildKeyInfo('Timestamp', _formatTimestamp(widget.timestamp)),
                  _buildKeyInfo('Status', widget.driverStatus),
                ],
              ),
              SizedBox(height: 12),
              // Location
              Row(
                children: [
                  Icon(Icons.location_on, color: Colors.green, size: 20),
                  SizedBox(width: 8),
                  Text(
                    _trimLocation(widget.location),
                    style: TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                ],
              ),
            ],
            // Expanded Details
            if (isExpanded) ...[
              _buildSectionTitle('Alert Details'),
              _buildDetailRow('Alert ID', widget.alertId),
              _buildDetailRow('Timestamp', _formatTimestamp(widget.timestamp)), // Use formatted timestamp here
              _buildDetailRow('Location', _trimLocationForDetails(widget.location)),
              _buildDetailRow('Driver Status', widget.driverStatus),

              _buildSectionTitle('Emergency Contact Information'),
              _buildDetailRow('Contact Name', widget.contactName),
              _buildDetailRow('Contact ID', widget.contactId),
              _buildDetailRow('Response Status', widget.responseStatus),
            ],
          ],
        ),
      ),
    );
  }

  Color _getWarningColor(String driverStatus) {
    switch (driverStatus.toLowerCase()) {
      case 'drowsy':
        return Colors.yellow;
      case 'drunk':
        return Colors.red;
      default:
        return Colors.green;
    }
  }

  Widget _buildKeyInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.black54,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue, size: 20),
          SizedBox(width: 12),
          Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.black87),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _trimLocation(String location) {
    // Split the location string by "Map" and return the first part
    return location.split('Map').first.trim();
  }
  String _trimLocationForDetails(String location) {
    // Implement your trimming logic for details here
    int index = location.indexOf('Map:');
    return index != -1 ? location.substring(0, index).trim() : location.trim();
  }
  String _formatTimestamp(String timestamp) {
    try {
      DateTime dateTime = DateTime.parse(timestamp); // Assuming the timestamp is in ISO 8601 format
      // Format to "h:mm a MMM d, yyyy" (e.g., "12:54 PM Nov 19, 2024")
      String formatted = DateFormat('h:mm a MMM d, yyyy').format(dateTime);
      return formatted;
    } catch (e) {
      print('Error parsing timestamp: $timestamp'); // Debug output
      return 'Invalid Date';
    }
  }
}