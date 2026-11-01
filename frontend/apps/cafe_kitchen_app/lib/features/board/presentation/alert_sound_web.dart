import 'package:web/web.dart' as web;

// A short tone from the browser's audio engine. Browsers allow it once the screen has been tapped.
void playAlert() {
  final ctx = web.AudioContext();
  final osc = ctx.createOscillator();
  final gain = ctx.createGain();
  osc.frequency.value = 880;
  gain.gain.value = 0.3;
  osc.connect(gain);
  gain.connect(ctx.destination);
  osc.start();
  osc.stop(ctx.currentTime + 0.4);
}
