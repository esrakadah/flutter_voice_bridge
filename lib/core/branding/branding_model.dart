import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// Event branding for talks and booths: when [isEventMode] is on, the app uses the DevFest theme and shows
/// the event's name, location, year and flag in the app bar.
@immutable
class BrandingConfig extends Equatable {
  const BrandingConfig({
    this.isEventMode = false,
    this.eventName = defaultEventName,
    this.location = '',
    this.year = '',
    this.flag,
  });

  factory BrandingConfig.fromJson(Map<String, dynamic> json) {
    final flag = json['flag'];
    return BrandingConfig(
      isEventMode: json['isEventMode'] == true,
      eventName: json['eventName'] is String ? json['eventName'] as String : defaultEventName,
      location: json['location'] is String ? json['location'] as String : '',
      year: json['year'] is String ? json['year'] as String : '',
      flag: flag is String && flag.isNotEmpty ? flag : null,
    );
  }

  static const String defaultEventName = 'DevFest';

  final bool isEventMode;
  final String eventName;
  final String location;
  final String year;
  final String? flag;

  /// Event name and location as one line, without stray spaces when either is empty.
  String get title => [eventName, location].where((part) => part.trim().isNotEmpty).join(' ');

  /// Pass `flag: () => null` to remove the flag; omitting it keeps the current one.
  BrandingConfig copyWith({
    bool? isEventMode,
    String? eventName,
    String? location,
    String? year,
    ValueGetter<String?>? flag,
  }) {
    return BrandingConfig(
      isEventMode: isEventMode ?? this.isEventMode,
      eventName: eventName ?? this.eventName,
      location: location ?? this.location,
      year: year ?? this.year,
      flag: flag != null ? flag() : this.flag,
    );
  }

  Map<String, dynamic> toJson() => {
    'isEventMode': isEventMode,
    'eventName': eventName,
    'location': location,
    'year': year,
    'flag': flag,
  };

  @override
  List<Object?> get props => [isEventMode, eventName, location, year, flag];
}
