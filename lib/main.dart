import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/control_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/history_provider.dart';
import 'screens/login_screen.dart';
import 'screens/history_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ControlProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
      ],
      child: const SmartVoltApp(),
    ),
  );
}

class SmartVoltApp extends StatelessWidget {
  const SmartVoltApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Smart Volt Campus',
          themeMode: themeProvider.themeMode,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          home: Consumer<AuthProvider>(
            builder: (context, auth, _) {
              if (!auth.isInitialized) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
              return auth.isLoggedIn ? const MainNavigationWrapper() : const LoginScreen();
            },
          ),
        );
      },
    );
  }
}

class MainNavigationWrapper extends StatefulWidget {
  const MainNavigationWrapper({super.key});

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const HistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Volt Campus'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(theme.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => theme.toggleTheme(!theme.isDarkMode),
            tooltip: 'Toggle Dark/Light Mode',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettingsMenu(context),
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
        ],
      ),
    );
  }

  void _showSettingsMenu(BuildContext context) {
    final controlProvider = Provider.of<ControlProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            SwitchListTile(
              secondary: Icon(themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode),
              title: const Text('Dark Mode'),
              value: themeProvider.isDarkMode,
              onChanged: (val) {
                themeProvider.toggleTheme(val);
                Navigator.pop(context);
              },
            ),
            SwitchListTile(
              secondary: const Icon(Icons.cloud),
              title: const Text('Cloud Mode (ThingSpeak)'),
              value: controlProvider.isCloudMode,
              onChanged: (val) {
                controlProvider.toggleCloudMode(val);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_ethernet),
              title: const Text('Local IP Configuration'),
              subtitle: Text(controlProvider.currentIp),
              onTap: () {
                Navigator.pop(context);
                _showIpDialog(context, controlProvider);
              },
            ),
            ListTile(
              leading: const Icon(Icons.api),
              title: const Text('ThingSpeak Settings'),
              subtitle: Text(controlProvider.channelId.isEmpty ? "Not Configured" : "ID: ${controlProvider.channelId}"),
              onTap: () {
                Navigator.pop(context);
                _showThingSpeakDialog(context, controlProvider);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              subtitle: Text('Logged in as ${authProvider.role == UserRole.teacher ? "Teacher" : "Other"}'),
              onTap: () {
                authProvider.logout();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showIpDialog(BuildContext context, ControlProvider provider) {
    final controller = TextEditingController(text: provider.currentIp);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Local Network Configuration'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'ESP32 IP Address'),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              provider.updateIp(controller.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showThingSpeakDialog(BuildContext context, ControlProvider provider) {
    final channelController = TextEditingController(text: provider.channelId);
    final readKeyController = TextEditingController(text: provider.readKey);
    final writeKeyController = TextEditingController(text: provider.writeKey);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ThingSpeak Configuration'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: channelController,
                decoration: const InputDecoration(labelText: 'Channel ID'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: readKeyController,
                decoration: const InputDecoration(labelText: 'Read API Key'),
              ),
              TextField(
                controller: writeKeyController,
                decoration: const InputDecoration(labelText: 'Write API Key'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              provider.updateThingSpeakSettings(
                channelId: channelController.text,
                readKey: readKeyController.text,
                writeKey: writeKeyController.text,
              );
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ControlProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final data = provider.data;
    final isTeacher = auth.role == UserRole.teacher;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Connection Status
          _buildStatusHeader(provider.isConnected, provider.isCloudMode),
          const SizedBox(height: 20),

          // Sensor Data Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _SensorCard(
                title: 'Temperature',
                value: '${data.temperature}°C',
                icon: Icons.thermostat,
                color: Colors.orange,
              ),
              _SensorCard(
                title: 'Humidity',
                value: '${data.humidity}%',
                icon: Icons.water_drop,
                color: Colors.cyan,
              ),
              _SensorCard(
                title: 'Motion',
                value: data.motionDetected ? 'DETECTED' : 'None',
                icon: Icons.person_search,
                color: data.motionDetected ? Colors.red : Colors.green,
              ),
              _SensorCard(
                title: 'Smoke',
                value: data.smokeDetected ? 'WARNING' : 'Clear',
                icon: Icons.smoke_free,
                color: data.smokeDetected ? Colors.red : Colors.blue,
              ),
            ],
          ),

          const SizedBox(height: 30),

          // Mode Selection Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    'CLASSROOM CONTROL',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Mode:', style: TextStyle(fontSize: 16)),
                      ActionChip(
                        label: Text(
                          data.mode.toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: data.mode == 'auto' ? Colors.green : Colors.orange,
                        onPressed: isTeacher ? () => provider.toggleMode() : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (!isTeacher)
                    const Text(
                      'View-only mode enabled for your account.',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  Text(
                    data.mode == 'auto'
                        ? 'System is making automatic decisions.'
                        : 'Manual Control is active.',
                    style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Manual Controls
          _buildManualControls(provider, data, isTeacher),
        ],
      ),
    );
  }

  Widget _buildStatusHeader(bool connected, bool isCloud) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: connected ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isCloud ? Icons.cloud : (connected ? Icons.wifi : Icons.wifi_off),
            color: connected ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 10),
          Text(
            isCloud 
              ? (connected ? 'Cloud Connected' : 'Cloud Error')
              : (connected ? 'Local Connected' : 'Searching...'),
            style: TextStyle(color: connected ? Colors.green[800] : Colors.red[800]),
          ),
        ],
      ),
    );
  }

  Widget _buildManualControls(ControlProvider provider, dynamic data, bool isTeacher) {
    final bool isManual = data.mode == 'manual';
    // Only teachers can actually interact if it's manual
    final bool canInteract = isTeacher && isManual;

    return Column(
      children: [
        _ControlRow(
          label: 'Light',
          isOn: data.lightState,
          isEnabled: canInteract,
          onToggle: (val) => provider.controlDevice('light', val),
        ),
      ],
    );
  }
}

class _SensorCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SensorCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: color),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
            Text(
              value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlRow extends StatelessWidget {
  final String label;
  final bool isOn;
  final bool isEnabled;
  final Function(bool) onToggle;

  const _ControlRow({
    required this.label,
    required this.isOn,
    required this.isEnabled,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isEnabled ? null : Colors.grey[200],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb,
                  color: isEnabled ? (isOn ? Colors.yellow[800] : Colors.grey) : Colors.grey[400],
                ),
                const SizedBox(width: 15),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: isEnabled ? Colors.black : Colors.grey[500],
                  ),
                ),
              ],
            ),
            Switch(
              value: isOn,
              onChanged: isEnabled ? onToggle : null,
              activeThumbColor: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }
}
