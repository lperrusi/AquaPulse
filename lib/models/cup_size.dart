/// Cup Size Model
///
/// Defines the CupSize data model for customizable quick-add water intake buttons.
/// Includes name, amount, icon, and default status.
class CupSize {
  final String id;
  final String name;
  final double amount; // in ml
  final String? icon;
  final bool isDefault;
  final DateTime createdAt;

  const CupSize({
    required this.id,
    required this.name,
    required this.amount,
    this.icon,
    this.isDefault = false,
    required this.createdAt,
  });

  CupSize copyWith({
    String? id,
    String? name,
    double? amount,
    String? icon,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return CupSize(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      icon: icon ?? this.icon,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'icon': icon,
      'is_default': isDefault ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory CupSize.fromJson(Map<String, dynamic> json) {
    return CupSize(
      id: json['id'] as String,
      name: json['name'] as String,
      amount: json['amount'] as double,
      icon: json['icon'] as String?,
      isDefault: (json['is_default'] as int) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at'] as int),
    );
  }

  @override
  String toString() {
    return 'CupSize(id: $id, name: $name, amount: $amount, icon: $icon, isDefault: $isDefault, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CupSize &&
        other.id == id &&
        other.name == name &&
        other.amount == amount &&
        other.icon == icon &&
        other.isDefault == isDefault &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        amount.hashCode ^
        icon.hashCode ^
        isDefault.hashCode ^
        createdAt.hashCode;
  }
} 