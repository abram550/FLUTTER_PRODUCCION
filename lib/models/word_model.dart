// models/word_model.dart
class WordModel {
  final String id;
  final String fullName;
  final DateTime date;
  final String startTime;
  final String endTime;
  final String wordType;
  final String service;
  final String? streamLink;
  final DateTime createdAt;

  WordModel({
    required this.id,
    required this.fullName,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.wordType,
    required this.service,
    this.streamLink,
    required this.createdAt,
  });

  factory WordModel.fromJson(Map<String, dynamic> json) {
    return WordModel(
      id: json['id'] ?? '',
      fullName: json['fullName'] ?? '',
      date: json['date']?.toDate() ?? DateTime.now(),
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      wordType: json['wordType'] ?? '',
      service: json['service'] ?? '',
      streamLink: json['streamLink'],
      createdAt: json['createdAt']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'date': date,
      'startTime': startTime,
      'endTime': endTime,
      'wordType': wordType,
      'service': service,
      'streamLink': streamLink,
      'createdAt': createdAt,
    };
  }
}