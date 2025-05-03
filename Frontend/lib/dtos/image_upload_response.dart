class ImageUploadResponse {
  final String imageId;
  final String imageUrl;

  ImageUploadResponse({
    required this.imageId,
    required this.imageUrl,
  });

  factory ImageUploadResponse.fromJson(Map<String, dynamic> json) {
    return ImageUploadResponse(
      imageId: json['image_id'],
      imageUrl: json['image_url'],
    );
  }
}