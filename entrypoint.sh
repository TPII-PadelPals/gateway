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
EOF

exec traefik "$@"