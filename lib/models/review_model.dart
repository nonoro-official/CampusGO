class ReviewModel {
  final String id;
  final String userId;
  final String userName;
  final double rating;
  final String comment;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory ReviewModel.fromFirestore(String id, Map<String, dynamic> data) {
    return ReviewModel(
      id: id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      rating: (data['rating'] ?? 0).toDouble(),
      comment: data['comment'] ?? '',
      createdAt: (data['createdAt']).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "userId": userId,
      "userName": userName,
      "rating": rating,
      "comment": comment,
      "createdAt": createdAt,
    };
  }
}