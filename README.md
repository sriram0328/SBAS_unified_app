# my_first_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

---

## Dev: Auth server & Firestore rules

- A small dev auth server scaffold is included at `auth_server/` that verifies credentials server-side and issues Firebase custom tokens (local port 9002). Follow `auth_server/README.md` to run it locally.
- A permissive dev rules file `firestore.rules.dev` is included for testing. **Do not** deploy it to production.

Recommended flow for secure production:
1. Verify credentials on a trusted backend using the Firebase Admin SDK and issue a custom token with role claims.
2. Client calls the backend, receives the token, then calls `FirebaseAuth.signInWithCustomToken(token)`.
3. Use strict Firestore security rules that allow reads only to authenticated users and according to role claims.

