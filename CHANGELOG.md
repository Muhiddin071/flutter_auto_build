## 1.0.2

* Fixed a bug where process hangs on macOS by switching to `utf8.decoder`
* Builder now shows the actual process output if a step takes too long
* Better error handling for process launch failures

## 1.0.1

* Translated all texts and comments to English

## 1.0.0

* Initial release
* Support for `apk`, `aab`, and `both` build targets
* Automatic `flutter clean` → `pub get` → `build` pipeline
* Environment switching (`dev` / `prod`) via `.env` file
* Animated single progress bar
* Auto-copy build output to `Desktop/Flutter Releases/<project_name>/`

