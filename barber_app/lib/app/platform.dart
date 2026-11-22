import 'package:flutter/foundation.dart';

/// ویندوز فقط بخش آرایشگاه را دارد (مشتری فقط موبایل است)
bool get isWindowsApp => defaultTargetPlatform == TargetPlatform.windows;
