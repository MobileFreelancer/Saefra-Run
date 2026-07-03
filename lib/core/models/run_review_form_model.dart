enum RunCompanion { noOne, myPet, friend }

enum RunSurface { asphalt, trail, grass, track }

enum RunWeather { sunny, cloudy, rainy, snowy }

class RunReviewFormModel {
  final RunCompanion companion;
  final List<String> environmentTags;
  final String accuracyRating;
  final String runMode;
  final String feedback;
  final List<String> imagePaths;
  final RunSurface? surface;
  final RunWeather? weather;

  const RunReviewFormModel({
    this.companion = RunCompanion.noOne,
    this.environmentTags = const [],
    this.accuracyRating = 'yes',
    this.runMode = 'felt_good',
    this.feedback = '',
    this.imagePaths = const [],
    this.surface,
    this.weather,
  });

  RunReviewFormModel copyWith({
    RunCompanion? companion,
    List<String>? environmentTags,
    String? accuracyRating,
    String? runMode,
    String? feedback,
    List<String>? imagePaths,
    RunSurface? surface,
    RunWeather? weather,
  }) {
    return RunReviewFormModel(
      companion: companion ?? this.companion,
      environmentTags: environmentTags ?? this.environmentTags,
      accuracyRating: accuracyRating ?? this.accuracyRating,
      runMode: runMode ?? this.runMode,
      feedback: feedback ?? this.feedback,
      imagePaths: imagePaths ?? this.imagePaths,
      surface: surface ?? this.surface,
      weather: weather ?? this.weather,
    );
  }

  Map<String, dynamic> toJson() => {
        'who_with': companion.name,
        'environment_tags': environmentTags,
        'accuracy_rating': accuracyRating,
        'run_mode': runMode,
        'feedback': feedback,
        'image_paths': imagePaths,
        if (surface != null) 'surface': surface!.name,
        if (weather != null) 'weather': weather!.name,
      };
}
