import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/branding/branding_cubit.dart';
import '../../../core/branding/branding_model.dart';
import '../../../di.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<BrandingCubit>(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: const SettingsViewContent(),
      ),
    );
  }
}

class SettingsViewContent extends StatefulWidget {
  const SettingsViewContent({super.key});

  @override
  State<SettingsViewContent> createState() => _SettingsViewContentState();
}

class _SettingsViewContentState extends State<SettingsViewContent> {
  late TextEditingController _eventNameController;
  late TextEditingController _locationController;
  late TextEditingController _yearController;
  late TextEditingController _flagController;

  @override
  void initState() {
    super.initState();
    final state = context.read<BrandingCubit>().state;
    _eventNameController = TextEditingController(text: state.eventName);
    _locationController = TextEditingController(text: state.location);
    _yearController = TextEditingController(text: state.year);
    _flagController = TextEditingController(text: state.flag);
  }

  @override
  void dispose() {
    _eventNameController.dispose();
    _locationController.dispose();
    _yearController.dispose();
    _flagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BrandingCubit, BrandingConfig>(
      builder: (context, state) {
        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            SwitchListTile(
              title: const Text('Enable Event Mode'),
              subtitle: const Text('Customize branding for specific events'),
              value: state.isEventMode,
              onChanged: (value) {
                context.read<BrandingCubit>().toggleEventMode(value);
              },
            ),
            const Divider(),
            if (state.isEventMode) ...[
              const Text('Event Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: _eventNameController,
                decoration: const InputDecoration(
                  labelText: 'Event Name',
                  border: OutlineInputBorder(),
                  helperText: 'e.g., DevFest, Flutter Vikings',
                ),
                onChanged: (value) {
                  context.read<BrandingCubit>().updateEventDetails(eventName: value);
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                  helperText: 'e.g., Konya, Berlin',
                ),
                onChanged: (value) {
                  context.read<BrandingCubit>().updateEventDetails(location: value);
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _yearController,
                decoration: const InputDecoration(labelText: 'Year', border: OutlineInputBorder()),
                onChanged: (value) {
                  context.read<BrandingCubit>().updateEventDetails(year: value);
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _flagController,
                decoration: const InputDecoration(labelText: 'Flag Emoji', border: OutlineInputBorder()),
                onChanged: (value) {
                  context.read<BrandingCubit>().updateEventDetails(flag: value);
                },
              ),
            ],
          ],
        );
      },
    );
  }
}
