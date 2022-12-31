import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../models/profile.dart';
import '../../../utils/constants.dart';
import '../../../utils/shared_preferences_util.dart';
import '../../../utils/storage_utils.dart';
import '../../../utils/theme.dart';

class ProfilesPage extends StatefulWidget {
  const ProfilesPage({super.key});

  @override
  State<ProfilesPage> createState() => _ProfilesPageState();
}

class _ProfilesPageState extends State<ProfilesPage> {
  int groupValue = 0;

  final _profileNameController = TextEditingController();
  final _profileNameFormKey = GlobalKey<FormState>();

  final mainColor = ThemeService().isDarkTheme() ? AppColors.dark : AppColors.light;

  List<Profile> profiles = [];

  @override
  void initState() {
    super.initState();
    validateProfileList();
    setSelectedProfileIndex();
  }

  void validateProfileList() {
    // Get profiles from persistence
    List<String>? storedProfiles = SharedPrefsUtil.getStringList('profiles');

    if (storedProfiles == null || storedProfiles.isEmpty) {
      // Add the default profile to storage
      storedProfiles = ['Default'];
      SharedPrefsUtil.putStringList('profiles', storedProfiles);
    }

    // Check if the 'Default' profile already exists in storage, otherwise add it
    if (!storedProfiles.contains('Default')) {
      profiles.insert(
        0,
        const Profile(label: 'Default', isDefault: true),
      );
    } else {
      profiles = storedProfiles.map(
        (e) {
          if (e == 'Default') return Profile(label: e, isDefault: true);
          return Profile(label: e);
        },
      ).toList();
    }

    print('Stored Profiles are: $storedProfiles');
  }

  void setSelectedProfileIndex() {
    groupValue = SharedPrefsUtil.getInt('selectedProfileIndex') ?? 0;
  }

  Future<void> _addNewProfileDialog() async {
    return await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Form(
          key: _profileNameFormKey,
          child: AlertDialog(
            title: Text('newProfile'.tr),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'newProfileTooltip'.tr,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _profileNameController,
                  cursorColor: Colors.green,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(45),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'profileNameCannotBeEmpty'.tr;
                    }

                    if (value.toLowerCase() == 'default') {
                      return 'reservedProfileName'.tr;
                    }

                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: 'enterProfileName'.tr,
                    errorStyle: const TextStyle(
                      color: AppColors.mainColor,
                    ),
                    border: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.green),
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: mainColor),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.green),
                    ),
                    focusedErrorBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.mainColor),
                    ),
                    errorBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.mainColor),
                    ),
                  ),
                )
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  // Checks if the textfield is valid based on if the text passes all the validations we set
                  final bool isTextValid =
                      _profileNameFormKey.currentState?.validate() ?? false;

                  if (isTextValid) {
                    // Create the profile directory for the new profile
                    await StorageUtils.createSpecificProfileFolder(
                      _profileNameController.text,
                    );

                    // Add the new profile to the end of the list
                    setState(() {
                      profiles.insert(
                        profiles.length,
                        Profile(label: _profileNameController.text),
                      );
                      _profileNameController.clear();
                    });

                    // Add the modified profile list to persistence
                    final profileNamesToStringList = profiles.map((e) => e.label).toList();
                    SharedPrefsUtil.putStringList('profiles', profileNamesToStringList);

                    Navigator.pop(context);
                  }
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.green,
                ),
                child: Text('done'.tr),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showdeleteProfileDialog(int index) async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('deleteProfile'.tr),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'deleteProfileTooltip'.tr,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: ThemeService().isDarkTheme() ? AppColors.light : AppColors.dark,
            ),
            child: Text('no'.tr),
          ),
          TextButton(
            onPressed: () async {
              // Delete the profile directory for the specific profile
              await StorageUtils.deleteSpecificProfileFolder(
                profiles[index].label,
              );

              // Remove the profile from the list
              setState(() {
                profiles.removeAt(index);
              });

              // Update the profile list in persistence
              final profileNamesToStringList = profiles.map((e) => e.label).toList();
              SharedPrefsUtil.putStringList('profiles', profileNamesToStringList);

              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: Text('yes'.tr),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'profiles'.tr,
          style: TextStyle(
            fontFamily: 'Magic',
            fontSize: MediaQuery.of(context).size.width * 0.05,
          ),
        ),
      ),
      body: Center(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.82,
          child: Column(
            children: [
              Text(
                'tapToSwitch'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width * 0.035,
                ),
              ),
              const SizedBox(height: 15),
              Expanded(
                child: ListView.separated(
                  itemCount: profiles.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return Material(
                      child: RadioListTile(
                        value: index,
                        groupValue: groupValue,
                        onChanged: (val) {
                          if (val == null) return;

                          // Set index in UI
                          setState(() {
                            groupValue = val;
                          });

                          // Set index in persistence
                          SharedPrefsUtil.putInt('selectedProfileIndex', val);
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        title: Text(profiles[index].label),
                        secondary: profiles[index].isDefault
                            ? null
                            : IconButton(
                                onPressed: () async {
                                  await _showdeleteProfileDialog(index);
                                },
                                icon: const Icon(
                                  Icons.delete,
                                  color: AppColors.mainColor,
                                ),
                              ),
                      ),
                    );
                  },
                ),
              ),
              TextButton.icon(
                onPressed: () async {
                  await _addNewProfileDialog();
                },
                icon: const Icon(Icons.add),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.mainColor,
                ),
                label: Text('createNewProfile'.tr),
              )
            ],
          ),
        ),
      ),
    );
  }
}