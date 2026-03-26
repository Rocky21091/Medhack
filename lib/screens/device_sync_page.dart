import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:health/health.dart';
import '../theme/app_theme.dart';

class DeviceSyncPage extends StatefulWidget {
  const DeviceSyncPage({super.key});

  @override
  State<DeviceSyncPage> createState() => _DeviceSyncPageState();
}

class _DeviceSyncPageState extends State<DeviceSyncPage>
    with SingleTickerProviderStateMixin {
  // BLE Scanning
  bool _isScanning = false;
  List<ScanResult> _scanResults = [];
  late StreamSubscription<List<ScanResult>> _scanResultsSubscription;
  late StreamSubscription<bool> _isScanningSubscription;

  // Device Connection
  BluetoothDevice? _connectedDevice;
  bool _isConnecting = false;
  String _connectionType = "none"; // ble, health_app, mock

  // Health App Integration
  bool _healthAppConnected = false;

  // Vitals Data
  String _currentHeartRate = "--";
  String _currentSpO2 = "--";
  String _currentBloodPressure = "--/--";
  String _currentTemperature = "--";
  String _currentSteps = "--";
  String _currentSleepHours = "--";
  String _currentCalories = "--";
  String _currentRespiratoryRate = "--";

  // Real-time data subscription
  Timer? _healthDataTimer;
  Health? _health;

  // Animation
  late AnimationController _pulseAnimation;
  late Animation<double> _pulseScale;

  @override
  void initState() {
    super.initState();

    // Setup BLE listeners
    _isScanningSubscription = FlutterBluePlus.isScanning.listen((state) {
      if (mounted) setState(() => _isScanning = state);
    });

    _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
      if (mounted) setState(() => _scanResults = results);
    });

    // Animation for pulse effect
    _pulseAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseScale = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseAnimation, curve: Curves.easeInOut),
    );

    // Initialize Health
    _health = Health();
    _checkHealthAppAvailability();
  }

  Future<void> _checkHealthAppAvailability() async {
    try {
      // Check if health data is available by requesting permissions
      final types = [HealthDataType.STEPS, HealthDataType.HEART_RATE];

      // Request permissions to check availability
      final requested = await _health!.requestAuthorization(types);
      if (requested) {
        await _requestHealthPermissions();
      }
    } catch (e) {
      print("Health app not available: $e");
    }
  }

  Future<void> _requestHealthPermissions() async {
    try {
      // Request permissions for all health data types
      final types = [
        HealthDataType.STEPS,
        HealthDataType.HEART_RATE,
        HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
        HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
        HealthDataType.BODY_TEMPERATURE,
        HealthDataType.ACTIVE_ENERGY_BURNED,
        HealthDataType.RESPIRATORY_RATE,
      ];

      final requested = await _health!.requestAuthorization(types);
      if (requested) {
        setState(() {
          _healthAppConnected = true;
          _connectionType = "health_app";
        });
        _startHealthDataCollection();
      }
    } catch (e) {
      print("Health permissions error: $e");
    }
  }

  void _startHealthDataCollection() {
    // Collect health data every 10 seconds
    _healthDataTimer?.cancel();
    _healthDataTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _fetchLatestHealthData();
    });
    _fetchLatestHealthData(); // Fetch immediately
  }

  Future<void> _fetchLatestHealthData() async {
    final now = DateTime.now();
    final startTime = now.subtract(const Duration(hours: 24));

    try {
      // Fetch Heart Rate
      final heartRateData = await _health!.getHealthDataFromTypes(
        startTime: startTime,
        endTime: now,
        types: [HealthDataType.HEART_RATE],
      );
      if (heartRateData.isNotEmpty) {
        final latest = heartRateData.last;
        if (latest.value is double) {
          setState(() {
            _currentHeartRate = (latest.value as double).toInt().toString();
          });
        } else if (latest.value is int) {
          setState(() {
            _currentHeartRate = (latest.value as int).toString();
          });
        }
      }

      // Fetch Blood Pressure
      final systolicData = await _health!.getHealthDataFromTypes(
        startTime: startTime,
        endTime: now,
        types: [HealthDataType.BLOOD_PRESSURE_SYSTOLIC],
      );
      final diastolicData = await _health!.getHealthDataFromTypes(
        startTime: startTime,
        endTime: now,
        types: [HealthDataType.BLOOD_PRESSURE_DIASTOLIC],
      );

      if (systolicData.isNotEmpty && diastolicData.isNotEmpty) {
        int systolic = 0;
        int diastolic = 0;

        if (systolicData.last.value is double) {
          systolic = (systolicData.last.value as double).toInt();
        } else if (systolicData.last.value is int) {
          systolic = systolicData.last.value as int;
        }

        if (diastolicData.last.value is double) {
          diastolic = (diastolicData.last.value as double).toInt();
        } else if (diastolicData.last.value is int) {
          diastolic = diastolicData.last.value as int;
        }

        setState(() {
          _currentBloodPressure = "$systolic/$diastolic";
        });
      }

      // Fetch Temperature
      final tempData = await _health!.getHealthDataFromTypes(
        startTime: startTime,
        endTime: now,
        types: [HealthDataType.BODY_TEMPERATURE],
      );
      if (tempData.isNotEmpty) {
        final latest = tempData.last;
        if (latest.value is double) {
          setState(() {
            _currentTemperature = (latest.value as double).toStringAsFixed(1);
          });
        } else if (latest.value is int) {
          setState(() {
            _currentTemperature = (latest.value as int).toString();
          });
        }
      }

      // Fetch Steps
      final stepsData = await _health!.getHealthDataFromTypes(
        startTime: startTime,
        endTime: now,
        types: [HealthDataType.STEPS],
      );
      if (stepsData.isNotEmpty) {
        int totalSteps = 0;
        for (var point in stepsData) {
          if (point.value is double) {
            totalSteps += (point.value as double).toInt();
          } else if (point.value is int) {
            totalSteps += point.value as int;
          }
        }
        setState(() {
          _currentSteps = totalSteps.toString();
        });
      }

      // Fetch Calories
      final caloriesData = await _health!.getHealthDataFromTypes(
        startTime: startTime,
        endTime: now,
        types: [HealthDataType.ACTIVE_ENERGY_BURNED],
      );
      if (caloriesData.isNotEmpty) {
        int totalCalories = 0;
        for (var point in caloriesData) {
          if (point.value is double) {
            totalCalories += (point.value as double).toInt();
          } else if (point.value is int) {
            totalCalories += point.value as int;
          }
        }
        setState(() {
          _currentCalories = totalCalories.toString();
        });
      }

      // Fetch Respiratory Rate
      final respData = await _health!.getHealthDataFromTypes(
        startTime: startTime,
        endTime: now,
        types: [HealthDataType.RESPIRATORY_RATE],
      );
      if (respData.isNotEmpty) {
        final latest = respData.last;
        if (latest.value is double) {
          setState(() {
            _currentRespiratoryRate = (latest.value as double)
                .toInt()
                .toString();
          });
        } else if (latest.value is int) {
          setState(() {
            _currentRespiratoryRate = (latest.value as int).toString();
          });
        }
      }

      // Save to Firebase
      _saveVitalsToFirebase();
    } catch (e) {
      print("Error fetching health data: $e");
    }
  }

  Future<void> _saveVitalsToFirebase() async {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      // Save current vitals to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('vitals_history')
          .add({
            'heartRate': _currentHeartRate,
            'spO2': _currentSpO2,
            'bloodPressure': _currentBloodPressure,
            'temperature': _currentTemperature,
            'steps': _currentSteps,
            'sleepHours': _currentSleepHours,
            'calories': _currentCalories,
            'respiratoryRate': _currentRespiratoryRate,
            'connectionType': _connectionType,
            'timestamp': FieldValue.serverTimestamp(),
          });

      // Also update the latest vitals in user document
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'latestVitals': {
          'heartRate': _currentHeartRate,
          'spO2': _currentSpO2,
          'bloodPressure': _currentBloodPressure,
          'temperature': _currentTemperature,
          'steps': _currentSteps,
          'sleepHours': _currentSleepHours,
          'calories': _currentCalories,
          'respiratoryRate': _currentRespiratoryRate,
          'lastUpdated': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));
    } catch (e) {
      print("Error saving vitals to Firebase: $e");
    }
  }

  // BLE Methods
  Future<void> _startScan() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    if (statuses[Permission.bluetoothScan]?.isDenied == true ||
        statuses[Permission.location]?.isDenied == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bluetooth & Location permissions required.'),
        ),
      );
      return;
    }

    try {
      setState(() => _scanResults.clear());
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error starting scan: $e')));
    }
  }

  void _stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    _stopScan();
    setState(() => _isConnecting = true);

    try {
      await device.connect(autoConnect: false, license: License.free);
      setState(() {
        _connectedDevice = device;
        _isConnecting = false;
        _connectionType = "ble";
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connected to ${device.platformName}')),
      );

      _discoverServices(device);
    } catch (e) {
      setState(() => _isConnecting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to connect: $e')));
    }
  }

  Future<void> _discoverServices(BluetoothDevice device) async {
    List<BluetoothService> services = await device.discoverServices();

    for (BluetoothService service in services) {
      // Heart Rate Service
      if (service.uuid.toString().toUpperCase().contains("180D")) {
        for (BluetoothCharacteristic characteristic
            in service.characteristics) {
          if (characteristic.properties.notify) {
            await characteristic.setNotifyValue(true);
            characteristic.onValueReceived.listen((value) {
              if (value.isNotEmpty) {
                int hrValue = value[1];
                setState(() {
                  _currentHeartRate = hrValue.toString();
                });
                _saveVitalsToFirebase();
              }
            });
          }
        }
      }

      // Blood Pressure Service
      if (service.uuid.toString().toUpperCase().contains("1810")) {
        for (BluetoothCharacteristic characteristic
            in service.characteristics) {
          if (characteristic.properties.notify) {
            await characteristic.setNotifyValue(true);
            characteristic.onValueReceived.listen((value) {
              if (value.length >= 4) {
                int systolic = value[2];
                int diastolic = value[3];
                setState(() {
                  _currentBloodPressure = "$systolic/$diastolic";
                });
                _saveVitalsToFirebase();
              }
            });
          }
        }
      }

      // Temperature Service
      if (service.uuid.toString().toUpperCase().contains("181A")) {
        for (BluetoothCharacteristic characteristic
            in service.characteristics) {
          if (characteristic.properties.notify) {
            await characteristic.setNotifyValue(true);
            characteristic.onValueReceived.listen((value) {
              if (value.isNotEmpty) {
                double temp = (value[0] + (value[1] << 8)) / 100.0;
                setState(() {
                  _currentTemperature = temp.toStringAsFixed(1);
                });
                _saveVitalsToFirebase();
              }
            });
          }
        }
      }
    }
  }

  Future<void> _disconnectDevice() async {
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
      setState(() {
        _connectedDevice = null;
        _connectionType = _healthAppConnected ? "health_app" : "none";
      });
    }
  }

  void _disconnectHealthApp() {
    _healthDataTimer?.cancel();
    setState(() {
      _healthAppConnected = false;
      _connectionType = "none";
      _currentHeartRate = "--";
      _currentSpO2 = "--";
      _currentBloodPressure = "--/--";
      _currentTemperature = "--";
      _currentSteps = "--";
      _currentSleepHours = "--";
      _currentCalories = "--";
      _currentRespiratoryRate = "--";
    });
    _saveVitalsToFirebase();
  }

  void _useMockData() {
    setState(() {
      _connectionType = "mock";
      _healthDataTimer?.cancel();
    });
    _startMockDataSimulation();
  }

  void _startMockDataSimulation() {
    _healthDataTimer?.cancel();
    _healthDataTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      setState(() {
        _currentHeartRate = (65 + (DateTime.now().second % 20)).toString();
        _currentSpO2 = (95 + (DateTime.now().second % 5)).toString();
        _currentBloodPressure =
            "${110 + (DateTime.now().second % 10)}/${70 + (DateTime.now().second % 10)}";
        _currentTemperature = (36.5 + (DateTime.now().second % 10) / 10)
            .toStringAsFixed(1);
        _currentSteps = (5000 + (DateTime.now().second * 10)).toString();
        _currentCalories = (200 + (DateTime.now().second * 2)).toString();
        _currentRespiratoryRate = (12 + (DateTime.now().second % 8)).toString();
      });
      _saveVitalsToFirebase();
    });
  }

  @override
  void dispose() {
    _scanResultsSubscription.cancel();
    _isScanningSubscription.cancel();
    _healthDataTimer?.cancel();
    _pulseAnimation.dispose();
    if (_connectedDevice != null) {
      _connectedDevice!.disconnect();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Health Sync',
          style: TextStyle(
            color: AppTheme.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.primaryGreen),
        actions: [
          if (_connectionType != "none")
            IconButton(
              icon: const Icon(Icons.sync_rounded),
              onPressed: _saveVitalsToFirebase,
              tooltip: 'Sync to Cloud',
            ),
        ],
      ),
      body: Column(
        children: [
          // Connection Status
          Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _connectionType != "none"
                      ? AppTheme.primaryGreen
                      : Colors.grey.shade400,
                  _connectionType != "none"
                      ? AppTheme.primaryGreen.withOpacity(0.7)
                      : Colors.grey.shade500,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _connectionType != "none"
                          ? _pulseScale.value
                          : 1.0,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Icon(
                          _connectionType == "ble"
                              ? Icons.bluetooth_connected_rounded
                              : _connectionType == "health_app"
                              ? Icons.health_and_safety_rounded
                              : Icons.devices_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _connectionType == "ble"
                            ? "Connected to ${_connectedDevice?.platformName ?? 'Device'}"
                            : _connectionType == "health_app"
                            ? "Connected to Health App"
                            : _connectionType == "mock"
                            ? "Demo Mode Active"
                            : "No Device Connected",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _connectionType != "none"
                            ? "Live data streaming"
                            : "Connect a device to see vitals",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_connectionType != "none")
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      if (_connectionType == "ble") {
                        _disconnectDevice();
                      } else if (_connectionType == "health_app") {
                        _disconnectHealthApp();
                      } else {
                        setState(() {
                          _connectionType = "none";
                          _healthDataTimer?.cancel();
                        });
                      }
                    },
                  ),
              ],
            ),
          ),

          // Vitals Grid
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 8),

                  // Heart Rate & SpO2 Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildVitalCard(
                          title: "Heart Rate",
                          value: _currentHeartRate,
                          unit: "bpm",
                          icon: Icons.favorite,
                          color: Colors.redAccent,
                          trend: _getHeartRateTrend(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildVitalCard(
                          title: "SpO2",
                          value: _currentSpO2,
                          unit: "%",
                          icon: Icons.air,
                          color: Colors.blueAccent,
                          trend: _getSpO2Trend(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Blood Pressure & Temperature Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildVitalCard(
                          title: "Blood Pressure",
                          value: _currentBloodPressure,
                          unit: "mmHg",
                          icon: Icons.monitor_heart_rounded,
                          color: Colors.purpleAccent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildVitalCard(
                          title: "Temperature",
                          value: _currentTemperature,
                          unit: "°C",
                          icon: Icons.thermostat,
                          color: Colors.orangeAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Steps & Calories Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildVitalCard(
                          title: "Steps",
                          value: _currentSteps,
                          unit: "steps",
                          icon: Icons.directions_walk,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildVitalCard(
                          title: "Calories",
                          value: _currentCalories,
                          unit: "kcal",
                          icon: Icons.local_fire_department,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Sleep & Respiratory Rate Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildVitalCard(
                          title: "Sleep",
                          value: _currentSleepHours,
                          unit: "hours",
                          icon: Icons.nights_stay_rounded,
                          color: Colors.indigo,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildVitalCard(
                          title: "Respiratory Rate",
                          value: _currentRespiratoryRate,
                          unit: "br/min",
                          icon: Icons.air_rounded,
                          color: Colors.teal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Connection Options
                  if (_connectionType == "none")
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      child: Column(
                        children: [
                          const Text(
                            "Connect Your Health Devices",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildConnectionOption(
                                  icon: Icons.bluetooth_rounded,
                                  title: "BLE Devices",
                                  subtitle: "Smartwatch, BP Monitor",
                                  color: Colors.blue,
                                  onTap: _startScan,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildConnectionOption(
                                  icon: Icons.health_and_safety_rounded,
                                  title: "Health App",
                                  subtitle: "Apple Health, Google Fit",
                                  color: Colors.green,
                                  onTap: _requestHealthPermissions,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildConnectionOption(
                                  icon: Icons.science_rounded,
                                  title: "Demo Mode",
                                  subtitle: "Simulate data",
                                  color: Colors.orange,
                                  onTap: _useMockData,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                  // Device List (when scanning)
                  if (_isScanning && _connectionType == "none")
                    Column(
                      children: [
                        const SizedBox(height: 16),
                        const Text(
                          "Available Devices",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _scanResults.length,
                          itemBuilder: (context, index) {
                            final result = _scanResults[index];
                            final deviceName =
                                result.device.platformName.isNotEmpty
                                ? result.device.platformName
                                : "Unknown Device";

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.grey.shade200),
                              ),
                              child: ListTile(
                                leading: const Icon(
                                  Icons.bluetooth,
                                  color: AppTheme.primaryGreen,
                                ),
                                title: Text(deviceName),
                                subtitle: Text(
                                  result.device.remoteId.toString(),
                                ),
                                trailing: _isConnecting
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : ElevatedButton(
                                        onPressed: () =>
                                            _connectToDevice(result.device),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              AppTheme.primaryGreen,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                        child: const Text('Connect'),
                                      ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
    String? trend,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glossyCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: AppTheme.textGrey),
              ),
              if (trend != null && trend.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(
                    trend == "up" ? Icons.trending_up : Icons.trending_down,
                    size: 12,
                    color: trend == "up" ? Colors.green : Colors.red,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: const TextStyle(fontSize: 12, color: AppTheme.textGrey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.pureWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 10, color: AppTheme.textGrey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getHeartRateTrend() {
    if (_currentHeartRate == "--") return "";
    int hr = int.tryParse(_currentHeartRate) ?? 0;
    if (hr > 100) return "up";
    if (hr < 60) return "down";
    return "";
  }

  String _getSpO2Trend() {
    if (_currentSpO2 == "--") return "";
    int spo2 = int.tryParse(_currentSpO2) ?? 0;
    if (spo2 < 95) return "down";
    if (spo2 > 98) return "up";
    return "";
  }
}
