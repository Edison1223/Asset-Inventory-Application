
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'notification_service.dart';

class NotificationsPage extends StatefulWidget {
  final bool isAdmin;
  final String userId;

  const NotificationsPage({
    super.key,
    required this.isAdmin,
    required this.userId,
  });

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  bool _isCreating = false;
  bool _isGeneratingAlerts = false;
  String _selectedFilter = 'All'; // Default filter for dropdown

  // Local set to track deleted notification IDs
  final Set<String> _deletedNotificationIds = {};

  // Store the user's account creation date
  DateTime? _userCreatedAt;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _animationController.forward();

    // Fetch the user's creation date
    _fetchUserCreationDate();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generateMaintenanceAlerts();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _detailsController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Fetch the user's account creation date from Firestore
  Future<void> _fetchUserCreationDate() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        Timestamp? createdAt = userData['created_at'] as Timestamp?;
        if (createdAt != null) {
          setState(() {
            _userCreatedAt = createdAt.toDate();
          });
        } else {
          setState(() {
            _userCreatedAt = DateTime.now();
          });
        }
      } else {
        setState(() {
          _userCreatedAt = DateTime.now();
        });
      }
    } catch (e) {
      setState(() {
        _userCreatedAt = DateTime.now();
      });
    }
  }

  Future<void> _generateMaintenanceAlerts() async {
    setState(() {
      _isGeneratingAlerts = true;
    });
    try {
      // Fetch all assets
      QuerySnapshot assetsSnapshot =
          await FirebaseFirestore.instance.collection('assets').get();

      // Fetch all deleted_notifications in one go
      QuerySnapshot deletedNotificationsSnapshot = await FirebaseFirestore
          .instance
          .collection('deleted_notifications')
          .get();
      Map<String, List<Map<String, dynamic>>> deletedNotificationsMap = {};
      for (var doc in deletedNotificationsSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String assetId = data['assetId']?.toString() ?? '';
        if (!deletedNotificationsMap.containsKey(assetId)) {
          deletedNotificationsMap[assetId] = [];
        }
        deletedNotificationsMap[assetId]!.add(data);
      }

      // Fetch all existing notifications in one go
      QuerySnapshot existingNotificationsSnapshot = await FirebaseFirestore
          .instance
          .collection('notifications')
          .where('type', isEqualTo: 'maintenance_alert')
          .get();
      Map<String, List<Map<String, dynamic>>> existingNotificationsMap = {};
      for (var doc in existingNotificationsSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String assetId = data['assetId']?.toString() ?? '';
        if (!existingNotificationsMap.containsKey(assetId)) {
          existingNotificationsMap[assetId] = [];
        }
        existingNotificationsMap[assetId]!.add(data);
      }

      // Process assets in parallel
      List<Future<void>> notificationFutures = [];
      for (var assetDoc in assetsSnapshot.docs) {
        Map<String, dynamic> assetData = assetDoc.data() as Map<String, dynamic>;
        String assetId = assetData['assetId']?.toString() ?? assetDoc.id;
        String assetName = assetData['assetName']?.toString() ?? 'Unknown Asset';
        Timestamp? maintenanceTimestamp =
            assetData['maintenance_date'] as Timestamp?;

        if (maintenanceTimestamp == null) {
          continue;
        }

        DateTime maintenanceDate = maintenanceTimestamp.toDate();
        DateTime now = DateTime.now();
        DateTime sevenDaysBefore =
            maintenanceDate.subtract(const Duration(days: 7));

        if (now.isAfter(sevenDaysBefore) && now.isBefore(maintenanceDate)) {

          // Check deleted notifications in memory
          bool isDeleted = false;
          if (deletedNotificationsMap.containsKey(assetId)) {
            for (var deleted in deletedNotificationsMap[assetId]!) {
              Timestamp? deletedMaintenanceDate =
                  deleted['maintenance_date'] as Timestamp?;
              if (deletedMaintenanceDate != null &&
                  deletedMaintenanceDate == maintenanceTimestamp) {
                isDeleted = true;
                break;
              }
            }
          }

          if (isDeleted) {
            continue;
          }

          // Check existing notifications in memory
          bool notificationExists = false;
          if (existingNotificationsMap.containsKey(assetId)) {
            for (var existing in existingNotificationsMap[assetId]!) {
              Timestamp? existingMaintenanceDate =
                  existing['maintenance_date'] as Timestamp?;
              if (existingMaintenanceDate != null &&
                  existingMaintenanceDate == maintenanceTimestamp) {
                notificationExists = true;
                break;
              }
            }
          }

          if (notificationExists) {
            continue;
          }

          // Create new notification
          notificationFutures.add(
            FirebaseFirestore.instance.collection('notifications').add({
              'notification_id': '',
              'assetId': assetId,
              'assetName': assetName,
              'message':
                  'Maintenance for $assetName is due on ${DateFormat('MM/dd/yyyy').format(maintenanceDate)}',
              'maintenance_date': maintenanceTimestamp,
              'created_at': FieldValue.serverTimestamp(),
              'created_by': 'system',
              'type': 'maintenance_alert',
            }).then((docRef) async {
              await docRef.update({'notification_id': docRef.id});

              // Schedule or show a local notification
              final notificationDate =
                  maintenanceDate.subtract(const Duration(days: 7));
              if (notificationDate.isAfter(now)) {
                await NotificationService().scheduleNotification(
                  'Upcoming Maintenance for $assetName',
                  'Maintenance for $assetName is due on ${DateFormat('MM/dd/yyyy').format(maintenanceDate)}',
                  notificationDate,
                );
              } else if (maintenanceDate.isAfter(now)) {
                await NotificationService().showNotification(
                  'Upcoming Maintenance for $assetName',
                  'Maintenance for $assetName is due on ${DateFormat('MM/dd/yyyy').format(maintenanceDate)}',
                );
              }
            }),
          );
        } else {
        }
      }

      // Wait for all notifications to be created
      await Future.wait(notificationFutures);
    } catch (e) {
      if (!mounted) return;
      _showMessageDialog(context,
          title: 'Error',
          message: 'Failed to generate maintenance alerts: $e',
          isSuccess: false);
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingAlerts = false;
        });
      }
    }
  }

  Future<void> _createNotification() async {
    if (!widget.isAdmin) {
      _showMessageDialog(context,
          title: 'Permission Denied',
          message: 'Only admins can create notifications.',
          isSuccess: false);
      return;
    }

    final title = _titleController.text.trim();
    final details = _detailsController.text.trim();

    if (title.isEmpty || details.isEmpty) {
      _showMessageDialog(context,
          title: 'Validation Error',
          message: 'Please fill in all fields.',
          isSuccess: false);
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      DocumentReference docRef =
          await FirebaseFirestore.instance.collection('notifications').add({
        'notification_id': '',
        'title': title,
        'details': details,
        'created_at': FieldValue.serverTimestamp(),
        'created_by': 'manual',
        'type': 'user_message',
      });

      await docRef.update({'notification_id': docRef.id});

      if (!mounted) return;
      _showMessageDialog(context,
          title: 'Success',
          message: 'Notification created successfully!',
          isSuccess: true);

      _titleController.clear();
      _detailsController.clear();
    } catch (e) {
      if (!mounted) return;
      _showMessageDialog(context,
          title: 'Error',
          message: 'Error creating notification: $e',
          isSuccess: false);
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      String userId = widget.userId;

      DocumentSnapshot notificationDoc = await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .get();

      if (!notificationDoc.exists) {
        if (!mounted) return;
        _showMessageDialog(context,
            title: 'Error', message: 'Notification not found.', isSuccess: false);
        return;
      }

      Map<String, dynamic>? notificationData =
          notificationDoc.data() as Map<String, dynamic>?;

      if (notificationData == null) {
        if (!mounted) return;
        _showMessageDialog(context,
            title: 'Error',
            message: 'Notification data is empty.',
            isSuccess: false);
        return;
      }

      String? type = notificationData['type'] as String? ?? 'unknown';

      String? assetId =
          (notificationData['assetId'] ?? notificationData['assetID'])
              ?.toString();
      Timestamp? maintenanceDate =
          notificationData['maintenance_date'] as Timestamp?;

      QuerySnapshot existingUserDeleted = await FirebaseFirestore.instance
          .collection('deleted_notifications_by_user')
          .where('userId', isEqualTo: userId)
          .where('notificationId', isEqualTo: notificationId)
          .get();

      if (existingUserDeleted.docs.isEmpty) {
        await FirebaseFirestore.instance
            .collection('deleted_notifications_by_user')
            .add({
          'userId': userId,
          'notificationId': notificationId,
          'deletedAt': FieldValue.serverTimestamp(),
        });
      } else {
      }

      if (type == 'maintenance_alert' && assetId != null && maintenanceDate != null) {
        QuerySnapshot existingDeleted = await FirebaseFirestore.instance
            .collection('deleted_notifications')
            .where('assetId', isEqualTo: assetId)
            .where('maintenance_date', isEqualTo: maintenanceDate)
            .get();

        if (existingDeleted.docs.isEmpty) {
          await FirebaseFirestore.instance
              .collection('deleted_notifications')
              .add({
            'assetId': assetId,
            'maintenance_date': maintenanceDate,
            'deleted_at': FieldValue.serverTimestamp(),
          });
        } else {
        }
      }

      // Update local state to reflect the deletion immediately
      setState(() {
        _deletedNotificationIds.add(notificationId);
      });

      if (!mounted) return;
      _showMessageDialog(context,
          title: 'Success',
          message: 'Notification deleted successfully!',
          isSuccess: true);
    } catch (e) {
      if (!mounted) return;
      _showMessageDialog(context,
          title: 'Error',
          message: 'Error deleting notification: $e',
          isSuccess: false);
    }
  }

  void _showDeleteConfirmationDialog(BuildContext context, String notificationId) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      pageBuilder: (context, animation, secondaryAnimation) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: Curves.elasticOut,
          ),
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5B7A6D).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(3, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFDAB894), Color(0xFF5B7A6D)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(15),
                          topRight: Radius.circular(15)),
                    ),
                    child: const Text(
                      'Delete Notification',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'NotoSansJP'),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Are you sure you want to delete this notification?',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3A4F41),
                        fontFamily: 'NotoSansJP'),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF5F5F5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: const BorderSide(
                                color: Color(0xFF5B7A6D), width: 2),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          child: Text(
                            'NO',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3A4F41),
                                fontFamily: 'NotoSansJP'),
                          ),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5B7A6D),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _deleteNotification(notificationId);
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          child: Text(
                            'YES',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'NotoSansJP'),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showMessageDialog(BuildContext context,
      {required String title, required bool isSuccess, required String message}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      pageBuilder: (context, animation, secondaryAnimation) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: Curves.elasticOut,
          ),
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5B7A6D).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(3, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFDAB894), Color(0xFF5B7A6D)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(15),
                          topRight: Radius.circular(15)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isSuccess ? Icons.check_circle : Icons.error,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          title,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'NotoSansJP'),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      message,
                      style: TextStyle(
                        fontSize: 16,
                        color: isSuccess ? Colors.lightGreen : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'NotoSansJP',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5B7A6D),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Text(
                        'Close',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'NotoSansJP'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String userId = widget.userId;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'NOTIFICATIONS',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF3A4F41),
              fontFamily: 'NotoSansJP'),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF3A4F41)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 20, horizontal: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFDAB894), Color(0xFF5B7A6D)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF5B7A6D).withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.notifications,
                            color: Colors.white,
                            size: 30,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Notifications',
                              style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontFamily: 'NotoSansJP'),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (widget.isAdmin)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF5B7A6D).withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.add_circle,
                                    color: Color(0xFF3A4F41), size: 24),
                                SizedBox(width: 8),
                                Text(
                                  'Create New Notification',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF3A4F41),
                                      fontFamily: 'NotoSansJP'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _titleController,
                              decoration: const InputDecoration(
                                labelText: 'Title',
                                labelStyle: TextStyle(
                                    color: Color(0xFF3A4F41),
                                    fontFamily: 'NotoSansJP'),
                                filled: true,
                                fillColor: Color(0xFFE0E0E0),
                                border: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Color(0xFF5B7A6D), width: 1.5)),
                                enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Color(0xFF5B7A6D), width: 1.5)),
                                focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Color(0xFF3A4F41), width: 2)),
                                prefixIcon: Icon(Icons.title,
                                    color: Color(0xFF3A4F41)),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 10),
                              ),
                              maxLines: 1,
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _detailsController,
                              decoration: const InputDecoration(
                                labelText: 'Details',
                                labelStyle: TextStyle(
                                    color: Color(0xFF3A4F41),
                                    fontFamily: 'NotoSansJP'),
                                filled: true,
                                fillColor: Color(0xFFE0E0E0),
                                border: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Color(0xFF5B7A6D), width: 1.5)),
                                enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Color(0xFF5B7A6D), width: 1.5)),
                                focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Color(0xFF3A4F41), width: 2)),
                                prefixIcon: Icon(Icons.message,
                                    color: Color(0xFF3A4F41)),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 10),
                              ),
                              maxLines: 3,
                            ),
                            const SizedBox(height: 20),
                            Center(
                              child: _isCreating
                                  ? const CircularProgressIndicator(
                                      color: Color(0xFF5B7A6D))
                                  : AnimatedBuilder(
                                      animation: _animationController,
                                      builder: (context, child) {
                                        return Transform.scale(
                                          scale: _scaleAnimation.value,
                                          child: ElevatedButton.icon(
                                            onPressed: () {
                                              _animationController
                                                  .reverse()
                                                  .then((_) {
                                                _animationController.forward();
                                                _createNotification();
                                              });
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  const Color(0xFF5B7A6D),
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 40, vertical: 15),
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12)),
                                              elevation: 5,
                                            ),
                                            icon: const Icon(
                                                Icons.notification_add,
                                                color: Colors.white),
                                            label: const Text(
                                              'Create Notification',
                                              style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                  fontFamily: 'NotoSansJP'),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF5B7A6D).withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: const [
                                  Icon(
                                    Icons.notifications,
                                    color: Color(0xFF3A4F41),
                                    size: 24,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Notifications List',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Color(0xFF3A4F41),
                                        fontFamily: 'NotoSansJP'),
                                  ),
                                ],
                              ),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 150),
                                child: DropdownButtonFormField<String>(
                                  value: _selectedFilter,
                                  items: ['All', 'User Message', 'Maintenance Alert']
                                      .map((option) {
                                    return DropdownMenuItem(
                                      value: option,
                                      child: Text(
                                        option,
                                        style: const TextStyle(
                                            color: Color(0xFF3A4F41),
                                            fontFamily: 'NotoSansJP'),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedFilter = value!;
                                    });
                                  },
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: Color(0xFF5B7A6D), width: 1.5)),
                                    enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: Color(0xFF5B7A6D), width: 1.5)),
                                    focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: Color(0xFF3A4F41), width: 2)),
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 0),
                                  ),
                                  dropdownColor: const Color(0xFFF5F5F5),
                                  isExpanded: true,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.5,
                            child: FutureBuilder<List<String>>(
                              future: FirebaseFirestore.instance
                                  .collection('deleted_notifications_by_user')
                                  .where('userId', isEqualTo: userId)
                                  .get()
                                  .then((snapshot) => snapshot.docs
                                      .map((doc) => doc['notificationId'] as String)
                                      .toList()),
                              builder: (context, deletedSnapshot) {
                                if (deletedSnapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                      child: CircularProgressIndicator(
                                          color: Color(0xFF5B7A6D)));
                                }
                                if (deletedSnapshot.hasError) {
                                  return Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.error,
                                            color: Colors.red, size: 50),
                                        const SizedBox(height: 10),
                                        Text(
                                          'Failed to load deleted notifications: ${deletedSnapshot.error}',
                                          style: const TextStyle(
                                              color: Colors.red,
                                              fontFamily: 'NotoSansJP'),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                // Merge initial deleted IDs with local state
                                final initialDeletedNotificationIds =
                                    deletedSnapshot.data ?? [];
                                final allDeletedNotificationIds = {
                                  ...initialDeletedNotificationIds,
                                  ..._deletedNotificationIds
                                };

                                return StreamBuilder<QuerySnapshot>(
                                  stream: widget.isAdmin || _userCreatedAt == null
                                      ? FirebaseFirestore.instance
                                          .collection('notifications')
                                          .orderBy('created_at', descending: true)
                                          .limit(20)
                                          .snapshots()
                                      : FirebaseFirestore.instance
                                          .collection('notifications')
                                          .where('created_at',
                                              isGreaterThanOrEqualTo:
                                                  Timestamp.fromDate(_userCreatedAt!))
                                          .orderBy('created_at', descending: true)
                                          .limit(20)
                                          .snapshots(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Center(
                                          child: CircularProgressIndicator(
                                              color: Color(0xFF5B7A6D)));
                                    }
                                    if (snapshot.hasError) {
                                      return Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.error,
                                                color: Colors.red, size: 50),
                                            const SizedBox(height: 10),
                                            Text(
                                              'Failed to load notifications: ${snapshot.error}',
                                              style: const TextStyle(
                                                  color: Colors.red,
                                                  fontFamily: 'NotoSansJP'),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                    if (!snapshot.hasData ||
                                        snapshot.data!.docs.isEmpty) {
                                      return const Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.notifications_off,
                                                color: Colors.grey, size: 50),
                                            SizedBox(height: 10),
                                            Text(
                                              'No notifications available.',
                                              style: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 16,
                                                  fontFamily: 'NotoSansJP'),
                                            ),
                                          ],
                                        ),
                                      );
                                    }

                                    final notifications = snapshot.data!.docs
                                        .where((doc) => !allDeletedNotificationIds
                                            .contains(doc['notification_id'] as String))
                                        .toList();

                                    // Filter notifications based on selected type
                                    final filteredNotifications = notifications.where((doc) {
                                      final notification =
                                          doc.data() as Map<String, dynamic>;
                                      final type =
                                          notification['type']?.toString() ?? 'unknown';
                                      if (_selectedFilter == 'All') return true;
                                      if (_selectedFilter == 'User Message' &&
                                          type == 'user_message') {
                                        return true;
                                      }
                                      if (_selectedFilter == 'Maintenance Alert' &&
                                          type == 'maintenance_alert') {
                                        return true;
                                      }
                                      return false;
                                    }).toList();

                                    if (filteredNotifications.isEmpty) {
                                      return const Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.notifications_off,
                                                color: Colors.grey, size: 50),
                                            SizedBox(height: 10),
                                            Text(
                                              'No notifications available.',
                                              style: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 16,
                                                  fontFamily: 'NotoSansJP'),
                                            ),
                                          ],
                                        ),
                                      );
                                    }

                                    return ListView.builder(
                                      itemCount: filteredNotifications.length,
                                      itemBuilder: (context, index) {
                                        final notification = filteredNotifications[index]
                                            .data() as Map<String, dynamic>;
                                        final notificationId =
                                            notification['notification_id']
                                                    ?.toString() ??
                                                '';
                                        final createdAt =
                                            notification['created_at'] != null
                                                ? (notification['created_at']
                                                        as Timestamp)
                                                    .toDate()
                                                : null;
                                        final maintenanceDate =
                                            notification['maintenance_date'] != null
                                                ? (notification['maintenance_date']
                                                        as Timestamp)
                                                    .toDate()
                                                : null;
                                        final type = notification['type']?.toString() ??
                                            'unknown';

                                        Widget notificationCard = Card(
                                          elevation: 3,
                                          margin:
                                              const EdgeInsets.symmetric(vertical: 6),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12)),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                  colors: [
                                                    Colors.grey[50]!,
                                                    Colors.grey[100]!
                                                  ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: ListTile(
                                              leading: const Icon(
                                                  Icons.notifications,
                                                  color: Color(0xFF3A4F41)),
                                              title: Text(
                                                type == 'user_message'
                                                    ? (notification['title']
                                                            ?.toString() ??
                                                        'No title')
                                                    : (notification['message']
                                                            ?.toString() ??
                                                        'No message'),
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF3A4F41),
                                                    fontSize: 14,
                                                    fontFamily: 'NotoSansJP'),
                                              ),
                                              subtitle: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  if (type == 'user_message')
                                                    Text(
                                                      'Details: ${notification['details']?.toString() ?? '-'}',
                                                      style: const TextStyle(
                                                          fontSize: 14,
                                                          color: Color(0xFF3A4F41),
                                                          fontFamily: 'NotoSansJP'),
                                                    ),
                                                  if (type == 'maintenance_alert')
                                                    Text(
                                                      'Maintenance Date: ${maintenanceDate != null ? DateFormat('MM/dd/yyyy').format(maintenanceDate) : '-'}',
                                                      style: const TextStyle(
                                                          fontSize: 14,
                                                          color: Color(0xFF3A4F41),
                                                          fontFamily: 'NotoSansJP'),
                                                    ),
                                                  Text(
                                                    'Created At: ${createdAt != null ? DateFormat('MM/dd/yyyy HH:mm').format(createdAt) : '-'}',
                                                    style: const TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey,
                                                        fontFamily: 'NotoSansJP'),
                                                  ),
                                                  Text(
                                                    'Source: ${type == 'maintenance_alert' ? 'System Alert' : 'Manual'}',
                                                    style: const TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.blue,
                                                        fontFamily: 'NotoSansJP'),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );

                                        return Dismissible(
                                          key: Key(notificationId),
                                          direction: DismissDirection.endToStart,
                                          background: Container(
                                            color: Colors.red,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 20),
                                            alignment: Alignment.centerRight,
                                            child: const Icon(Icons.delete,
                                                color: Colors.white),
                                          ),
                                          confirmDismiss: (direction) async {
                                            _showDeleteConfirmationDialog(
                                                context, notificationId);
                                            return false; // Prevent automatic dismissal
                                          },
                                          child: notificationCard,
                                        );
                                      },
                                    );
                                  },
                                );
                              },
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
          if (_isGeneratingAlerts)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF5B7A6D)),
            ),
        ],
      ),
    );
  }
}
