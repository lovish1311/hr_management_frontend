import 'dart:async';
import 'dart:convert';
import 'dart:io';

class MockHttpOverrides extends HttpOverrides {
  static void install() {
    HttpOverrides.global = MockHttpOverrides();
  }

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _MockHttpClient();
  }
}

class _MockHttpClient implements HttpClient {
  @override
  bool autoUncompress = true;
  @override
  Duration? connectionTimeout;
  @override
  Duration idleTimeout = const Duration(seconds: 15);
  @override
  int? maxConnectionsPerHost;
  @override
  String? userAgent;

  @override
  set connectionFactory(Future<ConnectionTask<Socket>> Function(Uri url, String? proxyHost, int? proxyPort)? f) {}
  @override
  set keyLog(Function(String line)? callback) {}

  @override
  void addCredentials(Uri url, String realm, HttpClientCredentials credentials) {}

  @override
  void addProxyCredentials(String host, int port, String realm, HttpClientCredentials credentials) {}

  @override
  void close({bool force = false}) {}

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    return _MockHttpClientRequest(method, url);
  }

  @override
  Future<HttpClientRequest> getUrl(Uri url) => openUrl('GET', url);
  @override
  Future<HttpClientRequest> postUrl(Uri url) => openUrl('POST', url);
  @override
  Future<HttpClientRequest> putUrl(Uri url) => openUrl('PUT', url);
  @override
  Future<HttpClientRequest> deleteUrl(Uri url) => openUrl('DELETE', url);
  @override
  Future<HttpClientRequest> patchUrl(Uri url) => openUrl('PATCH', url);
  @override
  Future<HttpClientRequest> headUrl(Uri url) => openUrl('HEAD', url);
  @override
  Future<HttpClientRequest> open(String method, String host, int port, String path) =>
      openUrl(method, Uri(scheme: 'http', host: host, port: port, path: path));
  @override
  Future<HttpClientRequest> get(String host, int port, String path) => open('GET', host, port, path);
  @override
  Future<HttpClientRequest> post(String host, int port, String path) => open('POST', host, port, path);
  @override
  Future<HttpClientRequest> put(String host, int port, String path) => open('PUT', host, port, path);
  @override
  Future<HttpClientRequest> delete(String host, int port, String path) => open('DELETE', host, port, path);
  @override
  Future<HttpClientRequest> patch(String host, int port, String path) => open('PATCH', host, port, path);
  @override
  Future<HttpClientRequest> head(String host, int port, String path) => open('HEAD', host, port, path);

  @override
  set authenticate(Future<bool> Function(Uri url, String scheme, String? realm)? f) {}
  @override
  set authenticateProxy(Future<bool> Function(String host, int port, String scheme, String? realm)? f) {}
  @override
  set badCertificateCallback(bool Function(X509Certificate cert, String host, int port)? callback) {}
  @override
  set findProxy(String Function(Uri url)? f) {}
}

class _MockHttpClientRequest implements HttpClientRequest {
  final String _method;
  final Uri _url;
  final List<int> _body = [];

  _MockHttpClientRequest(this._method, this._url);

  @override
  String get method => _method;

  @override
  Uri get uri => _url;

  @override
  bool bufferOutput = true;
  @override
  int contentLength = -1;
  @override
  Encoding encoding = utf8;
  @override
  bool followRedirects = true;
  @override
  int maxRedirects = 5;
  @override
  bool persistentConnection = true;

  @override
  final HttpHeaders headers = _MockHttpHeaders();

  @override
  void add(List<int> data) {
    _body.addAll(data);
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future addStream(Stream<List<int>> stream) async {
    await for (final data in stream) {
      _body.addAll(data);
    }
  }

  @override
  Future<HttpClientResponse> close() async {
    return _MockHttpClientResponse(_url);
  }

  @override
  HttpConnectionInfo? get connectionInfo => null;
  @override
  List<Cookie> get cookies => [];
  @override
  Future<HttpClientResponse> get done => close();
  @override
  Future flush() async {}
  @override
  void write(Object? object) {
    if (object != null) _body.addAll(utf8.encode(object.toString()));
  }
  @override
  void writeAll(Iterable objects, [String separator = ""]) {
    write(objects.join(separator));
  }
  @override
  void writeCharCode(int charCode) {
    _body.add(charCode);
  }
  @override
  void writeln([Object? object = ""]) {
    write('$object\n');
  }
  @override
  void abort([Object? exception, StackTrace? stackTrace]) {}
}

class _MockHttpHeaders implements HttpHeaders {
  final Map<String, List<String>> _headers = {};

  @override
  List<String>? operator [](String name) => _headers[name.toLowerCase()];

  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {
    _headers.putIfAbsent(name.toLowerCase(), () => []).add(value.toString());
  }

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    _headers[name.toLowerCase()] = [value.toString()];
  }

