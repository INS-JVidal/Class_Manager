# MongoDB Atlas with Dart/Flutter

A guide for connecting Dart and Flutter applications to MongoDB Atlas using the `mongo_dart` package.

---

## Table of Contents

- [Critical: SRV Connection Issue](#critical-srv-connection-issue)
- [Prerequisites](#prerequisites)
- [Atlas Setup](#atlas-setup)
- [Connection String Format](#connection-string-format)
- [Dart Implementation](#dart-implementation)
- [Environment Configuration](#environment-configuration)
- [TLS/SSL Security](#tlsssl-security)
- [Troubleshooting](#troubleshooting)
- [Testing Connection](#testing-connection)

---

## Critical: SRV Connection Issue

> **The `mongo_dart` package does NOT properly support `mongodb+srv://` connection strings.**

When using the standard Atlas connection string format (`mongodb+srv://`), you will encounter TLS handshake errors:

```
HandshakeException: Handshake error in client (OS Error: WRONG_VERSION_NUMBER)
```

### The Solution

Use the **direct replica set connection string** instead of the SRV format:

| Format | Supported | Example |
|--------|-----------|---------|
| `mongodb+srv://` | **NO** | `mongodb+srv://user:pass@cluster.mongodb.net/db` |
| `mongodb://` (direct) | **YES** | `mongodb://user:pass@shard0:27017,shard1:27017/db?tls=true` |

---

## Prerequisites

### 1. Add mongo_dart to pubspec.yaml

```yaml
dependencies:
  mongo_dart: ^0.10.3  # or latest version
  flutter_dotenv: ^5.1.0  # for environment variables
```

### 2. MongoDB Atlas Account

- Create account at [cloud.mongodb.com](https://cloud.mongodb.com)
- Deploy a cluster (M0 free tier is sufficient)

---

## Atlas Setup

### Step 1: Create Database User

1. Navigate to **Database Access** in Atlas sidebar
2. Click **Add New Database User**
3. Configure:
   - **Authentication**: Password
   - **Username**: your_app_user
   - **Password**: Generate a strong password
   - **Role**: `readWrite` on your database
4. Save the user

### Step 2: Configure Network Access

1. Navigate to **Network Access** in Atlas sidebar
2. Click **Add IP Address**
3. Options:
   - **Development/Desktop apps**: Add `0.0.0.0/0` (allow from anywhere)
   - **Production servers**: Add specific server IP addresses

> **Note**: For Flutter desktop apps with dynamic IPs, `0.0.0.0/0` combined with strong password authentication is acceptable.

### Step 3: Get Connection Details

1. Navigate to **Database** > **Connect**
2. Select **Drivers**
3. Note down:
   - **Replica set hosts** (3 shard addresses)
   - **Replica set name** (e.g., `atlas-abc123-shard-0`)
   - **Database name**

The hosts will look like:
```
ac-xxxxx-shard-00-00.xxxxx.mongodb.net:27017
ac-xxxxx-shard-00-01.xxxxx.mongodb.net:27017
ac-xxxxx-shard-00-02.xxxxx.mongodb.net:27017
```

---

## Connection String Format

### Standard Atlas Format (NOT SUPPORTED by mongo_dart)

```
mongodb+srv://username:password@cluster.xxxxx.mongodb.net/database
```

### Required Format for mongo_dart

```
mongodb://USERNAME:PASSWORD@HOST1:27017,HOST2:27017,HOST3:27017/DATABASE?tls=true&replicaSet=REPLICA_SET_NAME&authSource=admin&retryWrites=true&w=majority
```

### Complete Example

```
mongodb://myuser:MyP%40ssword@ac-m0kawqe-shard-00-00.utqeme2.mongodb.net:27017,ac-m0kawqe-shard-00-01.utqeme2.mongodb.net:27017,ac-m0kawqe-shard-00-02.utqeme2.mongodb.net:27017/mydb?tls=true&replicaSet=atlas-jrqqt0-shard-0&authSource=admin&retryWrites=true&w=majority
```

### Connection String Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `tls=true` | **Yes** | Enables TLS encryption (Atlas requires this) |
| `replicaSet` | **Yes** | Atlas replica set name |
| `authSource=admin` | **Yes** | Authentication database |
| `retryWrites=true` | Recommended | Auto-retry failed writes |
| `w=majority` | Recommended | Write concern for durability |

### Password URL Encoding

Special characters in passwords **must** be URL-encoded:

| Character | Encoded |
|-----------|---------|
| `!` | `%21` |
| `@` | `%40` |
| `:` | `%3A` |
| `=` | `%3D` |
| `/` | `%2F` |
| `?` | `%3F` |
| `#` | `%23` |
| `%` | `%25` |

**Example**: Password `MyP@ss!word` becomes `MyP%40ss%21word`

---

## Dart Implementation

### Basic Connection

```dart
import 'package:mongo_dart/mongo_dart.dart';

class MongoDbDatasource {
  Db? _db;

  bool get isConnected => _db?.isConnected ?? false;

  Future<void> connect(String uri) async {
    if (_db != null && _db!.isConnected) return;

    _db = await Db.create(uri);
    await _db!.open();  // TLS is handled via tls=true in URI
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  DbCollection collection(String name) {
    if (_db == null || !_db!.isConnected) {
      throw StateError('Database not connected');
    }
    return _db!.collection(name);
  }
}
```

### With Environment Variables

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mongo_dart/mongo_dart.dart';

class MongoDbDatasource {
  Db? _db;

  Future<void> connect() async {
    if (_db != null && _db!.isConnected) return;

    final uri = dotenv.env['MONGO_URI'];
    if (uri == null || uri.isEmpty) {
      throw StateError('MONGO_URI not found in environment');
    }

    _db = await Db.create(uri);
    await _db!.open();
  }

  // ... rest of implementation
}
```

### With Error Handling and Offline Fallback

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: 'lib/.env');

  final mongoDatasource = MongoDbDatasource();

  try {
    await mongoDatasource.connect();
    print('Connected to MongoDB Atlas');
  } catch (e) {
    print('Starting in offline mode: $e');
    // Fall back to local storage (e.g., Isar, Hive, SQLite)
  }

  runApp(MyApp(database: mongoDatasource));
}
```

---

## Environment Configuration

### lib/.env (Production - Git ignored)

```bash
# MongoDB Atlas connection (direct replica set format)
MONGO_URI=mongodb://username:password@shard0:27017,shard1:27017,shard2:27017/database?tls=true&replicaSet=atlas-xxx-shard-0&authSource=admin&retryWrites=true&w=majority
```

### lib/.env.example (Template - Committed to Git)

```bash
# MongoDB connection for Flutter app
#
# ─────────────────────────────────────────────────────────────────────────────
# LOCAL DEVELOPMENT (Docker)
# ─────────────────────────────────────────────────────────────────────────────
# MONGO_URI=mongodb://user:password@localhost:27017/database
#
# ─────────────────────────────────────────────────────────────────────────────
# PRODUCTION (MongoDB Atlas)
# ─────────────────────────────────────────────────────────────────────────────
# NOTE: mongo_dart doesn't support mongodb+srv:// - use direct replica set format
#
# MONGO_URI=mongodb://USER:PASSWORD@shard-00:27017,shard-01:27017,shard-02:27017/DATABASE?tls=true&replicaSet=REPLICA_SET_NAME&authSource=admin&retryWrites=true&w=majority
#
# URL-encode special characters in password:
#   ! -> %21    @ -> %40    : -> %3A    = -> %3D    / -> %2F
#
# ─────────────────────────────────────────────────────────────────────────────

MONGO_URI=mongodb://user:password@localhost:27017/database
```

### Load Environment in main.dart

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: 'lib/.env');
  // ...
}
```

### .gitignore

Ensure credentials are never committed:

```gitignore
# Environment files with secrets
lib/.env
*.env
!*.env.example
```

---

## TLS/SSL Security

### How TLS Works with Atlas

1. **Atlas requires TLS** - All connections must be encrypted
2. **Certificate validation** - Atlas uses Let's Encrypt certificates (trusted by all major OS)
3. **No custom certificates needed** - System CA store is used automatically

### Enabling TLS

TLS is enabled via the `tls=true` parameter in the connection string:

```
mongodb://...?tls=true&...
```

> **Important**: Do NOT use `ssl=true` (deprecated). Use `tls=true`.

### Verifying TLS is Active

If your connection succeeds to Atlas, TLS is working. Atlas rejects all non-TLS connections.

You can verify with OpenSSL:

```bash
openssl s_client -connect your-shard.mongodb.net:27017 -servername your-shard.mongodb.net
```

Expected output includes:
```
Certificate chain
 0 s:CN = *.xxxxx.mongodb.net
   i:C = US, O = Let's Encrypt, CN = R13
```

---

## Troubleshooting

### Connection Errors

| Error | Cause | Solution |
|-------|-------|----------|
| `WRONG_VERSION_NUMBER` | Using `mongodb+srv://` | Use direct replica set format |
| `Connection refused` | IP not whitelisted | Add IP to Atlas Network Access |
| `Authentication failed` | Wrong credentials | Verify username/password, check URL encoding |
| `Timeout` | Network/firewall issue | Check connectivity, verify IP whitelist |
| `Certificate verify failed` | System CA outdated | Update system certificates |

### Verify Network Connectivity

```bash
# Check if port is reachable
nc -zv your-shard.mongodb.net 27017

# Check DNS resolution
host -t SRV _mongodb._tcp.your-cluster.mongodb.net
```

### Check Your Public IP

```bash
curl -s ifconfig.me
```

Add this IP to Atlas Network Access if not using `0.0.0.0/0`.

### Replica Set Name

Find the replica set name in Atlas:
1. Go to **Database** > **Connect**
2. Select **Shell** or **Drivers**
3. Look for `replicaSet=` in the connection string

Or via DNS:
```bash
host -t TXT _mongodb._tcp.your-cluster.mongodb.net
```

---

## Testing Connection

### Test Script

Save as `scripts/test-mongo-simple.dart`:

```dart
import 'dart:io';
import 'package:mongo_dart/mongo_dart.dart';

void main() async {
  final envContent = File('lib/.env').readAsStringSync();
  final match = RegExp(r'MONGO_URI=(.+)').firstMatch(envContent);
  if (match == null) { print('MONGO_URI not found'); exit(1); }

  final uri = match.group(1)!.trim();
  final masked = uri.replaceAllMapped(RegExp(r':([^:@]+)@'), (m) => ':****@');
  print('URI: $masked');
  print('Connecting...');

  try {
    final db = await Db.create(uri);
    await db.open();
    print('SUCCESS!');
    print('Collections: ${await db.getCollectionNames()}');
    await db.close();
  } catch (e) {
    print('FAILED: $e');
    exit(1);
  }
}
```

Run with:
```bash
dart run scripts/test-mongo-simple.dart
```

Expected output:
```
URI: mongodb://user:****@shard0:27017,.../database?tls=true&...
Connecting...
SUCCESS!
Collections: [collection1, collection2]
```

---

## Quick Reference

### Minimum Working Example

**pubspec.yaml:**
```yaml
dependencies:
  mongo_dart: ^0.10.3
```

**lib/.env:**
```
MONGO_URI=mongodb://user:pass@shard0:27017,shard1:27017,shard2:27017/db?tls=true&replicaSet=atlas-xxx-shard-0&authSource=admin
```

**main.dart:**
```dart
import 'dart:io';
import 'package:mongo_dart/mongo_dart.dart';

void main() async {
  final uri = File('lib/.env')
      .readAsStringSync()
      .split('\n')
      .firstWhere((l) => l.startsWith('MONGO_URI='))
      .substring(10);

  final db = await Db.create(uri);
  await db.open();
  print('Connected! Collections: ${await db.getCollectionNames()}');
  await db.close();
}
```

---

## References

- [mongo_dart package](https://pub.dev/packages/mongo_dart)
- [MongoDB Atlas Documentation](https://www.mongodb.com/docs/atlas/)
- [MongoDB Connection String URI Format](https://www.mongodb.com/docs/manual/reference/connection-string/)
- [Atlas Network Access](https://www.mongodb.com/docs/atlas/security/ip-access-list/)
