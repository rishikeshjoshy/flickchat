import 'package:flikchat/themes/theme_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // --- NEW --- Import this

// --- NEW --- Converted to a StatefulWidget
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // --- NEW --- State variable to hold the toggle's value
  bool _isEmotionFeatureEnabled = false;

  // --- NEW --- Load the setting when the page opens
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isEmotionFeatureEnabled =
          prefs.getBool('isEmotionFeatureEnabled') ?? false;
    });
  }

  // --- NEW --- Save the setting when the user taps the toggle
  Future<void> _saveSettings(bool newValue) async {
    setState(() {
      _isEmotionFeatureEnabled = newValue;
    });
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isEmotionFeatureEnabled', newValue);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          "Settings",
          style: TextStyle(
            color: Colors.green,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondary,
            borderRadius: BorderRadius.circular(20)),
        margin: EdgeInsets.all(25),
        padding: EdgeInsets.all(25),

        // --- NEW --- Changed Row to Column to hold multiple settings
        child: Column(
          mainAxisSize: MainAxisSize.min, // Shrinks column to fit content
          children: [
            // 1. Your existing Dark Mode Row (unchanged)
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  //Dark Mode
                  Text("Dark Mode"),

                  //Switch Toggle
                  CupertinoSwitch(
                      value: Provider.of<ThemeProvider>(context, listen: false)
                          .isDarkMode,
                      onChanged: (value) =>
                          Provider.of<ThemeProvider>(context, listen: false)
                              .toggleTheme()),
                ]),

            // --- NEW --- A little space between the two settings
            const SizedBox(height: 16),

            // --- NEW --- 2. The new Emotion Feature Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                //Emotion Feature
                Text("Emotion Feature"),

                //Switch Toggle
                CupertinoSwitch(
                  value: _isEmotionFeatureEnabled,
                  onChanged:
                  _saveSettings, // Calls our new save function
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}