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
Every other valid two-letter country code uses `automatic`. If the request fails, the
token is missing, or the response is invalid, the state remains `unknown` and the game
does not grant automatic personalization.

The list is intentionally stored in the app because there is no server-side policy
resolver. Updating the list therefore requires a new app build.

An explicit player choice always takes priority over the regional default. Automatic
permission is session-only: it is not restored from a previous app launch.

## Timing

The normal lookup is attempted once per app launch, and only after the legal documents
have been accepted. On a fresh install the startup call is therefore a no-op and the same
one-time lookup begins immediately after the mandatory legal acceptance. There is no
periodic polling and no refresh merely because the app resumes from the background.

If that first lookup has left the region `unknown`, the game makes exactly one fallback
request when the player starts level 3, the first ad-enabled level. This request is fully
asynchronous: Play is never disabled and the level transition/gameplay never waits for
IPinfo. The advertising-consent popup has two independent gates and may appear only after
both the gameplay entrance animation and regional resolution have finished. If the launch
lookup is still running at level start, it is allowed to finish first; a failure flows
directly into the single fallback request in the background. If that fallback also fails,
the final region remains `unknown` and the popup is shown anyway, because the game could
not establish that consent is unnecessary. Personalized ads remain disabled until the
player makes an explicit choice.

## Verification

Run the project-specific test with a local Godot executable:

`python3 tools/run_region_consent_tests.py --godot /path/to/godot`

The test runner removes the real token in its temporary project and drives the resolver
with synthetic country-code responses, so it does not contact IPinfo.
