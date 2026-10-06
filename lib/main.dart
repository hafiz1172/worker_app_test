import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// APNA APPS SCRIPT WEB APP URL YAHAN PASTE KAREIN
const String scriptUrl = "https://script.google.com/macros/s/YOUR_SCRIPT_ID/exec";

void main() {
  runApp(const MaterialApp(
    home: AuthCheck(),
    debugShowCheckedModeBanner: false,
  ));
}

class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});
  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  @override
  void initState() {
    super.initState();
    _checkSavedPin();
  }

  void _checkSavedPin() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPin = prefs.getString('worker_pin');
    if (savedPin != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => DashboardScreen(pin: savedPin)),
      );
    } else if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _pinController = TextEditingController();
  bool _loading = false;

  void _login() async {
    final pin = _pinController.text.trim();
    if (pin.isEmpty) return;

    setState(() => _loading = true);
    try {
      final res = await http.post(
        Uri.parse(scriptUrl),
        body: jsonEncode({"action": "get_balance", "pin": pin}),
      );
      final data = jsonDecode(res.body);

      if (data["status"] == "success") {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('worker_pin', pin);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => DashboardScreen(pin: pin)),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data["message"] ?? "PIN ghalat hai")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Internet ya Server error")),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Worker Portal Login")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 70, color: Colors.blue),
            const SizedBox(height: 20),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Apna 4-Digit PIN Likhein",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            _loading
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _login,
                      child: const Text("Login Karein", style: TextStyle(fontSize: 18)),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  final String pin;
  const DashboardScreen({super.key, required this.pin});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _workerData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  void _fetchDetails() async {
    setState(() => _loading = true);
    try {
      final res = await http.post(
        Uri.parse(scriptUrl),
        body: jsonEncode({"action": "get_balance", "pin": widget.pin}),
      );
      final data = jsonDecode(res.body);
      if (data["status"] == "success" && mounted) {
        setState(() => _workerData = data);
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('worker_pin');
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_workerData != null ? _workerData!["worker"] : "Dashboard"),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchDetails),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _workerData == null
              ? const Center(child: Text("Data load nahi ho saka"))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Card(
                        elevation: 4,
                        color: Colors.blue.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              const Text("Remaining Balance", style: TextStyle(fontSize: 16)),
                              const SizedBox(height: 8),
                              Text(
                                "Rs. ${_workerData!["balance"]}",
                                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blue),
                              ),
                              const Divider(height: 30),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  Column(
                                    children: [
                                      const Text("Total Tiles"),
                                      Text("${_workerData!["totalTiles"]}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      const Text("Total Expense"),
                                      Text("Rs. ${_workerData!["totalExpense"]}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.red)),
                                    ],
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.add_circle_outline),
                          label: const Text("Aaj Ka Record Likhein", style: TextStyle(fontSize: 18)),
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddEntryScreen(workerName: _workerData!["worker"]),
                              ),
                            );
                            _fetchDetails();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class AddEntryScreen extends StatefulWidget {
  final String workerName;
  const AddEntryScreen({super.key, required this.workerName});

  @override
  State<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends State<AddEntryScreen> {
  final _tilesController = TextEditingController();
  final _expenseController = TextEditingController();
  final _notesController = TextEditingController();
  bool _submitting = false;

  void _submit() async {
    final tiles = _tilesController.text.trim();
    final expense = _expenseController.text.trim();
    if (tiles.isEmpty && expense.isEmpty) return;

    setState(() => _submitting = true);
    final now = DateTime.now();
    final dateStr = "${now.day}-${_getMonthName(now.month)}";

    try {
      final res = await http.post(
        Uri.parse(scriptUrl),
        body: jsonEncode({
          "action": "add_entry",
          "workerName": widget.workerName,
          "date": dateStr,
          "tiles": tiles.isEmpty ? "0" : tiles,
          "expense": expense.isEmpty ? "0" : expense,
          "notes": _notesController.text.trim(),
        }),
      );
      final data = jsonDecode(res.body);
      if (data["status"] == "success" && mounted) {
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error saving record")),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _getMonthName(int m) {
    const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    return months[m - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${widget.workerName} - Daily Entry")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            TextField(
              controller: _tilesController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Aaj Ki Tiles (Quantity)", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _expenseController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Aaj Ka Advance / Kharcha (Rs.)", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: "Koi Note (Optional)", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            _submitting
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _submit,
                      child: const Text("Save Karein", style: TextStyle(fontSize: 18)),
                    ),
                  )
          ],
        ),
      ),
    );
  }
}
