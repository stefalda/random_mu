/// Models for the offline download system.
library;

/// Represents an item that can be downloaded for offline use.
enum DownloadItemType { playlist, album, artist, favorites }

/// Status of a download item.
enum DownloadStatus { queued, downloading, completed, failed }

/// An item in the download queue.
class DownloadItem {
  final String id;
  final String title;
  final DownloadItemType type;
  final String sourceId; // playlist ID, album ID, artist ID, or "favorites"
  final DownloadStatus status;
  final double progress; // 0.0 to 1.0
  final int totalSongs;
  final int downloadedSongs;
  final String? errorMessage;

  const DownloadItem({
    required this.id,
    required this.title,
    required this.type,
    required this.sourceId,
    this.status = DownloadStatus.queued,
    this.progress = 0.0,
    this.totalSongs = 0,
    this.downloadedSongs = 0,
    this.errorMessage,
  });

  DownloadItem copyWith({
    DownloadStatus? status,
    double? progress,
    int? totalSongs,
    int? downloadedSongs,
    String? errorMessage,
  }) {
    return DownloadItem(
      id: id,
      title: title,
      type: type,
      sourceId: sourceId,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      totalSongs: totalSongs ?? this.totalSongs,
      downloadedSongs: downloadedSongs ?? this.downloadedSongs,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'type': type.name,
        'sourceId': sourceId,
        'status': status.name,
        'progress': progress,
        'totalSongs': totalSongs,
        'downloadedSongs': downloadedSongs,
        'errorMessage': errorMessage,
      };

  factory DownloadItem.fromJson(Map<String, dynamic> json) => DownloadItem(
        id: json['id'] as String,
        title: json['title'] as String,
        type: DownloadItemType.values.firstWhere(
            (e) => e.name == json['type']),
        sourceId: json['sourceId'] as String,
        status: DownloadStatus.values.firstWhere(
            (e) => e.name == json['status']),
        progress: (json['progress'] as num).toDouble(),
        totalSongs: json['totalSongs'] as int,
        downloadedSongs: json['downloadedSongs'] as int,
        errorMessage: json['errorMessage'] as String?,
      );
}

/// Information about used and total storage for offline content.
class StorageInfo {
  final int usedBytes;
  final int? limitBytes; // null means unlimited

  const StorageInfo({this.usedBytes = 0, this.limitBytes});

  StorageInfo copyWith({int? usedBytes, int? limitBytes}) {
    return StorageInfo(
      usedBytes: usedBytes ?? this.usedBytes,
      limitBytes: limitBytes ?? this.limitBytes,
    );
  }

  bool get isUnlimited => limitBytes == null;
  bool get isLimitReached => limitBytes != null && usedBytes >= limitBytes!;
  double get usedFraction =>
      limitBytes != null ? usedBytes / limitBytes! : 0.0;

  String get usedFormatted => _formatBytes(usedBytes);
  String get limitFormatted =>
      limitBytes != null ? _formatBytes(limitBytes!) : 'Unlimited';

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
