# Build stage
FROM cirrusci/flutter:latest AS build

WORKDIR /app

# Copy source code
COPY . .

# Install dependencies and build web
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
