import 'package:flutter/material.dart';

abstract final class AppText {
  static const _family = 'Inter';

  // Navigation bar title — 17pt / semibold
  static const navTitle = TextStyle(
    fontFamily: _family,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: -0.4,
  );

  // Large headline for mobile — 28pt / bold
  static const headlineLgMobile = TextStyle(
    fontFamily: _family,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.5,
  );

  // Body medium — 15pt / regular
  static const bodyMd = TextStyle(
    fontFamily: _family,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: -0.2,
  );

  // Callout — 16pt / regular
  static const callout = TextStyle(
    fontFamily: _family,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.4,
    letterSpacing: -0.3,
  );

  // Subhead — 15pt / medium
  static const subhead = TextStyle(
    fontFamily: _family,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: -0.2,
  );

  // Footnote — 13pt / regular
  static const footnote = TextStyle(
    fontFamily: _family,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.4,
    letterSpacing: -0.1,
  );

  // Label caps — 11pt / semibold / uppercase
  static const labelCaps = TextStyle(
    fontFamily: _family,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0.6,
  );
}
