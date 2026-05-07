# flutter_auto_build

A CLI tool to automatically build Flutter projects.

Executes `flutter clean → pub get → build apk/aab` with a single command, featuring `.env` environment switching.

## Installation

Add to `pubspec.yaml`:

```yaml
dev_dependencies:
  flutter_auto_build: ^1.0.0
```

Keyin:

```bash
dart pub get
```

## Usage

```bash
# APK build (default)
dart run flutter_auto_build apk

# APK with Dev environment
dart run flutter_auto_build apk dev

# APK with Prod environment
dart run flutter_auto_build apk prod

# App Bundle (AAB)
dart run flutter_auto_build aab prod

# Both APK and AAB
dart run flutter_auto_build both prod
```

## .env file format

```env
BASE_URL=https://api.example.com/api
IMAGE_URL=https://api.example.com/storage/
TEST_BASE_URL=https://testapi.example.com/api
TEST_IMAGE_URL=https://testapi.example.com/storage/
```

- `dev` → writes `TEST_BASE_URL` and `TEST_IMAGE_URL` to `BASE_URL` / `IMAGE_URL`
- `prod` → keeps the main `BASE_URL` / `IMAGE_URL`
- If omitted → `.env` remains unchanged

## Build Output

The built files are automatically copied to `Desktop/Flutter Releases/<project_name>/`:

```
~/Desktop/Flutter Releases/
  my_app/
    my_app_dev_release.apk
    my_app_prod_release.aab
```
