import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _playJingle();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/auth-wrapper');
      }
    });
  }

  Future<void> _playJingle() async {
    try {
      await _audioPlayer.setVolume(0.5);
      await _audioPlayer.play(AssetSource('audio/unimart_jingle.m4a'));
    } catch (e) {
      debugPrint("Error playing audio: $e");
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Align(
              alignment: const Alignment(0, 0),
              child: Image.asset('assets/images/UniMart_Logo.png', width: 235),
            ),
            const SizedBox(height: 10),
            Text('Buy and Sell', style: textTheme.bodyMedium),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