  @override
  void remove(String name, Object value) {
    _headers[name.toLowerCase()]?.remove(value.toString());
  }

  @override
  void removeAll(String name) {
    _headers.remove(name.toLowerCase());
  }

  @override
  void forEach(void Function(String name, List<String> values) action) {
    _headers.forEach(action);
  }

  @override
  void noSuchMethod(Invocation invocation) {}
}

class _MockHttpClientResponse extends Stream<List<int>> implements HttpClientResponse {
  final Uri _url;

  _MockHttpClientResponse(this._url);

  @override
  int get statusCode => 200;

  @override
  bool get isRedirect => false;

  @override
  bool get persistentConnection => false;

  @override
  List<RedirectInfo> get redirects => [];

  @override
  String get reasonPhrase => 'OK';

  @override
  int get contentLength => _responseBytes.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  final HttpHeaders headers = _MockHttpHeaders();

  List<int> get _responseBytes {
    final path = _url.path;
    String jsonStr = '{}';

    if (path.contains('/api/v1/dashboard')) {
      jsonStr = json.encode({
        'totalEmployees': 18,
        'presentToday': 16,
        'onLeaveToday': 2,
        'pendingLeaves': [
          {
            'id': 101,
            'employeeName': 'Rahul Sharma',
            'leaveType': 'CASUAL_LEAVE',
            'startDate': '2026-09-28',
            'endDate': '2026-09-29',
            'reason': 'Family function attendance',
            'status': 'PENDING'
          }
        ]
      });
    } else if (path.contains('/api/v1/employees/search') || path.endsWith('/api/v1/employees')) {
      jsonStr = json.encode({
        'content': [
          {
            'id': 1,
            'firstName': 'Ankesh',
            'lastName': 'Verma',
            'email': 'ankesh.verma@example.com',
            'department': 'Engineering',
            'role': 'Director',
            'designation': 'Executive Director',
            'status': 'ACTIVE',
            'isProbation': false,
            'isNoticePeriod': false,
            'starred': false
          },
          {
            'id': 2,
            'firstName': 'Priya',
            'lastName': 'Sharma',
            'email': 'priya.s@example.com',
            'department': 'Design',
            'role': 'UI/UX Lead',
            'designation': 'Lead Designer',
            'status': 'ACTIVE',
            'isProbation': true,
            'probationDurationMonths': 3,
            'isNoticePeriod': false,
            'starred': true
          }
        ],
        'totalElements': 2,
        'totalPages': 1,
        'size': 20,
        'number': 0
      });
    } else if (path.contains('/api/v1/holidays/calendar') || path.contains('/api/v1/holidays/list')) {
      jsonStr = json.encode({
        'id': 1,
        'year': 2026,
        'published': true,
        'rhAllowed': 2,
        'rhUsed': 0,
        'holidays': [
          {
            'id': 1,
            'name': 'Republic Day',
            'date': '2026-01-26',
            'type': 'GENERAL',
            'description': 'National Holiday'
          },
          {
            'id': 2,
            'name': 'Maha Shivratri',
            'date': '2026-02-15',
            'type': 'RESTRICTED',
            'description': 'Restricted optional holiday'
          }
        ]
      });
    } else if (path.contains('/api/v1/holidays')) {
      jsonStr = json.encode([
        {
          'id': 1,
          'name': 'Republic Day',
          'date': '2026-01-26',
          'type': 'GENERAL',
          'description': 'National Holiday'
        }
      ]);
    } else if (path.contains('/api/v1/leaves')) {
      jsonStr = json.encode([
        {
          'id': 201,
          'employeeName': 'Rahul Sharma',
          'leaveType': 'CASUAL_LEAVE',
          'startDate': '2026-09-28',
          'endDate': '2026-09-29',
          'reason': 'Attending sibling wedding ceremony in home town',
          'status': 'PENDING'
        }
      ]);
    } else if (path.contains('/api/v1/attendance')) {
      jsonStr = json.encode({
        'weeklyHours': 40.0,
        'paidLeaveCount': 2,
        'lopCount': 0,
        'holidayCount': 1,
        'records': []
      });
    } else if (path.contains('/api/v1/tambola')) {
      jsonStr = json.encode([
        {
          'id': 'room-101',
          'roomCode': 'TAMB88',
          'title': 'Friday Fun Tambola',
          'status': 'WAITING',
          'players': ['Ankesh', 'Priya']
        }
      ]);
    } else if (path.contains('/api/v1/auth/login')) {
      jsonStr = json.encode({
        'token': 'mock-jwt-token-12345',
        'email': 'admin@hrportal.com',
        'role': 'ROLE_SUPER_ADMIN',
        'employeeId': 1
      });
    } else {
      jsonStr = json.encode([]);
    }

    return utf8.encode(jsonStr);
  }

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream.value(_responseBytes).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  void noSuchMethod(Invocation invocation) {}
}
