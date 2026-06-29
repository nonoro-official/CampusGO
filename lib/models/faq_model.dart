class FAQModel {
  final String question;
  final String answer;

  FAQModel({required this.question, required this.answer});

  factory FAQModel.fromMap(Map<String, dynamic> data) {
    return FAQModel(
      question: data['question'] ?? '',
      answer: data['answer'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'question': question,
      'answer': answer,
    };
  }
}