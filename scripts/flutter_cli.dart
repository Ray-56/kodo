// Flutter 3.41.4's discovery crashes on an unrelated Intel-only Android Studio
// after Rosetta is removed. Use the explicitly configured JDK/SDK for CLI builds.
// Run with the pinned Flutter tool's package_config.json and FLUTTER_ROOT set.
// This does not modify the SDK or installed IDEs.
import 'package:flutter_tools/executable.dart' as executable;
import 'package:flutter_tools/src/android/android_studio.dart';
import 'package:flutter_tools/src/base/context.dart';

Future<void> main(List<String> args) => context.run<void>(
  body: () => executable.main(args),
  overrides: {
    AndroidStudio: () => AndroidStudio('/nonexistent/kodo-cli-only'),
  },
);
