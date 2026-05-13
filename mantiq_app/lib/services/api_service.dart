import 'dart:convert';
import 'package:http/http.dart' as http;

// Im Simulator: localhost, auf echtem Geraet: IP des Homelab-Servers
const String baseUrl = 'http://192.168.178.163:8080';

class ApiService {

  // ── Auth ──────────────────────────────────────────

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    return {'ok': res.statusCode == 200, 'data': jsonDecode(res.body)};
  }

  static Future<Map<String, dynamic>> register(
      String email, String password, String firstName, String lastName) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email, 'password': password,
        'firstName': firstName, 'lastName': lastName,
      }),
    );
    return {'ok': res.statusCode == 200, 'data': jsonDecode(res.body)};
  }

  // ── Nutzer / Einstellungen ────────────────────────

  static Future<Map<String, dynamic>?> getUser(int userId) async {
    final res = await http.get(Uri.parse('$baseUrl/api/users/$userId'));
    if (res.statusCode == 200) return jsonDecode(res.body);
    return null;
  }

  static Future<List<dynamic>> searchUsers(String q, int userId) async {
    final res = await http.get(
        Uri.parse('$baseUrl/api/users/search?q=${Uri.encodeComponent(q)}&userId=$userId'));
    if (res.statusCode == 200) return jsonDecode(res.body);
    return [];
  }

  static Future<Map<String, dynamic>> updateDisplayName(int userId, String name) async {
    final res = await http.put(
      Uri.parse('$baseUrl/api/users/$userId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'displayName': name}),
    );
    return {'ok': res.statusCode == 200, 'data': jsonDecode(res.body)};
  }

  static Future<bool> resetProgress(int userId) async {
    final res = await http.delete(Uri.parse('$baseUrl/api/users/$userId/progress'));
    return res.statusCode == 200;
  }

  // ── Baeume ────────────────────────────────────────

  static Future<List<dynamic>> getTrees(int userId) async {
    final res = await http.get(Uri.parse('$baseUrl/api/trees?userId=$userId'));
    if (res.statusCode == 200) return jsonDecode(res.body);
    return [];
  }

  static Future<Map<String, dynamic>?> getTree(int treeId, int userId) async {
    final res = await http.get(Uri.parse('$baseUrl/api/trees/$treeId?userId=$userId'));
    if (res.statusCode == 200) return jsonDecode(res.body);
    return null;
  }

  static Future<Map<String, dynamic>> createTree(int userId, String title, String description) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/trees'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId, 'title': title, 'description': description}),
    );
    return {'ok': res.statusCode == 200, 'data': jsonDecode(res.body)};
  }

  static Future<bool> updateTree(int treeId, String title, String description) async {
    final res = await http.put(
      Uri.parse('$baseUrl/api/trees/$treeId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'title': title, 'description': description}),
    );
    return res.statusCode == 200;
  }

  static Future<bool> deleteTree(int treeId) async {
    final res = await http.delete(Uri.parse('$baseUrl/api/trees/$treeId'));
    return res.statusCode == 204;
  }

  // ── Schritte ──────────────────────────────────────

  static Future<Map<String, dynamic>> addStep(int treeId, String title) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/trees/$treeId/steps'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'title': title}),
    );
    return {'ok': res.statusCode == 200, 'data': jsonDecode(res.body)};
  }

  static Future<bool> deleteStep(int stepId) async {
    final res = await http.delete(Uri.parse('$baseUrl/api/steps/$stepId'));
    return res.statusCode == 204;
  }

  static Future<bool> renameStep(int stepId, String title) async {
    final res = await http.put(
      Uri.parse('$baseUrl/api/steps/$stepId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'title': title}),
    );
    return res.statusCode == 200;
  }

  static Future<bool> reorderSteps(int treeId, List<Map<String, int>> order) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/trees/$treeId/steps/reorder'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(order),
    );
    return res.statusCode == 200;
  }

  // ── Aufgaben ──────────────────────────────────────

  static Future<List<dynamic>> getStepTasks(int stepId) async {
    final res = await http.get(Uri.parse('$baseUrl/api/steps/$stepId/tasks'));
    if (res.statusCode == 200) return jsonDecode(res.body);
    return [];
  }

  static Future<Map<String, dynamic>> completeStep(int stepId, int userId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/steps/$stepId/complete'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId}),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    return {};
  }

  // ── PDF Upload ────────────────────────────────────

  static Future<Map<String, dynamic>> uploadPdf(
      String filePath, int userId, String titel) async {
    final request = http.MultipartRequest(
      'POST', Uri.parse('$baseUrl/api/pdf/upload'),
    );
    request.files.add(await http.MultipartFile.fromPath('datei', filePath));
    request.fields['userId'] = userId.toString();
    request.fields['titel']  = titel;

    final streamed = await request.send();
    final res      = await http.Response.fromStream(streamed);
    return {'ok': res.statusCode == 200, 'data': jsonDecode(res.body)};
  }

  // ── Freunde ───────────────────────────────────────

  static Future<List<dynamic>> getFriends(int userId) async {
    final res = await http.get(Uri.parse('$baseUrl/api/friends?userId=$userId'));
    if (res.statusCode == 200) return jsonDecode(res.body);
    return [];
  }

  static Future<List<dynamic>> getFriendRequests(int userId) async {
    final res = await http.get(Uri.parse('$baseUrl/api/friends/requests?userId=$userId'));
    if (res.statusCode == 200) return jsonDecode(res.body);
    return [];
  }

  static Future<Map<String, dynamic>> sendFriendRequest(int fromUserId, String toEmail) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/friends/request'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'fromUserId': fromUserId, 'toEmail': toEmail}),
    );
    return {'ok': res.statusCode == 200, 'data': jsonDecode(res.body)};
  }

  static Future<bool> acceptFriendRequest(int requestId) async {
    final res = await http.post(Uri.parse('$baseUrl/api/friends/$requestId/accept'));
    return res.statusCode == 200;
  }

  static Future<bool> removeFriend(int friendshipId) async {
    final res = await http.delete(Uri.parse('$baseUrl/api/friends/$friendshipId'));
    return res.statusCode == 204;
  }

  // ── Leaderboard ───────────────────────────────────

  static Future<Map<String, dynamic>?> getLeaderboard(int userId) async {
    final res = await http.get(Uri.parse('$baseUrl/api/leaderboard?userId=$userId'));
    if (res.statusCode == 200) return jsonDecode(res.body);
    return null;
  }

  // ── Shop ──────────────────────────────────────────

  static Future<List<dynamic>> getShopItems() async {
    final res = await http.get(Uri.parse('$baseUrl/api/shop/items'));
    if (res.statusCode == 200) return jsonDecode(res.body);
    return [];
  }

  static Future<List<dynamic>> getInventory(int userId) async {
    final res = await http.get(Uri.parse('$baseUrl/api/shop/inventory?userId=$userId'));
    if (res.statusCode == 200) return jsonDecode(res.body);
    return [];
  }

  static Future<Map<String, dynamic>> buyItem(int userId, int itemId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/shop/buy'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId, 'itemId': itemId}),
    );
    return {'ok': res.statusCode == 200, 'data': jsonDecode(res.body)};
  }

  static Future<Map<String, dynamic>> useItem(int userId, int itemId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/shop/use'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId, 'itemId': itemId}),
    );
    return {'ok': res.statusCode == 200, 'data': jsonDecode(res.body)};
  }

  // ── Gruppen ───────────────────────────────────────

  static Future<List<dynamic>> getMyGroups(int userId) async {
    final res = await http.get(Uri.parse('$baseUrl/api/groups?userId=$userId'));
    if (res.statusCode == 200) return jsonDecode(res.body);
    return [];
  }

  static Future<List<dynamic>> searchGroups(String q, int userId) async {
    final res = await http.get(
        Uri.parse('$baseUrl/api/groups/search?q=${Uri.encodeComponent(q)}&userId=$userId'));
    if (res.statusCode == 200) return jsonDecode(res.body);
    return [];
  }

  static Future<Map<String, dynamic>> createGroup(
      int userId, String name, String type, String description) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/groups'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId, 'name': name, 'groupType': type, 'description': description}),
    );
    return {'ok': res.statusCode == 200, 'data': jsonDecode(res.body)};
  }

  static Future<Map<String, dynamic>> joinGroup(int userId, String inviteCode) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/groups/join'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId, 'inviteCode': inviteCode}),
    );
    return {'ok': res.statusCode == 200, 'data': jsonDecode(res.body)};
  }

  static Future<bool> leaveGroup(int groupId, int userId) async {
    final res = await http.delete(
        Uri.parse('$baseUrl/api/groups/$groupId/leave?userId=$userId'));
    return res.statusCode == 204;
  }

  static Future<List<dynamic>> getGroupTrees(int groupId) async {
    final res = await http.get(Uri.parse('$baseUrl/api/groups/$groupId/trees'));
    if (res.statusCode == 200) return jsonDecode(res.body);
    return [];
  }

  static Future<Map<String, dynamic>> shareTreeWithGroup(
      int groupId, int userId, int treeId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/groups/$groupId/trees'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId, 'treeId': treeId}),
    );
    return {'ok': res.statusCode == 200, 'data': jsonDecode(res.body)};
  }

  // ── Teilen ────────────────────────────────────────

  static Future<Map<String, dynamic>?> generateShareCode(int treeId, int userId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/shares/generate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'treeId': treeId, 'userId': userId}),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    return null;
  }

  static Future<Map<String, dynamic>?> getSharePreview(String code) async {
    final res = await http.get(Uri.parse('$baseUrl/api/shares/${code.toUpperCase()}'));
    if (res.statusCode == 200) return jsonDecode(res.body);
    return null;
  }

  static Future<Map<String, dynamic>> importByCode(String code, int userId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/shares/${code.toUpperCase()}/import'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId}),
    );
    return {'ok': res.statusCode == 200, 'data': jsonDecode(res.body)};
  }

  static Future<Map<String, dynamic>?> exportTree(int treeId) async {
    final res = await http.get(Uri.parse('$baseUrl/api/shares/export/$treeId'));
    if (res.statusCode == 200) return jsonDecode(res.body);
    return null;
  }

  static Future<Map<String, dynamic>> importFile(int userId, Map<String, dynamic> tree) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/shares/import-file'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId, 'tree': tree}),
    );
    return {'ok': res.statusCode == 200, 'data': jsonDecode(res.body)};
  }

  // ── Version ───────────────────────────────────────

  static Future<Map<String, dynamic>?> getServerVersion() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/version'))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (_) {}
    return null;
  }

  // ── Abo ───────────────────────────────────────────

  static Future<Map<String, dynamic>?> getSubscription(int userId) async {
    final res = await http.get(Uri.parse('$baseUrl/api/subscription?userId=$userId'));
    if (res.statusCode == 200) return jsonDecode(res.body);
    return null;
  }

  static Future<Map<String, dynamic>> upgradeSubscription() async {
    final res = await http.post(Uri.parse('$baseUrl/api/subscription/upgrade'));
    return {'ok': res.statusCode == 200, 'data': jsonDecode(res.body)};
  }
}
