class UserGoals {
  final int stepGoal;
  final double waterGoal;
  final int sleepGoal;
  final int calorieGoal;

  const UserGoals({
    this.stepGoal = 10000,
    this.waterGoal = 2.5,
    this.sleepGoal = 480,
    this.calorieGoal = 2000,
  });

  factory UserGoals.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const UserGoals();
    return UserGoals(
      stepGoal: (json['stepGoal'] as num?)?.toInt() ?? 10000,
      waterGoal: (json['waterGoal'] as num?)?.toDouble() ?? 2.5,
      sleepGoal: (json['sleepGoal'] as num?)?.toInt() ?? 480,
      calorieGoal: (json['calorieGoal'] as num?)?.toInt() ?? 2000,
    );
  }

  Map<String, dynamic> toJson() => {
        'stepGoal': stepGoal,
        'waterGoal': waterGoal,
        'sleepGoal': sleepGoal,
        'calorieGoal': calorieGoal,
      };

  UserGoals copyWith({
    int? stepGoal,
    double? waterGoal,
    int? sleepGoal,
    int? calorieGoal,
  }) {
    return UserGoals(
      stepGoal: stepGoal ?? this.stepGoal,
      waterGoal: waterGoal ?? this.waterGoal,
      sleepGoal: sleepGoal ?? this.sleepGoal,
      calorieGoal: calorieGoal ?? this.calorieGoal,
    );
  }
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final String authProvider;
  final int age;
  final String gender;
  final double weight;
  final double height;
  final double bmi;
  final UserGoals goals;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.authProvider = 'local',
    this.age = 21,
    this.gender = 'male',
    this.weight = 68.0,
    this.height = 175.0,
    this.bmi = 22.2,
    this.goals = const UserGoals(),
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Athlete',
      email: json['email']?.toString() ?? '',
      authProvider: json['authProvider']?.toString() ?? 'local',
      age: (json['age'] as num?)?.toInt() ?? 21,
      gender: json['gender']?.toString() ?? 'male',
      weight: (json['weight'] as num?)?.toDouble() ?? 68.0,
      height: (json['height'] as num?)?.toDouble() ?? 175.0,
      bmi: (json['bmi'] as num?)?.toDouble() ?? 22.2,
      goals: UserGoals.fromJson(json['goals'] as Map<String, dynamic>?),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'authProvider': authProvider,
        'age': age,
        'gender': gender,
        'weight': weight,
        'height': height,
        'bmi': bmi,
        'goals': goals.toJson(),
      };

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? authProvider,
    int? age,
    String? gender,
    double? weight,
    double? height,
    double? bmi,
    UserGoals? goals,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      authProvider: authProvider ?? this.authProvider,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      bmi: bmi ?? this.bmi,
      goals: goals ?? this.goals,
    );
  }
}
