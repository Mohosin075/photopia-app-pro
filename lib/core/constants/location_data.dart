class LocationData {
  static const Map<String, List<String>> countriesAndCities = {
    'Germany': [
      'Berlin',
      'Hamburg',
      'Munich',
      'Cologne',
      'Frankfurt',
      'Stuttgart',
      'Düsseldorf',
      'Dortmund',
    ],
    'France': [
      'Paris',
      'Marseille',
      'Lyon',
      'Toulouse',
      'Nice',
      'Nantes',
      'Strasbourg',
      'Montpellier',
    ],
    'Bangladesh': [
      'Dhaka',
      'Chittagong',
      'Sylhet',
      'Rajshahi',
      'Khulna',
      'Barisal',
      'Rangpur',
      'Comilla',
    ],
    'USA': [
      'New York',
      'Los Angeles',
      'Chicago',
      'Houston',
      'Phoenix',
      'Philadelphia',
      'San Antonio',
      'San Diego',
    ],
    'United Kingdom': [
      'London',
      'Birmingham',
      'Manchester',
      'Glasgow',
      'Liverpool',
      'Newcastle',
      'Sheffield',
      'Bristol',
    ],
  };

  static List<String> get countries => countriesAndCities.keys.toList()..sort();

  static List<String> getCities(String country) {
    return countriesAndCities[country] ?? [];
  }
}
