import 'package:json_annotation/json_annotation.dart';
part 'vosk_result.g.dart';

@JsonSerializable()
class VoskResult {
  String text;

  VoskResult({
    required this.text,
  });

  factory VoskResult.fromJson(Map<String, dynamic> json) =>
      _$VoskResultFromJson(json);
  Map<String, dynamic> toJson() => _$VoskResultToJson(this);
}
