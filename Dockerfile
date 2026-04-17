# Build stage - ARM64 compatible
FROM ubuntu:22.04 AS build

ARG CONFIG_FILE=config.prod.json

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

# Select configuration file based on build argument
# This allows same code to work in any environment without code changes
RUN cp assets/${CONFIG_FILE} assets/config.json

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
