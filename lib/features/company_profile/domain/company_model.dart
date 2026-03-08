class CompanyProfile {
  final String companyName;
  final String address;
  final String phone;
  final String? gstNumber;
  final String? logoPath;
  final String? bankDetails;
  final String? upiId;

  const CompanyProfile({
    required this.companyName,
    required this.address,
    required this.phone,
    this.gstNumber,
    this.logoPath,
    this.bankDetails,
    this.upiId,
  });

  CompanyProfile copyWith({
    String? companyName,
    String? address,
    String? phone,
    String? gstNumber,
    String? logoPath,
    String? bankDetails,
    String? upiId,
  }) {
    return CompanyProfile(
      companyName: companyName ?? this.companyName,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      gstNumber: gstNumber ?? this.gstNumber,
      logoPath: logoPath ?? this.logoPath,
      bankDetails: bankDetails ?? this.bankDetails,
      upiId: upiId ?? this.upiId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'companyName': companyName,
      'address': address,
      'phone': phone,
      'gstNumber': gstNumber,
      'logoPath': logoPath,
      'bankDetails': bankDetails,
      'upiId': upiId,
    };
  }

  factory CompanyProfile.fromMap(Map<String, dynamic> map) {
    return CompanyProfile(
      companyName: map['companyName'] as String? ?? '',
      address: map['address'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      gstNumber: map['gstNumber'] as String?,
      logoPath: map['logoPath'] as String?,
      bankDetails: map['bankDetails'] as String?,
      upiId: map['upiId'] as String?,
    );
  }

  bool get hasLogo => logoPath != null && logoPath!.isNotEmpty;
  bool get hasGst => gstNumber != null && gstNumber!.isNotEmpty;
}
