import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

enum PlnState { idle, loading, success, error }

class NearestPlnController extends GetxController {
  final state = PlnState.idle.obs;
  final errorMessage = ''.obs;
  final latitude = 0.0.obs;
  final longitude = 0.0.obs;

  @override
  void onReady() {
    super.onReady();
    fetchLocationAndOpen();
  }

  Future<void> fetchLocationAndOpen() async {
    state.value = PlnState.loading;
    errorMessage.value = '';

    try {
      final position = await _determinePosition();
      latitude.value = position.latitude;
      longitude.value = position.longitude;
      state.value = PlnState.success;
    } catch (e) {
      errorMessage.value = e.toString();
      state.value = PlnState.error;
    }
  }

  Future<void> openInMaps() async {
    if (state.value != PlnState.success) return;

    final lat = latitude.value;
    final lng = longitude.value;

    // Search "Kantor PLN terdekat" centered on user location
    final uri = Uri.parse(
      'https://www.google.com/maps/search/Kantor+PLN+terdekat/@$lat,$lng,15z',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      errorMessage.value = 'Could not open Google Maps.';
    }
  }

  // ── Location logic ─────────────────────────────────────────────────────────

  Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw 'Location services are disabled. Please enable GPS.';
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'Location permission denied.';
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw 'Location permission permanently denied. Enable it in app settings.';
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }
}
