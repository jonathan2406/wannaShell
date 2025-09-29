// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cc_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CCSession _$CCSessionFromJson(Map<String, dynamic> json) => CCSession(
      id: json['id'] as String,
      machineName: json['machineName'] as String,
      ipAddress: json['ipAddress'] as String,
      status: $enumDecode(_$SessionStatusEnumMap, json['status']),
      lastCommand: json['lastCommand'] as String?,
      commandHistory: (json['commandHistory'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      timestamp: json['timestamp'] == null
          ? null
          : DateTime.parse(json['timestamp'] as String),
      port: (json['port'] as num?)?.toInt(),
      operatingSystem: json['operatingSystem'] as String?,
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$CCSessionToJson(CCSession instance) => <String, dynamic>{
      'id': instance.id,
      'machineName': instance.machineName,
      'ipAddress': instance.ipAddress,
      'status': _$SessionStatusEnumMap[instance.status]!,
      'lastCommand': instance.lastCommand,
      'commandHistory': instance.commandHistory,
      'timestamp': instance.timestamp.toIso8601String(),
      'port': instance.port,
      'operatingSystem': instance.operatingSystem,
      'notes': instance.notes,
    };

const _$SessionStatusEnumMap = {
  SessionStatus.active: 'active',
  SessionStatus.inactive: 'inactive',
  SessionStatus.connecting: 'connecting',
  SessionStatus.error: 'error',
};
