# create the tohen for the ilovepdf api
# https://developer.ilovepdf.com/docs/api-reference#authentication
 
base64url() {
  # Don't wrap, make URL-safe, delete trailer.
  base64 -w 0 | tr '+/' '-_' | tr -d '='
}

create_jwt_token() {
  test $API_ILOVEPDF_TOKEN || { printf "Missing API_ILOVEPDF_TOKEN. Exit 1."; exit 1; }
  local public_key="project_public_a1ce3b6ab648325fabb24eb512693979_6WTex798599d9e6c612ce592d6f4ae781df76"
  local now=$(date +%s)
  local now4h=$((now + 7200))
  local jwt_header=$(printf '{"alg":"HS256","typ":"JWT"}' | base64url)
  local jwt_claims=$($JQ -Mcn --arg jti "${public_key}" --argjson now ${now} --argjson now4h ${now4h} '{"iss":"", "aud":"", "iat": $now, "nbf": $now, "exp": $now4h, "jti": $jti}' | base64url)
  local jwt_signature=$(echo -n "${jwt_header}.${jwt_claims}" | openssl dgst -sha256 -hmac "${API_ILOVEPDF_TOKEN}" -binary | base64url)
  printf "${jwt_header}.${jwt_claims}.${jwt_signature}"

  # test token
  # https://jwt.io/#debugger-io?token=${jwt_header}.${jwt_claims}.${jwt_signature}
}
