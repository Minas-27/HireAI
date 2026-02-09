class CompanyProfile {
  final String name;
  final String industry;
  final String location;
  final String website;
  final String about;
  final String email;
  final String phone;

  CompanyProfile({
    required this.name,
    required this.industry,
    required this.location,
    required this.website,
    required this.about,
    required this.email,
    required this.phone,
  });

  // Default factory for new users
  factory CompanyProfile.defaultProfile() {
    return CompanyProfile(
      name: 'TechCorp Africa',
      industry: 'Technology',
      location: 'Addis Ababa, Ethiopia',
      website: 'www.techcorp.africa',
      about:
          'Leading the digital revolution in Africa with innovative software solutions.',
      email: 'hr@techcorp.africa',
      phone: '+251 911 234 567',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'industry': industry,
      'location': location,
      'website': website,
      'about': about,
      'email': email,
      'phone': phone,
    };
  }

  factory CompanyProfile.fromJson(Map<String, dynamic> json) {
    return CompanyProfile(
      name: json['name'] ?? '',
      industry: json['industry'] ?? '',
      location: json['location'] ?? '',
      website: json['website'] ?? '',
      about: json['about'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
    );
  }

  CompanyProfile copyWith({
    String? name,
    String? industry,
    String? location,
    String? website,
    String? about,
    String? email,
    String? phone,
  }) {
    return CompanyProfile(
      name: name ?? this.name,
      industry: industry ?? this.industry,
      location: location ?? this.location,
      website: website ?? this.website,
      about: about ?? this.about,
      email: email ?? this.email,
      phone: phone ?? this.phone,
    );
  }
}
