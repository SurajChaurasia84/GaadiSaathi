enum BookingStatus {
  pending,
  confirmed,
  cancelled,
}

class ChatMessage {
  final String senderId; // sender's gmail
  final String text;
  final DateTime timestamp;
  final bool isBookingProposal;
  final BookingStatus? bookingStatus;
  final double? ratePerKm;

  ChatMessage({
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.isBookingProposal = false,
    this.bookingStatus,
    this.ratePerKm,
  });

  ChatMessage copyWith({
    String? senderId,
    String? text,
    DateTime? timestamp,
    bool? isBookingProposal,
    BookingStatus? bookingStatus,
    double? ratePerKm,
  }) {
    return ChatMessage(
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      isBookingProposal: isBookingProposal ?? this.isBookingProposal,
      bookingStatus: bookingStatus ?? this.bookingStatus,
      ratePerKm: ratePerKm ?? this.ratePerKm,
    );
  }
}

class ChatThread {
  final String threadId;
  final String customerName;
  final String customerGmail;
  final String ownerName;
  final String ownerGmail;
  final String vehicleModel;
  final List<ChatMessage> messages;

  ChatThread({
    required this.threadId,
    required this.customerName,
    required this.customerGmail,
    required this.ownerName,
    required this.ownerGmail,
    required this.vehicleModel,
    required this.messages,
  });

  String get lastMessageText {
    if (messages.isEmpty) return 'No messages yet';
    return messages.last.text;
  }

  DateTime get lastMessageTime {
    if (messages.isEmpty) return DateTime.now();
    return messages.last.timestamp;
  }

  ChatThread copyWith({
    String? threadId,
    String? customerName,
    String? customerGmail,
    String? ownerName,
    String? ownerGmail,
    String? vehicleModel,
    List<ChatMessage>? messages,
  }) {
    return ChatThread(
      threadId: threadId ?? this.threadId,
      customerName: customerName ?? this.customerName,
      customerGmail: customerGmail ?? this.customerGmail,
      ownerName: ownerName ?? this.ownerName,
      ownerGmail: ownerGmail ?? this.ownerGmail,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      messages: messages ?? this.messages,
    );
  }
}
