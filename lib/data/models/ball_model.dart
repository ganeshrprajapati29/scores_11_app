class BallModel {
  final String id;
  final String matchId;
  final int overNumber;
  final int ballNumber;
  final String batsmanId;
  final String batsmanName;
  final String bowlerId;
  final String bowlerName;
  final int runs;
  final int? wicketType; // 0: no wicket, 1: bowled, 2: caught, 3: stumped, etc.
  final String? wicketBy;
  final bool isWide;
  final bool isNoBall;
  final bool isBye;
  final bool isLegBye;
  final String? commentary;
  final DateTime timestamp;

  BallModel({
    required this.id,
    required this.matchId,
    required this.overNumber,
    required this.ballNumber,
    required this.batsmanId,
    required this.batsmanName,
    required this.bowlerId,
    required this.bowlerName,
    required this.runs,
    this.wicketType,
    this.wicketBy,
    this.isWide = false,
    this.isNoBall = false,
    this.isBye = false,
    this.isLegBye = false,
    this.commentary,
    required this.timestamp,
  });

  factory BallModel.fromJson(Map<String, dynamic> json) {
    return BallModel(
      id: json['_id'] ?? '',
      matchId: json['matchId'] ?? '',
      overNumber: json['overNumber'] ?? 0,
      ballNumber: json['ballNumber'] ?? 0,
      batsmanId: json['batsmanId'] ?? '',
      batsmanName: json['batsmanName'] ?? '',
      bowlerId: json['bowlerId'] ?? '',
      bowlerName: json['bowlerName'] ?? '',
      runs: json['runs'] ?? 0,
      wicketType: json['wicketType'],
      wicketBy: json['wicketBy'],
      isWide: json['isWide'] ?? false,
      isNoBall: json['isNoBall'] ?? false,
      isBye: json['isBye'] ?? false,
      isLegBye: json['isLegBye'] ?? false,
      commentary: json['commentary'],
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'matchId': matchId,
      'overNumber': overNumber,
      'ballNumber': ballNumber,
      'batsmanId': batsmanId,
      'batsmanName': batsmanName,
      'bowlerId': bowlerId,
      'bowlerName': bowlerName,
      'runs': runs,
      'wicketType': wicketType,
      'wicketBy': wicketBy,
      'isWide': isWide,
      'isNoBall': isNoBall,
      'isBye': isBye,
      'isLegBye': isLegBye,
      'commentary': commentary,
    };
  }
}
