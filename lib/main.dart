import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_isolated_worker_fetch_example/core/http_service.dart';

import 'models/user.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IsolatedWorker Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const String _targetUrl = 'https://jsonplaceholder.typicode.com/users';
  final HttpService _httpService = HttpService();

  List<User>? _users;
  Object? _error;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });
    _users = null;
    _error = null;
    try {
      final List<User> fetchedUsers = await _fetchUsers();
      setState(() {
        _isLoading = false;
        _users = fetchedUsers;
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
        _error = error;
      });
    }
  }

  Future<List<User>> _fetchUsers() async {
    final LinkedHashMap<dynamic, dynamic> responseMap = await _httpService.get(_targetUrl);
    final Object? error = responseMap['err'];
    if (error != null) {
      throw error;
    }
    final List<dynamic> jsonResponse = responseMap['jsonResponse'];
    final List<User> users = jsonResponse.map<User>((dynamic raw) {
      return User.fromMap(raw);
    }).toList();
    return users;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IsolatedWorker fetch example'),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _currentState,
      ),
    );
  }

  Widget get _currentState {
    if (_isLoading) {
      return const LoadingIndicator();
    }
    if (_error != null) {
      return ErrorText(
        error: _error!,
        onRefresh: _refresh,
      );
    }
    return UserList(users: _users!);
  }
}

class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(child: CupertinoActivityIndicator());
  }
}

class ErrorText extends StatelessWidget {
  const ErrorText({
    Key? key,
    required this.error,
    required this.onRefresh,
  }) : super(key: key);

  final Object error;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(error.toString()),
          TextButton(
            onPressed: onRefresh,
            child: const Text('Reload'),
          ),
        ],
      ),
    );
  }
}

class UserList extends StatelessWidget {
  const UserList({
    Key? key,
    required this.users,
  }) : super(key: key);

  final List<User> users;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemBuilder: (_, index) {
        return UserListTile(user: users[index]);
      },
      itemCount: users.length,
    );
  }
}

class UserListTile extends StatelessWidget {
  const UserListTile({
    Key? key,
    required this.user,
  }) : super(key: key);

  final User user;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(),
        Text(user.name),
        Text(user.username),
        Text(user.phone),
        Text(user.email),
        Text(user.website),
        const Divider(),
      ],
    );
  }
}
