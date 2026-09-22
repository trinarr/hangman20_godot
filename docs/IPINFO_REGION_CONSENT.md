# IPinfo Lite: regional advertising consent

The game determines only the country of the current public IP connection and uses
that result to choose the advertising-consent flow. No developer-operated server is
required.

## Runtime request

The Godot client calls:

`https://api.ipinfo.io/lite/me/country_code?token=<TOKEN>`

The checked-in token is configured under `[ad_privacy]` in `project.godot`. Because
this is a native client, the token is shipped inside the APK and must be treated as
public/extractable. Use a dedicated IPinfo Lite token and rotate it if necessary.

Only the two-letter country-code response is consumed by the game. The request still
necessarily exposes the connection IP address to IPinfo at the network layer. No game
save, profile identifier or advertising identifier is added to this request.

## Regional rule

`required` currently means EEA countries plus the United Kingdom and Switzerland.
Every other assigned ISO 3166-1 alpha-2 country code uses `automatic`. If the request fails, the
token is missing, or the response is invalid, the state remains `unknown` and the game
does not grant automatic personalization.

The list is intentionally stored in the app because there is no server-side policy
resolver. Updating the list therefore requires a new app build.

An explicit player choice always takes priority over the regional default. Automatic
permission is session-only: it is not restored from a previous app launch.

## Timing

The normal lookup is attempted at most once per app launch, only after the legal documents
have been accepted, and only while there is no saved explicit advertising-personalization
choice. Once the player has explicitly accepted or denied personalization, later app
launches do not contact IPinfo at all. On a fresh install the startup call is therefore a
no-op and the one-time lookup begins immediately after the mandatory legal acceptance.
There is no periodic polling and no refresh merely because the app resumes from the background.

If that first lookup has left the region `unknown`, the game makes at most one fallback
request when the player starts level 3, the first ad-enabled level. This request is fully
asynchronous: Play is never disabled and the level transition/gameplay never waits for
IPinfo. The advertising-consent popup has two independent gates and may appear only after
both the gameplay entrance animation and regional resolution have finished. If the launch
lookup is still running at level start, it is allowed to finish first; a failure flows
directly into the single fallback request in the background. If that fallback also fails,
the final region remains `unknown` and the popup is shown anyway, because the game could
not establish that consent is unnecessary. Personalized ads remain disabled until the
player makes an explicit choice.

The SDK has a separate game-readiness gate: permission (regional or explicit) is
resolved/stored independently, but Yandex initialization and automatic ad preloads
start only after advertising is unlocked at level 3. A saved refusal still permits
non-personalized advertising after that threshold. Existing unlocked profiles can
initialize on launch once their advertising decision is known.

## Validation and errors

Only the exact HTTPS `/lite/me/country_code` endpoint is accepted, with redirects
disabled, a five-second timeout and a 1 KiB response limit. A successful response
must be HTTP 200 with an assigned uppercase ISO country code (surrounding ASCII
whitespace is allowed). If Content-Type is supplied, it must be `text/plain`.
HTML, JSON, invalid bytes, oversized country payloads and unassigned codes fail closed.

`last_lookup_error` and `last_http_status` provide diagnostics without storing a URL,
token, IP or response body. Timeout/transport errors, malformed responses and 5xx
errors can use the single level-3 fallback. Missing tokens, invalid endpoints,
401/403, other 4xx and unexpected HTTP statuses do not cause a futile second request.
429 suppresses further requests for the entire app launch, including the fallback;
there is no immediate retry or polling. Resolution still completes as UNKNOWN so
the consent UI does not wait indefinitely. Gameplay never waits for geolocation.

Saving an explicit player choice cancels an in-flight lookup and invalidates its
callback. A late response cannot persist a new regional default or start a retry.

## Verification

Run the project-specific test with a local Godot executable:

`python3 tools/run_region_consent_tests.py --godot /path/to/godot`

The test runner removes the real token in its temporary project and drives the resolver
with synthetic country-code responses, so it does not contact IPinfo.
