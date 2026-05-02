// Creates Supabase Auth accounts for all existing users via Admin API.
// Usage: dart run bin/create_auth_users.dart <SERVICE_ROLE_KEY>
// Get key: https://supabase.com/dashboard/project/pzmyfchyzowlkufqabva/settings/api

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

const _projectUrl = 'https://pzmyfchyzowlkufqabva.supabase.co';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: dart run bin/create_auth_users.dart <SERVICE_ROLE_KEY>');
    print('Get it from: Supabase Dashboard → Settings → API → service_role key');
    exit(1);
  }

  final serviceKey = args[0];
  final headers = {
    'apikey': serviceKey,
    'Authorization': 'Bearer $serviceKey',
    'Content-Type': 'application/json',
  };

  // 1. Fetch all users without auth accounts
  print('Fetching users...');
  final usersRes = await http.get(
    Uri.parse('$_projectUrl/rest/v1/users?select=id,email,password&auth_user_id=is.null'),
    headers: headers,
  );

  if (usersRes.statusCode != 200) {
    print('Failed to fetch users: ${usersRes.body}');
    exit(1);
  }

  final users = jsonDecode(usersRes.body) as List;
  print('Found ${users.length} users to process\n');

  int created = 0;
  int failed = 0;

  for (final user in users) {
    final email    = user['email'] as String?;
    final password = user['password'] as String?;
    final userId   = user['id'];

    if (email == null || password == null) {
      print('⚠️  Skipping id=$userId — missing email or password');
      failed++;
      continue;
    }

    // 2. Create auth user via Admin API
    final createRes = await http.post(
      Uri.parse('$_projectUrl/auth/v1/admin/users'),
      headers: headers,
      body: jsonEncode({
        'email': email,
        'password': password,
        'email_confirm': true,
      }),
    );

    if (createRes.statusCode != 200 && createRes.statusCode != 201) {
      print('❌ $email — ${jsonDecode(createRes.body)['msg'] ?? createRes.body}');
      failed++;
      continue;
    }

    final authId = jsonDecode(createRes.body)['id'] as String?;
    if (authId == null) {
      print('❌ $email — no auth ID returned');
      failed++;
      continue;
    }

    // 3. Link auth_user_id back to users table
    final updateRes = await http.patch(
      Uri.parse('$_projectUrl/rest/v1/users?id=eq.$userId'),
      headers: {
        ...headers,
        'Prefer': 'return=minimal',
      },
      body: jsonEncode({'auth_user_id': authId}),
    );

    if (updateRes.statusCode == 200 || updateRes.statusCode == 204) {
      print('✅ $email');
      created++;
    } else {
      print('⚠️  $email — auth created but failed to link: ${updateRes.body}');
      failed++;
    }
  }

  print('\n─────────────────────────');
  print('✅ Created : $created');
  print('❌ Failed  : $failed');
  print('─────────────────────────');
}
