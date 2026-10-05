/// The one place the backend address lives. By default the app talks to the
/// hosted DIGIVET Online API on Vercel. For development against the laptop,
/// override it per run (run-phone.bat does this):
///   flutter run --dart-define=API_BASE=http://192.168.1.8:4001/api
const String apiBase = String.fromEnvironment(
  'API_BASE',
  defaultValue: 'https://digivetlipa.vercel.app/api',
);
