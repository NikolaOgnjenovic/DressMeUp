class ImageUploadResponse {
  final int id;
  final String imgurUrl;
  final DateTime? uploadDate;

  ImageUploadResponse({
    required this.id,
    required this.imgurUrl,
    this.uploadDate,
  });

  factory ImageUploadResponse.fromJson(Map<String, dynamic> json) {
    return ImageUploadResponse(
      id: json['id'],
      imgurUrl: json['imgur_url'],
      uploadDate: json['upload_date'] != null 
          ? DateTime.parse(json['upload_date']) 
          : null,
    );
  }
}