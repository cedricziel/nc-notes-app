import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

/// This file re-exports the PlatformApp from flutter_platform_widgets.
///
/// We're using the package's implementation directly, so this file
/// is just a placeholder to maintain backward compatibility with
/// existing imports in the codebase.
///
/// For new code, import PlatformApp directly from flutter_platform_widgets.
export 'package:flutter_platform_widgets/flutter_platform_widgets.dart'
    show PlatformApp;
