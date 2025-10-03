// models/song_list_model.dart
class SongListModel {
  final String id;
  final DateTime serviceDate;
  final List<String> songs;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String serviceType;

  SongListModel({
    required this.id,
    required this.serviceDate,
    required this.songs,
    required this.createdAt,
    this.updatedAt,
    this.serviceType = '',
  });

  factory SongListModel.fromJson(Map<String, dynamic> json) {
    return SongListModel(
      id: json['id'] ?? '',
      serviceDate: json['serviceDate']?.toDate() ?? DateTime.now(),
      songs: List<String>.from(json['songs'] ?? []),
      createdAt: json['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: json['updatedAt']?.toDate(),
      serviceType: json['serviceType'] ?? '', // Parse from JSON
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serviceDate': serviceDate,
      'songs': songs,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'serviceType': serviceType, // Include in JSON
    };
  }
}
