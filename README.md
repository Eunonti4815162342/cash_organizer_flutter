# cash_organizer_flutter

Cliente Flutter del cash organizer (backend Spring Boot en puerto 8085).

## Configuración del backend

La URL del backend se resuelve en `lib/services/api/api_client.dart` en este orden:

1. `--dart-define=API_BASE_URL=...` (build-time, prioritario).
2. Web sin flag → `http://localhost:8085/api`.
3. Nativo sin flag → `http://100.86.48.34:8085/api` (IP Tailscale dev).

Ejemplos:

```bash
# Dev contra backend local
flutter run --dart-define=API_BASE_URL=http://localhost:8085/api

# Build producción contra API real
flutter build apk --release --dart-define=API_BASE_URL=https://api.example.com/api
```

Sin flag funciona el flujo dev actual (web → localhost, móvil → Tailscale).
