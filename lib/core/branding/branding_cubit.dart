import 'package:flutter_bloc/flutter_bloc.dart';

import 'branding_model.dart';
import 'branding_repository.dart';

class BrandingCubit extends Cubit<BrandingConfig> {
  BrandingCubit({required BrandingRepository repository}) : _repository = repository, super(const BrandingConfig());

  final BrandingRepository _repository;

  Future<void> load() async {
    final config = await _repository.load();
    if (!isClosed) emit(config);
  }

  Future<void> toggleEventMode(bool enabled) => _update(state.copyWith(isEventMode: enabled));

  /// An empty [flag] removes it.
  Future<void> updateEventDetails({String? eventName, String? location, String? year, String? flag}) {
    return _update(
      state.copyWith(
        eventName: eventName,
        location: location,
        year: year,
        flag: flag == null ? null : () => flag.trim().isEmpty ? null : flag.trim(),
      ),
    );
  }

  Future<void> _update(BrandingConfig config) async {
    emit(config);
    await _repository.save(config);
  }
}
