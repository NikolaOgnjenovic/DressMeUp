class ImageUploadResponse {
  final String imageId;
  final String imageUrl;
  final DateTime? uploadDate;

  ImageUploadResponse({
    required this.imageId,
    required this.imageUrl,
    this.uploadDate,
  });

  factory ImageUploadResponse.fromJson(Map<String, dynamic> json) {
    return ImageUploadResponse(
      imageId: json['image_id'],
      imageUrl: json['image_url'],
      uploadDate: json['upload_date'] != null ? DateTime.parse(json['upload_date']) : null,
    );
  }
}