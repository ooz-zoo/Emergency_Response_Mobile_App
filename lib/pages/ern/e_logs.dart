import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LogScreen extends StatefulWidget {
  @override
  _LogScreenState createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  User? currentUser;

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
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
                        return ListView.builder(
                          itemCount: logs.length,
                          itemBuilder: (context, index) {
                            var log = logs[index];
                            return Column(
                              children: [
                            LogCard(
                            logTitle: 'Log ${index + 1}',
                              alertId: log.id,
                              briefSummary: '${log['driverStatus']} | ${log['location']} | ${log['ResponseType']}',
                              timestamp: log['timestamp'].toDate().toString(),
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
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.logTitle,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Icon(
                  isExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  color: Colors.black,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (!isExpanded) ...[
              Text(
                'AlertID:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(widget.alertId),
              const SizedBox(height: 8),
              Text(
                'Brief Summary:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(widget.briefSummary),
            ] else ...[
              Text(
                'AlertID:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(widget.alertId),
              const SizedBox(height: 8),
              Text(
                'Timestamp:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(widget.timestamp),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on),
                  const SizedBox(width: 8),
                  Text(
                    'Location:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Text(widget.location),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.warning),
                  const SizedBox(width: 8),
                  Text(
                    'Driver Status:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Text(widget.driverStatus),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.check_circle),
                  const SizedBox(width: 8),
                  Text(
                    'Response Status:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Text(widget.responseStatus),
              const SizedBox(height: 8),
              Text(
                'Emergency Contact Response Details:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(widget.contactName),
              const SizedBox(height: 8),
              Text(widget.contactId),
            ],
          ],
        ),
      ),
    );
  }
}
