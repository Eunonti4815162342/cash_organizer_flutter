# Flutter Environment Configuration

## Overview
The Flutter frontend supports three environments: Development, Staging, and Production. The app automatically selects the appropriate environment based on the build type.

## Automatic Environment Selection

The app uses `EnvironmentFactory.initAuto()` which automatically selects:
- **Debug builds**: Development environment
- **Release builds**: Production environment

### Build and Run

**Development (default)**
```bash
flutter run
# Uses DevelopmentEnvironment with localhost API
```

**Staging**
To run staging, you need to modify main.dart temporarily or use build flavors (see Advanced section).

**Production**
```bash
flutter run --release
# Uses ProductionEnvironment with production API
```

## Environment Configurations

### Development Environment
- **API Base URL**: `http://localhost:8085/api`
- **API Timeout**: 30 seconds (lenient for debugging)
- **Logging**: Enabled (detailed request/response logs)
- **Database**: `cash_organizer_dev.db`
- **Background Sync**: Every 15 minutes
- **Debug Features**: All enabled

**Use case**: Local development with backend running on localhost

```bash
flutter run
# Connects to http://localhost:8085/api
```

### Staging Environment
- **API Base URL**: `https://staging-api.cashorganizer.com/api`
- **API Timeout**: 20 seconds
- **Logging**: Enabled (for debugging issues on staging)
- **Database**: `cash_organizer_staging.db`
- **Background Sync**: Every 30 minutes
- **CORS Origins**: staging.cashorganizer.com, app-staging.cashorganizer.com

**Use case**: Testing against staging server before production

### Production Environment
- **API Base URL**: `https://api.cashorganizer.com/api`
- **API Timeout**: 15 seconds (strict timeout)
- **Logging**: Disabled (no sensitive data in logs)
- **Database**: `cash_organizer_prod.db`
- **Background Sync**: Every 60 minutes (less frequent)
- **Release mode**: Always

**Use case**: Production deployment

```bash
flutter run --release
# Connects to https://api.cashorganizer.com/api
```

## Advanced: Using Build Flavors (Recommended)

For easier switching between environments without code changes, use Flutter build flavors:

### 1. Create flavor-specific main files

**lib/main_dev.dart**
```dart
import 'config/environment_factory.dart';
import 'main.dart' as main_app;

void main() {
  EnvironmentFactory.init(type: EnvironmentType.development);
  main_app.main();
}
```

**lib/main_staging.dart**
```dart
import 'config/environment_factory.dart';
import 'main.dart' as main_app;

void main() {
  EnvironmentFactory.init(type: EnvironmentType.staging);
  main_app.main();
}
```

**lib/main_prod.dart**
```dart
import 'config/environment_factory.dart';
import 'main.dart' as main_app;

void main() {
  EnvironmentFactory.init(type: EnvironmentType.production);
  main_app.main();
}
```

### 2. Update pubspec.yaml

Add flavor configurations (this is optional but recommended):

```yaml
# In your CI/CD, you can then run:
# flutter run -t lib/main_dev.dart --flavor dev
# flutter run -t lib/main_staging.dart --flavor staging
# flutter run -t lib/main_prod.dart --flavor prod
```

### 3. Run with flavors

```bash
# Development
flutter run -t lib/main_dev.dart

# Staging
flutter run -t lib/main_staging.dart

# Production
flutter run -t lib/main_prod.dart
```

## Configuration Access in Code

Access environment configuration anywhere in the app:

```dart
import 'config/environment_factory.dart';

// Get current environment
final env = EnvironmentFactory.current;

// Access specific settings
final apiUrl = env.apiBaseUrl;
final timeout = env.apiTimeout;
final isProduction = env.isProduction;
final enableLogging = env.enableLogging;

// Conditional logic based on environment
if (!env.isProduction) {
  print('Debug logs enabled');
}

// In widgets
Text('Environment: ${EnvironmentFactory.getEnvironmentName()}')
```

## HttpClientManager Integration

The `HttpClientManager` automatically uses the current environment:

```dart
final clientManager = HttpClientManager();
// Automatically gets API URL from current environment
final url = clientManager.baseUrl; // e.g., http://localhost:8085/api

// Timeout also comes from environment
final timeout = clientManager.apiTimeout;

// Logging controlled by environment
if (clientManager.enableLogging) {
  print('Request to: $url');
}
```

## Database Management

Each environment has its own SQLite database to prevent data conflicts:

- **Dev**: `cash_organizer_dev.db`
- **Staging**: `cash_organizer_staging.db`
- **Prod**: `cash_organizer_prod.db`

This allows you to test on staging without losing dev data.

## SSL/HTTPS in Different Environments

- **Development**: HTTP (localhost)
- **Staging**: HTTPS (staging-api.cashorganizer.com)
- **Production**: HTTPS (api.cashorganizer.com)

The app automatically uses HTTPS for staging and production.

## Background Sync Intervals

Background sync frequency varies by environment:

- **Development**: 15 minutes (fast testing)
- **Staging**: 30 minutes (realistic but testable)
- **Production**: 60 minutes (less battery drain)

## Testing Against Different Backends

### Test development environment
```bash
# Ensure backend is running on localhost:8085
./gradlew bootRun --args='--spring.profiles.active=dev'

# Then run the app
flutter run
```

### Test staging environment
```bash
# Either:
# 1. Use the flavor approach (recommended)
flutter run -t lib/main_staging.dart

# 2. Or temporarily modify main.dart to force staging
# Change EnvironmentFactory.initAuto() to:
# EnvironmentFactory.init(type: EnvironmentType.staging);
```

### Test production environment
```bash
# Create a release build
flutter build apk --release
# or for iOS
flutter build ios --release

# For local testing, you can temporarily modify main.dart:
# EnvironmentFactory.init(type: EnvironmentType.production);
flutter run --release
```

## Troubleshooting

### Wrong API being called
1. Check which environment the app is using:
   ```dart
   print('Current environment: ${EnvironmentFactory.getEnvironmentName()}');
   ```
2. Verify the build type (debug vs release)
3. If using flavors, ensure the correct main file is specified with `-t`

### Connection refused on localhost
1. Verify backend is running on port 8085
2. Check that development build is being used (not release)
3. Ensure HttpClientManager is using correct baseUrl

### Wrong database being used
1. Each environment has its own database
2. Clear app data if switching environments:
   ```bash
   flutter clean
   flutter run
   ```

### Environment not updating
1. Do a clean build: `flutter clean`
2. Rebuild: `flutter run` or `flutter run --release`

## Security Notes

- **Never commit API credentials** in the environment files
- Use secure storage (FlutterSecureStorage) for tokens
- Production API URLs are hardcoded (safe - just URL, no credentials)
- Development environment uses HTTP only on localhost (safe - local only)
- Staging and production use HTTPS

## CI/CD Integration

### GitHub Actions example
```yaml
- name: Run development build
  run: flutter run -t lib/main_dev.dart --release

- name: Run staging build
  run: flutter run -t lib/main_staging.dart --release

- name: Run production build
  run: flutter run -t lib/main_prod.dart --release
```

## Environment Variables (Future Enhancement)

For additional security, you could extend the environment system to use:
- .env files for local development
- Platform channels for injected configurations
- Firebase Remote Config for dynamic values

Currently, all configurations are hardcoded in the environment classes (which is safe since there are no secrets).
