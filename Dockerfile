# Build stage - ARM64 compatible
FROM ubuntu:22.04 AS build

ARG API_BASE_URL=http://localhost:8085/api
ARG API_TIMEOUT=30
ARG ENABLE_LOGGING=false
ARG IS_PRODUCTION=true
ARG ENVIRONMENT_NAME=Production

ENV DEBIAN_FRONTEND=noninteractive
ENV FLUTTER_HOME=/usr/local/flutter
ENV PATH=$FLUTTER_HOME/bin:$FLUTTER_HOME/bin/cache/dart-sdk/bin:$PATH

WORKDIR /app

# Install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install Flutter
RUN git clone --depth 1 -b stable https://github.com/flutter/flutter.git $FLUTTER_HOME && \
    flutter config --no-analytics && \
    flutter precache

# Copy source code
COPY . .

# Generate runtime configuration from build arguments
RUN mkdir -p assets && \
    echo "{ \
      \"apiBaseUrl\": \"${API_BASE_URL}\", \
      \"apiTimeout\": ${API_TIMEOUT}, \
      \"enableLogging\": ${ENABLE_LOGGING}, \
      \"isProduction\": ${IS_PRODUCTION}, \
      \"environmentName\": \"${ENVIRONMENT_NAME}\", \
      \"tokenExpirationHours\": 24, \
      \"enableBiometric\": true, \
      \"enableBackgroundSync\": true, \
      \"backgroundSyncIntervalMinutes\": 60, \
      \"databaseName\": \"cash_organizer_prod.db\" \
    }" > assets/config.json

# Build web app
RUN flutter pub get && \
    flutter build web --release --no-tree-shake-icons

# Runtime stage
FROM nginx:alpine

# Copy built web app to nginx
COPY --from=build /app/build/web /usr/share/nginx/html

# Copy nginx configuration
RUN rm /etc/nginx/conf.d/default.conf
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
