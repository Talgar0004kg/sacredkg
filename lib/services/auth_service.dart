import 'dart:convert';
import 'dart:math' as math;

import 'package:shared_preferences/shared_preferences.dart';

enum UserRole { admin, agent, user }

class AgentCredentials {
  AgentCredentials({
    required this.email,
    required this.password,
    required this.createdAt,
  });

  final String email;
  final String password;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
    'createdAt': createdAt.toIso8601String(),
  };

  factory AgentCredentials.fromJson(Map<String, dynamic> json) =>
      AgentCredentials(
        email: json['email'] as String,
        password: json['password'] as String,
        createdAt:
            DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
}

/// Hard-coded admin credentials (per spec) and helpers for SharedPreferences-backed
/// role detection, agent management and "view as user" mode.
class AuthService {
  AuthService._();

  static const String adminEmail = 'admin@sacred.kg';
  static const String adminPassword = 'admin2026';

  static const String _kSessionRole = 'auth_role';
  static const String _kSessionEmail = 'auth_email';
  static const String _kSessionName = 'auth_name';
  static const String _kSessionActive = 'auth_session';
  static const String _kAgentsJson = 'auth_agents_json';
  static const String _kAdminViewAsUser = 'auth_admin_view_as_user';

  /// Returns the role that matches the supplied credentials, or null if no
  /// role matches.
  static Future<UserRole?> resolveRole(String email, String password) async {
    final trimmedEmail = email.trim().toLowerCase();
    if (trimmedEmail == adminEmail && password == adminPassword) {
      return UserRole.admin;
    }
    final agents = await getAgents();
    final match = agents.where(
      (a) => a.email.toLowerCase() == trimmedEmail && a.password == password,
    );
    if (match.isNotEmpty) return UserRole.agent;
    // Any other non-empty creds become a regular user.
    if (trimmedEmail.isNotEmpty && password.isNotEmpty) return UserRole.user;
    return null;
  }

  /// Persist a session for the given role + email.
  static Future<void> login({
    required UserRole role,
    required String email,
    String? name,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final displayName = name ?? email.split('@').first;
    await prefs.setBool(_kSessionActive, true);
    await prefs.setString(_kSessionRole, role.name);
    await prefs.setString(_kSessionEmail, email);
    await prefs.setString(_kSessionName, displayName);
    await prefs.setBool(_kAdminViewAsUser, false);
    // Mirror into legacy AuthController keys so HomeScreen/Account screen
    // continue to render the right name/email immediately after login.
    await prefs.setBool('session', true);
    await prefs.setString('email', email);
    await prefs.setString('userName', displayName);
  }

  /// Convenience for the "Login as guest" button: stores a regular USER session.
  static Future<void> loginAsGuest() async {
    await login(
      role: UserRole.user,
      email: 'guest@sacred.kg',
      name: 'Guest',
    );
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSessionActive, false);
    await prefs.remove(_kSessionRole);
    await prefs.remove(_kSessionEmail);
    await prefs.remove(_kSessionName);
    await prefs.setBool(_kAdminViewAsUser, false);
    // Mirror into legacy keys.
    await prefs.setBool('session', false);
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kSessionActive) ?? false;
  }

  static Future<UserRole?> getCurrentRole() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(_kSessionActive) ?? false)) return null;
    final raw = prefs.getString(_kSessionRole);
    if (raw == null) return null;
    return UserRole.values.firstWhere(
      (r) => r.name == raw,
      orElse: () => UserRole.user,
    );
  }

  static Future<({String email, String name})?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(_kSessionActive) ?? false)) return null;
    final email = prefs.getString(_kSessionEmail);
    if (email == null) return null;
    return (
      email: email,
      name: prefs.getString(_kSessionName) ?? email.split('@').first,
    );
  }

  // ---------- Agent management ----------

  /// True if [email] matches an agent currently created by the admin.
  static Future<bool> isKnownAgent(String email) async {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty) return false;
    final agents = await getAgents();
    return agents.any((a) => a.email.toLowerCase() == normalized);
  }

  static Future<List<AgentCredentials>> getAgents() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kAgentsJson);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = json.decode(raw) as List<dynamic>;
      return list
          .map(
            (item) => AgentCredentials.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _saveAgents(List<AgentCredentials> agents) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(agents.map((a) => a.toJson()).toList());
    await prefs.setString(_kAgentsJson, encoded);
  }

  static String _randomPassword([int length = 8]) {
    const chars =
        'abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = math.Random.secure();
    return List.generate(length, (_) => chars[rnd.nextInt(chars.length)]).join();
  }

  static Future<AgentCredentials> createAgent() async {
    final agents = await getAgents();
    final used = agents.map((a) => a.email).toSet();
    final rnd = math.Random.secure();
    String email;
    do {
      final tail = (1000 + rnd.nextInt(9000)).toString();
      email = 'agent_$tail@sacred.kg';
    } while (used.contains(email));

    final agent = AgentCredentials(
      email: email,
      password: _randomPassword(),
      createdAt: DateTime.now(),
    );
    agents.add(agent);
    await _saveAgents(agents);
    return agent;
  }

  static Future<void> deleteAgent(String email) async {
    final agents = await getAgents();
    agents.removeWhere((a) => a.email.toLowerCase() == email.toLowerCase());
    await _saveAgents(agents);
  }

  // ---------- "View as user" toggle for admins ----------

  static Future<bool> isAdminViewingAsUser() async {
    final prefs = await SharedPreferences.getInstance();
    final role = await getCurrentRole();
    if (role != UserRole.admin) return false;
    return prefs.getBool(_kAdminViewAsUser) ?? false;
  }

  static Future<void> setAdminViewAsUser(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAdminViewAsUser, value);
  }
}
