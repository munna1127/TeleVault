/// Statistics displayed on the home screen.
class BackupStats {
  const BackupStats({
    this.totalPhotos = 0,
    this.totalVideos = 0,
    this.lastBackupTime,
    this.isScanning = false,
  });

  final int totalPhotos;
  final int totalVideos;
  final DateTime? lastBackupTime;
  final bool isScanning;

  int get totalMedia => totalPhotos + totalVideos;

  BackupStats copyWith({
    int? totalPhotos,
    int? totalVideos,
    DateTime? lastBackupTime,
    bool? isScanning,
  }) {
    return BackupStats(
      totalPhotos: totalPhotos ?? this.totalPhotos,
      totalVideos: totalVideos ?? this.totalVideos,
      lastBackupTime: lastBackupTime ?? this.lastBackupTime,
      isScanning: isScanning ?? this.isScanning,
    );
  }
}
