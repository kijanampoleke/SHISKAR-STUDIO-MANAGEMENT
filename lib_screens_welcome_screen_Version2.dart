import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.studio_microphone, size: 92, color: Colors.deepPurple),
            const SizedBox(height: 18),
            Text('Welcome to Shiskar Studio Manager',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text(
              'Manage music, video, photo and DIY tech projects — all offline. '
              'Create projects, track tasks, organize media and log technical experiments — securely on your device.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.check),
              label: const Text('Get started'),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('saw_welcome', true);
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainLauncher()));
              },
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('saw_welcome', true);
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainLauncher()));
              },
              child: const Text('Skip'),
            ),
          ],
        ),
      ),
    );
  }
}

class MainLauncher extends StatelessWidget {
  const MainLauncher({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Launching...')));
  }
}