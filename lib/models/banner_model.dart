class BannerModal {
  final int id;
  final String title;
  final String image;
  final String status;
  final String createdAt;
  final String updatedAt;

  BannerModal({
    required this.id,
    required this.title,
    required this.image,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BannerModal.fromJson(Map<String, dynamic> json) {
    return BannerModal(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      image: json['image'] ?? '',
      status: json['status'] ?? '0',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }
}