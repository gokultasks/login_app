import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DraftStorage {
  final SharedPreferences prefs;
  static const String draftKey = 'draft_item_form';

  DraftStorage({required this.prefs});

  
  Future<void> saveDraft(Map<String, dynamic> formData) async {
    try {
      final jsonString = jsonEncode(formData);
      await prefs.setString(draftKey, jsonString);
    } catch (e) {
      throw Exception('Failed to save draft: $e');
    }
  }


  Future<Map<String, dynamic>?> loadDraft() async {
    try {
      final jsonString = prefs.getString(draftKey);
      if (jsonString == null) return null;
      
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }


  Future<void> clearDraft() async {
    await prefs.remove(draftKey);
  }


  bool hasDraft() {
    return prefs.containsKey(draftKey);
  }
}
