import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payparse/features/company_profile/data/company_repository.dart';
import 'package:payparse/features/company_profile/domain/company_model.dart';

final companyRepositoryProvider = Provider((ref) => CompanyRepository());

/// Provides the current company profile state.
final companyProfileProvider =
    StateNotifierProvider<CompanyProfileNotifier, CompanyProfile?>(
  (ref) => CompanyProfileNotifier(ref),
);

class CompanyProfileNotifier extends StateNotifier<CompanyProfile?> {
  final Ref _ref;

  CompanyProfileNotifier(this._ref) : super(null) {
    _loadProfile();
  }

  void _loadProfile() {
    final repo = _ref.read(companyRepositoryProvider);
    state = repo.getProfile();
  }

  Future<void> saveProfile(CompanyProfile profile) async {
    final repo = _ref.read(companyRepositoryProvider);
    await repo.saveProfile(profile);
    state = profile;
  }

  Future<String> saveLogo(File file) async {
    final repo = _ref.read(companyRepositoryProvider);
    return repo.saveLogoFile(file);
  }

  bool get hasProfile => state != null;
}
