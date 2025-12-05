#!/usr/bin/env bash

# This script uses the same secret key and example as jwt.io,
# so that you can verify that it's correct.

secret_key="your-256-bit-secret"

base64url() {
    # Don't wrap, make URL-safe, delete trailer.
    base64 -b 0 | tr '+/' '-_' | tr -d '='
}

jwt_header=$(echo -n '{"alg":"HS256","typ":"JWT"}' | base64url)

jwt_claims=$(cat <<EOF |
{
  "sub": "1234567890",
  "name": "John Doe",
  "iat": 1516239022
}
EOF
jq -Mcj '.' | base64url)
# jq -Mcj => Monochrome output, compact output, join lines

jwt_signature=$(echo -n "${jwt_header}.${jwt_claims}" | \
        openssl dgst -sha256 -hmac "$secret_key" -binary | base64url)

# Use the same colours as jwt.io, more-or-less.
echo "$(tput setaf 1)${jwt_header}$(tput sgr0).$(tput setaf 5)${jwt_claims}$(tput sgr0).$(tput setaf 6)${jwt_signature}$(tput sgr0)"

jwt="${jwt_header}.${jwt_claims}.${jwt_signature}"
