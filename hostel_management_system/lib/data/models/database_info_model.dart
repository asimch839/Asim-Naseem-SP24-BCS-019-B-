class DatabaseInfoModel {
  final String path;
  final String directory;
  final int fileSizeBytes;
  final String fileSizeFormatted;
  final int totalRecords;
  final Map<String, int> tableCounts;
  final DateTime? lastModified;
  final String? lastBackupAt;
  final bool isConnected;

  DatabaseInfoModel({
    required this.path,
    required this.directory,
    required this.fileSizeBytes,
    required this.fileSizeFormatted,
    required this.totalRecords,
    required this.tableCounts,
    this.lastModified,
    this.lastBackupAt,
    this.isConnected = true,
  });
}
