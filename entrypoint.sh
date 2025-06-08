#!/bin/sh
set -e

mkdir -p /etc/traefik/dynamic

cat <<EOF > /etc/traefik/dynamic/middleware.yml
http:
  middlewares:
    my-easy-traefik-rate-limit-jwt:
      plugin:
        easy-traefik-rate-limit-jwt:
          Alg: HS256
          ErrorMessage: "Authentication failed."
          ExpirationMessage: "Your session has expired. Please log in again."
          JwtPayloadFields:
            - exp
            - sub
            - iat
          RoutesToBypassJwtValidation:
            - match: PathPrefix(\`/api/v1/auth\`)
          RoutesToBypassTokenExpiration:
            - match: PathPrefix(\`/api/v1/auth\`)
          Secret:
            - ${JWT_SECRET}
          Sources:
            - key: Authorization
              type: bearer
          InjectNewHeaders:
            X-User-ID:
              From:
                - JwtPayloadFields
              Values:
                - sub
          logs:
            level: DEBUG
    x-api-key:
      headers:
        customRequestHeaders:
          x-api-key: ${X_API_KEY}
EOF

cat <<EOF > /etc/traefik/dynamic/services.yml
http:
  services:
    google-service:
      loadBalancer:
        servers:
          - url: ${USER_SERVICE_URL}/api/v1/google

    auth-service:
      loadBalancer:
        servers:
          - url: ${USER_SERVICE_URL}/api/v1/auth

    users-service:
      loadBalancer:
        servers:
          - url: ${USER_SERVICE_URL}/api/v1/users

    businesses-service:
      loadBalancer:
        servers:
          - url: ${BUSINESS_SERVICE_URL}/api/v1/businesses

    padel-courts-service:
      loadBalancer:
        servers:
          - url: ${BUSINESS_SERVICE_URL}/api/v1/padel-courts

  routers:
    google-router:
      rule: "PathPrefix(`/api/v1/google`)"
      service: google-service
      entryPoints:
        - websecure
      tls:
        certResolver: duckdns
      middlewares:
        - cors
        - my-easy-traefik-rate-limit-jwt
        - x-api-key

    auth-router:
      rule: "PathPrefix(`/api/v1/auth`)"
      service: auth-service
      entryPoints:
        - websecure
      tls:
        certResolver: duckdns
      middlewares:
        - cors
        - my-easy-traefik-rate-limit-jwt
        - x-api-key

    users-router:
      rule: "PathPrefix(`/api/v1/users`)"
      service: users-service
      entryPoints:
        - websecure
      tls:
        certResolver: duckdns
      middlewares:
        - cors
        - my-easy-traefik-rate-limit-jwt
        - x-api-key

    businesses-router:
      rule: "PathPrefix(`/api/v1/businesses`)"
      service: businesses-service
      entryPoints:
        - websecure
      tls:
        certResolver: duckdns
      middlewares:
        - cors
        - my-easy-traefik-rate-limit-jwt
        - x-api-key

    padel-courts-router:
      rule: "PathPrefix(`/api/v1/padel-courts`)"
      service: padel-courts-service
      entryPoints:
        - websecure
      tls:
        certResolver: duckdns
      middlewares:
        - cors
        - my-easy-traefik-rate-limit-jwt
        - x-api-key

EOF

exec traefik "$@"
