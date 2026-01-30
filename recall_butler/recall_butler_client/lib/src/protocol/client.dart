/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    as _i1;
import 'package:serverpod_client/serverpod_client.dart' as _i2;
import 'dart:async' as _i3;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as _i4;
import 'package:recall_butler_client/src/protocol/actions/butler_action.dart'
    as _i5;
import 'package:recall_butler_client/src/protocol/document.dart' as _i6;
import 'package:recall_butler_client/src/protocol/reminder.dart' as _i7;
import 'package:recall_butler_client/src/protocol/search_response.dart' as _i8;
import 'package:recall_butler_client/src/protocol/search_result.dart' as _i9;
import 'package:recall_butler_client/src/protocol/suggestion.dart' as _i10;
import 'package:recall_butler_client/src/protocol/greetings/greeting.dart'
    as _i11;
import 'protocol.dart' as _i12;

/// By extending [EmailIdpBaseEndpoint], the email identity provider endpoints
/// are made available on the server and enable the corresponding sign-in widget
/// on the client.
/// {@category Endpoint}
class EndpointEmailIdp extends _i1.EndpointEmailIdpBase {
  EndpointEmailIdp(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'emailIdp';

  /// Logs in the user and returns a new session.
  ///
  /// Throws an [EmailAccountLoginException] in case of errors, with reason:
  /// - [EmailAccountLoginExceptionReason.invalidCredentials] if the email or
  ///   password is incorrect.
  /// - [EmailAccountLoginExceptionReason.tooManyAttempts] if there have been
  ///   too many failed login attempts.
  ///
  /// Throws an [AuthUserBlockedException] if the auth user is blocked.
  @override
  _i3.Future<_i4.AuthSuccess> login({
    required String email,
    required String password,
  }) => caller.callServerEndpoint<_i4.AuthSuccess>(
    'emailIdp',
    'login',
    {
      'email': email,
      'password': password,
    },
  );

  /// Starts the registration for a new user account with an email-based login
  /// associated to it.
  ///
  /// Upon successful completion of this method, an email will have been
  /// sent to [email] with a verification link, which the user must open to
  /// complete the registration.
  ///
  /// Always returns a account request ID, which can be used to complete the
  /// registration. If the email is already registered, the returned ID will not
  /// be valid.
  @override
  _i3.Future<_i2.UuidValue> startRegistration({required String email}) =>
      caller.callServerEndpoint<_i2.UuidValue>(
        'emailIdp',
        'startRegistration',
        {'email': email},
      );

  /// Verifies an account request code and returns a token
  /// that can be used to complete the account creation.
  ///
  /// Throws an [EmailAccountRequestException] in case of errors, with reason:
  /// - [EmailAccountRequestExceptionReason.expired] if the account request has
  ///   already expired.
  /// - [EmailAccountRequestExceptionReason.policyViolation] if the password
  ///   does not comply with the password policy.
  /// - [EmailAccountRequestExceptionReason.invalid] if no request exists
  ///   for the given [accountRequestId] or [verificationCode] is invalid.
  @override
  _i3.Future<String> verifyRegistrationCode({
    required _i2.UuidValue accountRequestId,
    required String verificationCode,
  }) => caller.callServerEndpoint<String>(
    'emailIdp',
    'verifyRegistrationCode',
    {
      'accountRequestId': accountRequestId,
      'verificationCode': verificationCode,
    },
  );

  /// Completes a new account registration, creating a new auth user with a
  /// profile and attaching the given email account to it.
  ///
  /// Throws an [EmailAccountRequestException] in case of errors, with reason:
  /// - [EmailAccountRequestExceptionReason.expired] if the account request has
  ///   already expired.
  /// - [EmailAccountRequestExceptionReason.policyViolation] if the password
  ///   does not comply with the password policy.
  /// - [EmailAccountRequestExceptionReason.invalid] if the [registrationToken]
  ///   is invalid.
  ///
  /// Throws an [AuthUserBlockedException] if the auth user is blocked.
  ///
  /// Returns a session for the newly created user.
  @override
  _i3.Future<_i4.AuthSuccess> finishRegistration({
    required String registrationToken,
    required String password,
  }) => caller.callServerEndpoint<_i4.AuthSuccess>(
    'emailIdp',
    'finishRegistration',
    {
      'registrationToken': registrationToken,
      'password': password,
    },
  );

  /// Requests a password reset for [email].
  ///
  /// If the email address is registered, an email with reset instructions will
  /// be send out. If the email is unknown, this method will have no effect.
  ///
  /// Always returns a password reset request ID, which can be used to complete
  /// the reset. If the email is not registered, the returned ID will not be
  /// valid.
  ///
  /// Throws an [EmailAccountPasswordResetException] in case of errors, with reason:
  /// - [EmailAccountPasswordResetExceptionReason.tooManyAttempts] if the user has
  ///   made too many attempts trying to request a password reset.
  ///
  @override
  _i3.Future<_i2.UuidValue> startPasswordReset({required String email}) =>
      caller.callServerEndpoint<_i2.UuidValue>(
        'emailIdp',
        'startPasswordReset',
        {'email': email},
      );

  /// Verifies a password reset code and returns a finishPasswordResetToken
  /// that can be used to finish the password reset.
  ///
  /// Throws an [EmailAccountPasswordResetException] in case of errors, with reason:
  /// - [EmailAccountPasswordResetExceptionReason.expired] if the password reset
  ///   request has already expired.
  /// - [EmailAccountPasswordResetExceptionReason.tooManyAttempts] if the user has
  ///   made too many attempts trying to verify the password reset.
  /// - [EmailAccountPasswordResetExceptionReason.invalid] if no request exists
  ///   for the given [passwordResetRequestId] or [verificationCode] is invalid.
  ///
  /// If multiple steps are required to complete the password reset, this endpoint
  /// should be overridden to return credentials for the next step instead
  /// of the credentials for setting the password.
  @override
  _i3.Future<String> verifyPasswordResetCode({
    required _i2.UuidValue passwordResetRequestId,
    required String verificationCode,
  }) => caller.callServerEndpoint<String>(
    'emailIdp',
    'verifyPasswordResetCode',
    {
      'passwordResetRequestId': passwordResetRequestId,
      'verificationCode': verificationCode,
    },
  );

  /// Completes a password reset request by setting a new password.
  ///
  /// The [verificationCode] returned from [verifyPasswordResetCode] is used to
  /// validate the password reset request.
  ///
  /// Throws an [EmailAccountPasswordResetException] in case of errors, with reason:
  /// - [EmailAccountPasswordResetExceptionReason.expired] if the password reset
  ///   request has already expired.
  /// - [EmailAccountPasswordResetExceptionReason.policyViolation] if the new
  ///   password does not comply with the password policy.
  /// - [EmailAccountPasswordResetExceptionReason.invalid] if no request exists
  ///   for the given [passwordResetRequestId] or [verificationCode] is invalid.
  ///
  /// Throws an [AuthUserBlockedException] if the auth user is blocked.
  @override
  _i3.Future<void> finishPasswordReset({
    required String finishPasswordResetToken,
    required String newPassword,
  }) => caller.callServerEndpoint<void>(
    'emailIdp',
    'finishPasswordReset',
    {
      'finishPasswordResetToken': finishPasswordResetToken,
      'newPassword': newPassword,
    },
  );
}

/// By extending [RefreshJwtTokensEndpoint], the JWT token refresh endpoint
/// is made available on the server and enables automatic token refresh on the client.
/// {@category Endpoint}
class EndpointJwtRefresh extends _i4.EndpointRefreshJwtTokens {
  EndpointJwtRefresh(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'jwtRefresh';

  /// Creates a new token pair for the given [refreshToken].
  ///
  /// Can throw the following exceptions:
  /// -[RefreshTokenMalformedException]: refresh token is malformed and could
  ///   not be parsed. Not expected to happen for tokens issued by the server.
  /// -[RefreshTokenNotFoundException]: refresh token is unknown to the server.
  ///   Either the token was deleted or generated by a different server.
  /// -[RefreshTokenExpiredException]: refresh token has expired. Will happen
  ///   only if it has not been used within configured `refreshTokenLifetime`.
  /// -[RefreshTokenInvalidSecretException]: refresh token is incorrect, meaning
  ///   it does not refer to the current secret refresh token. This indicates
  ///   either a malfunctioning client or a malicious attempt by someone who has
  ///   obtained the refresh token. In this case the underlying refresh token
  ///   will be deleted, and access to it will expire fully when the last access
  ///   token is elapsed.
  ///
  /// This endpoint is unauthenticated, meaning the client won't include any
  /// authentication information with the call.
  @override
  _i3.Future<_i4.AuthSuccess> refreshAccessToken({
    required String refreshToken,
  }) => caller.callServerEndpoint<_i4.AuthSuccess>(
    'jwtRefresh',
    'refreshAccessToken',
    {'refreshToken': refreshToken},
    authenticated: false,
  );
}

/// {@category Endpoint}
class EndpointAction extends _i2.EndpointRef {
  EndpointAction(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'action';

  _i3.Future<_i5.ButlerAction?> objectify(String text) =>
      caller.callServerEndpoint<_i5.ButlerAction?>(
        'action',
        'objectify',
        {'text': text},
      );

  _i3.Future<bool> execute(_i5.ButlerAction action) =>
      caller.callServerEndpoint<bool>(
        'action',
        'execute',
        {'action': action},
      );
}

/// Analytics endpoint for usage statistics and insights
/// {@category Endpoint}
class EndpointAnalytics extends _i2.EndpointRef {
  EndpointAnalytics(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'analytics';

  /// Get overall analytics summary
  _i3.Future<Map<String, dynamic>> getSummary() =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'analytics',
        'getSummary',
        {},
      );

  /// Get document activity over time (last 30 days)
  _i3.Future<List<Map<String, dynamic>>> getActivityTimeline() =>
      caller.callServerEndpoint<List<Map<String, dynamic>>>(
        'analytics',
        'getActivityTimeline',
        {},
      );

  /// Get document type distribution
  _i3.Future<List<Map<String, dynamic>>> getDocumentTypes() =>
      caller.callServerEndpoint<List<Map<String, dynamic>>>(
        'analytics',
        'getDocumentTypes',
        {},
      );

  /// Get top search queries
  _i3.Future<List<Map<String, dynamic>>> getTopSearches({required int limit}) =>
      caller.callServerEndpoint<List<Map<String, dynamic>>>(
        'analytics',
        'getTopSearches',
        {'limit': limit},
      );

  /// Get memory insights (AI-generated observations)
  _i3.Future<Map<String, dynamic>> getInsights() =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'analytics',
        'getInsights',
        {},
      );

  /// Get knowledge graph data (connections between documents)
  _i3.Future<Map<String, dynamic>> getKnowledgeGraph() =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'analytics',
        'getKnowledgeGraph',
        {},
      );
}

/// Authentication Endpoint - Handles user auth flows
/// {@category Endpoint}
class EndpointAuth extends _i2.EndpointRef {
  EndpointAuth(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'auth';

  /// Register a new user
  _i3.Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
  }) => caller.callServerEndpoint<Map<String, dynamic>>(
    'auth',
    'register',
    {
      'email': email,
      'password': password,
      'name': name,
    },
  );

  /// Login with email and password
  _i3.Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) => caller.callServerEndpoint<Map<String, dynamic>>(
    'auth',
    'login',
    {
      'email': email,
      'password': password,
    },
  );

  /// Refresh access token
  _i3.Future<Map<String, dynamic>> refresh({required String refreshToken}) =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'auth',
        'refresh',
        {'refreshToken': refreshToken},
      );

  /// Logout (revoke refresh token)
  _i3.Future<Map<String, dynamic>> logout({required String refreshToken}) =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'auth',
        'logout',
        {'refreshToken': refreshToken},
      );

  /// Logout from all devices
  _i3.Future<Map<String, dynamic>> logoutAll({required String authHeader}) =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'auth',
        'logoutAll',
        {'authHeader': authHeader},
      );

  /// Get current user profile
  _i3.Future<Map<String, dynamic>> me({required String authHeader}) =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'auth',
        'me',
        {'authHeader': authHeader},
      );

  /// Update user profile
  _i3.Future<Map<String, dynamic>> updateProfile({
    required String authHeader,
    String? name,
    String? avatarUrl,
  }) => caller.callServerEndpoint<Map<String, dynamic>>(
    'auth',
    'updateProfile',
    {
      'authHeader': authHeader,
      'name': name,
      'avatarUrl': avatarUrl,
    },
  );

  /// Change password
  _i3.Future<Map<String, dynamic>> changePassword({
    required String authHeader,
    required String currentPassword,
    required String newPassword,
  }) => caller.callServerEndpoint<Map<String, dynamic>>(
    'auth',
    'changePassword',
    {
      'authHeader': authHeader,
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    },
  );

  /// OAuth2 callback handler (for Google/Apple sign-in)
  _i3.Future<Map<String, dynamic>> oauthCallback({
    required String provider,
    required String code,
    String? state,
  }) => caller.callServerEndpoint<Map<String, dynamic>>(
    'auth',
    'oauthCallback',
    {
      'provider': provider,
      'code': code,
      'state': state,
    },
  );
}

/// {@category Endpoint}
class EndpointDocument extends _i2.EndpointRef {
  EndpointDocument(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'document';

  /// Create a new document from text
  _i3.Future<_i6.Document> createFromText({
    required String title,
    required String text,
    required int userId,
  }) => caller.callServerEndpoint<_i6.Document>(
    'document',
    'createFromText',
    {
      'title': title,
      'text': text,
      'userId': userId,
    },
  );

  /// Create a new document from URL
  _i3.Future<_i6.Document> createFromUrl({
    required String title,
    required String url,
    required int userId,
  }) => caller.callServerEndpoint<_i6.Document>(
    'document',
    'createFromUrl',
    {
      'title': title,
      'url': url,
      'userId': userId,
    },
  );

  /// Create a new document from image (base64)
  _i3.Future<_i6.Document> createFromImage({
    required String title,
    required String imageBase64,
    required String type,
    required int userId,
  }) => caller.callServerEndpoint<_i6.Document>(
    'document',
    'createFromImage',
    {
      'title': title,
      'imageBase64': imageBase64,
      'type': type,
      'userId': userId,
    },
  );

  /// Get all documents for a user
  _i3.Future<List<_i6.Document>> getDocuments({
    required int userId,
    required int limit,
  }) => caller.callServerEndpoint<List<_i6.Document>>(
    'document',
    'getDocuments',
    {
      'userId': userId,
      'limit': limit,
    },
  );

  /// Get a single document by ID
  _i3.Future<_i6.Document?> getDocument(int id) =>
      caller.callServerEndpoint<_i6.Document?>(
        'document',
        'getDocument',
        {'id': id},
      );

  /// Delete a document
  _i3.Future<bool> deleteDocument(int id) => caller.callServerEndpoint<bool>(
    'document',
    'deleteDocument',
    {'id': id},
  );

  /// Get document statistics
  _i3.Future<Map<String, int>> getStats({required int userId}) =>
      caller.callServerEndpoint<Map<String, int>>(
        'document',
        'getStats',
        {'userId': userId},
      );
}

/// Health check endpoint for monitoring and orchestration
/// {@category Endpoint}
class EndpointHealth extends _i2.EndpointRef {
  EndpointHealth(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'health';

  /// Basic health check - returns 200 if service is running
  _i3.Future<Map<String, dynamic>> check() =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'health',
        'check',
        {},
      );

  /// Detailed health check with dependencies
  _i3.Future<Map<String, dynamic>> detailed() =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'health',
        'detailed',
        {},
      );

  /// Readiness probe for Kubernetes/orchestration
  _i3.Future<Map<String, dynamic>> ready() =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'health',
        'ready',
        {},
      );

  /// Liveness probe
  _i3.Future<Map<String, dynamic>> live() =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'health',
        'live',
        {},
      );

  /// Get service metrics
  _i3.Future<Map<String, dynamic>> metrics() =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'health',
        'metrics',
        {},
      );
}

/// ═══════════════════════════════════════════════════════════════════════════════
/// 🧠 RECALL BUTLER - MCP HTTP ENDPOINT
/// ═══════════════════════════════════════════════════════════════════════════════
///
/// Exposes MCP functionality via HTTP for web-based integrations
/// ═══════════════════════════════════════════════════════════════════════════════
/// {@category Endpoint}
class EndpointMcp extends _i2.EndpointRef {
  EndpointMcp(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'mcp';

  /// Get MCP server manifest
  /// Returns the full MCP manifest with tools, resources, and prompts
  _i3.Future<Map<String, dynamic>> getManifest() =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'mcp',
        'getManifest',
        {},
      );

  /// List available MCP tools
  _i3.Future<List<Map<String, dynamic>>> listTools() =>
      caller.callServerEndpoint<List<Map<String, dynamic>>>(
        'mcp',
        'listTools',
        {},
      );

  /// List available MCP resources
  _i3.Future<List<Map<String, dynamic>>> listResources() =>
      caller.callServerEndpoint<List<Map<String, dynamic>>>(
        'mcp',
        'listResources',
        {},
      );

  /// List available MCP prompts
  _i3.Future<List<Map<String, dynamic>>> listPrompts() =>
      caller.callServerEndpoint<List<Map<String, dynamic>>>(
        'mcp',
        'listPrompts',
        {},
      );

  /// Execute an MCP tool
  _i3.Future<Map<String, dynamic>> executeTool(
    String toolName,
    Map<String, dynamic> arguments,
  ) => caller.callServerEndpoint<Map<String, dynamic>>(
    'mcp',
    'executeTool',
    {
      'toolName': toolName,
      'arguments': arguments,
    },
  );

  /// Read an MCP resource
  _i3.Future<Map<String, dynamic>> readResource(String uri) =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'mcp',
        'readResource',
        {'uri': uri},
      );

  /// Get an MCP prompt
  _i3.Future<Map<String, dynamic>> getPrompt(
    String promptName,
    Map<String, dynamic> arguments,
  ) => caller.callServerEndpoint<Map<String, dynamic>>(
    'mcp',
    'getPrompt',
    {
      'promptName': promptName,
      'arguments': arguments,
    },
  );

  /// Handle raw MCP JSON-RPC request
  _i3.Future<Map<String, dynamic>> handleJsonRpc(
    Map<String, dynamic> request,
  ) => caller.callServerEndpoint<Map<String, dynamic>>(
    'mcp',
    'handleJsonRpc',
    {'request': request},
  );
}

/// ═══════════════════════════════════════════════════════════════════════════════
/// ⚡ REAL-TIME & WEB5 ENDPOINTS
/// ═══════════════════════════════════════════════════════════════════════════════
///
/// FastAPI-style async endpoints for:
/// - Real-time event subscriptions
/// - WebSocket connection info
/// - Web5 decentralized identity
/// ═══════════════════════════════════════════════════════════════════════════════
/// {@category Endpoint}
class EndpointRealtime extends _i2.EndpointRef {
  EndpointRealtime(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'realtime';

  /// Get SSE connection info for client
  _i3.Future<Map<String, dynamic>> getSSEInfo() =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'realtime',
        'getSSEInfo',
        {},
      );

  /// Get WebSocket connection info
  _i3.Future<Map<String, dynamic>> getWebSocketInfo() =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'realtime',
        'getWebSocketInfo',
        {},
      );

  /// Trigger a test event (for debugging)
  _i3.Future<Map<String, dynamic>> triggerTestEvent({
    required int userId,
    required String eventType,
    Map<String, dynamic>? data,
  }) => caller.callServerEndpoint<Map<String, dynamic>>(
    'realtime',
    'triggerTestEvent',
    {
      'userId': userId,
      'eventType': eventType,
      'data': data,
    },
  );

  /// Create a new Web5 decentralized identity
  _i3.Future<Map<String, dynamic>> createWeb5Identity({
    String? name,
    String? email,
  }) => caller.callServerEndpoint<Map<String, dynamic>>(
    'realtime',
    'createWeb5Identity',
    {
      'name': name,
      'email': email,
    },
  );

  /// Connect to existing Web5 identity
  _i3.Future<Map<String, dynamic>> connectWeb5Identity({required String did}) =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'realtime',
        'connectWeb5Identity',
        {'did': did},
      );

  /// Store a memory in user's Decentralized Web Node
  _i3.Future<Map<String, dynamic>> storeInDWN({
    required String title,
    required String content,
    required String sourceType,
    Map<String, dynamic>? metadata,
  }) => caller.callServerEndpoint<Map<String, dynamic>>(
    'realtime',
    'storeInDWN',
    {
      'title': title,
      'content': content,
      'sourceType': sourceType,
      'metadata': metadata,
    },
  );

  /// Share memories with another user via Verifiable Credential
  _i3.Future<Map<String, dynamic>> shareMemories({
    required String recipientDid,
    required List<String> memoryIds,
    required int expiresInDays,
  }) => caller.callServerEndpoint<Map<String, dynamic>>(
    'realtime',
    'shareMemories',
    {
      'recipientDid': recipientDid,
      'memoryIds': memoryIds,
      'expiresInDays': expiresInDays,
    },
  );

  /// Export Web5 identity for backup
  _i3.Future<Map<String, dynamic>> exportWeb5Identity() =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'realtime',
        'exportWeb5Identity',
        {},
      );

  /// Get current Web5 DID
  _i3.Future<Map<String, dynamic>> getCurrentDID() =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'realtime',
        'getCurrentDID',
        {},
      );

  /// Get real-time sync status
  _i3.Future<Map<String, dynamic>> getSyncStatus({required int userId}) =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'realtime',
        'getSyncStatus',
        {'userId': userId},
      );

  /// Trigger manual sync
  _i3.Future<Map<String, dynamic>> triggerSync({required int userId}) =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'realtime',
        'triggerSync',
        {'userId': userId},
      );
}

/// {@category Endpoint}
class EndpointReminder extends _i2.EndpointRef {
  EndpointReminder(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'reminder';

  _i3.Future<List<_i7.Reminder>> getReminders() =>
      caller.callServerEndpoint<List<_i7.Reminder>>(
        'reminder',
        'getReminders',
        {},
      );

  _i3.Future<_i7.Reminder> createReminder(_i7.Reminder reminder) =>
      caller.callServerEndpoint<_i7.Reminder>(
        'reminder',
        'createReminder',
        {'reminder': reminder},
      );

  _i3.Future<_i7.Reminder> updateReminder(_i7.Reminder reminder) =>
      caller.callServerEndpoint<_i7.Reminder>(
        'reminder',
        'updateReminder',
        {'reminder': reminder},
      );

  _i3.Future<void> deleteReminder(int id) => caller.callServerEndpoint<void>(
    'reminder',
    'deleteReminder',
    {'id': id},
  );
}

/// {@category Endpoint}
class EndpointSearch extends _i2.EndpointRef {
  EndpointSearch(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'search';

  /// Semantic search across documents (now Hybrid)
  _i3.Future<_i8.SearchResponse> search({
    required String query,
    required int userId,
    required int topK,
  }) => caller.callServerEndpoint<_i8.SearchResponse>(
    'search',
    'search',
    {
      'query': query,
      'userId': userId,
      'topK': topK,
    },
  );

  /// Quick search returning just results
  _i3.Future<List<_i9.SearchResult>> quickSearch({
    required String query,
    required int userId,
    required int topK,
  }) => caller.callServerEndpoint<List<_i9.SearchResult>>(
    'search',
    'quickSearch',
    {
      'query': query,
      'userId': userId,
      'topK': topK,
    },
  );
}

/// {@category Endpoint}
class EndpointSuggestion extends _i2.EndpointRef {
  EndpointSuggestion(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'suggestion';

  /// Create a custom reminder for a document
  _i3.Future<_i10.Suggestion> createReminder({
    required int documentId,
    required String title,
    required String description,
    required DateTime scheduledAt,
    required int userId,
  }) => caller.callServerEndpoint<_i10.Suggestion>(
    'suggestion',
    'createReminder',
    {
      'documentId': documentId,
      'title': title,
      'description': description,
      'scheduledAt': scheduledAt,
      'userId': userId,
    },
  );

  /// Get all suggestions for a user
  _i3.Future<List<_i10.Suggestion>> getSuggestions({
    required int userId,
    String? state,
  }) => caller.callServerEndpoint<List<_i10.Suggestion>>(
    'suggestion',
    'getSuggestions',
    {
      'userId': userId,
      'state': state,
    },
  );

  /// Get pending suggestions count
  _i3.Future<int> getPendingCount({required int userId}) =>
      caller.callServerEndpoint<int>(
        'suggestion',
        'getPendingCount',
        {'userId': userId},
      );

  /// Accept a suggestion
  _i3.Future<_i10.Suggestion> accept(int id) =>
      caller.callServerEndpoint<_i10.Suggestion>(
        'suggestion',
        'accept',
        {'id': id},
      );

  /// Dismiss a suggestion
  _i3.Future<_i10.Suggestion> dismiss(int id) =>
      caller.callServerEndpoint<_i10.Suggestion>(
        'suggestion',
        'dismiss',
        {'id': id},
      );

  /// Get suggestion by ID
  _i3.Future<_i10.Suggestion?> getSuggestion(int id) =>
      caller.callServerEndpoint<_i10.Suggestion?>(
        'suggestion',
        'getSuggestion',
        {'id': id},
      );
}

/// This is an example endpoint that returns a greeting message through
/// its [hello] method.
/// {@category Endpoint}
class EndpointGreeting extends _i2.EndpointRef {
  EndpointGreeting(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'greeting';

  /// Returns a personalized greeting message: "Hello {name}".
  _i3.Future<_i11.Greeting> hello(String name) =>
      caller.callServerEndpoint<_i11.Greeting>(
        'greeting',
        'hello',
        {'name': name},
      );
}

class Modules {
  Modules(Client client) {
    serverpod_auth_idp = _i1.Caller(client);
    serverpod_auth_core = _i4.Caller(client);
  }

  late final _i1.Caller serverpod_auth_idp;

  late final _i4.Caller serverpod_auth_core;
}

class Client extends _i2.ServerpodClientShared {
  Client(
    String host, {
    dynamic securityContext,
    @Deprecated(
      'Use authKeyProvider instead. This will be removed in future releases.',
    )
    super.authenticationKeyManager,
    Duration? streamingConnectionTimeout,
    Duration? connectionTimeout,
    Function(
      _i2.MethodCallContext,
      Object,
      StackTrace,
    )?
    onFailedCall,
    Function(_i2.MethodCallContext)? onSucceededCall,
    bool? disconnectStreamsOnLostInternetConnection,
  }) : super(
         host,
         _i12.Protocol(),
         securityContext: securityContext,
         streamingConnectionTimeout: streamingConnectionTimeout,
         connectionTimeout: connectionTimeout,
         onFailedCall: onFailedCall,
         onSucceededCall: onSucceededCall,
         disconnectStreamsOnLostInternetConnection:
             disconnectStreamsOnLostInternetConnection,
       ) {
    emailIdp = EndpointEmailIdp(this);
    jwtRefresh = EndpointJwtRefresh(this);
    action = EndpointAction(this);
    analytics = EndpointAnalytics(this);
    auth = EndpointAuth(this);
    document = EndpointDocument(this);
    health = EndpointHealth(this);
    mcp = EndpointMcp(this);
    realtime = EndpointRealtime(this);
    reminder = EndpointReminder(this);
    search = EndpointSearch(this);
    suggestion = EndpointSuggestion(this);
    greeting = EndpointGreeting(this);
    modules = Modules(this);
  }

  late final EndpointEmailIdp emailIdp;

  late final EndpointJwtRefresh jwtRefresh;

  late final EndpointAction action;

  late final EndpointAnalytics analytics;

  late final EndpointAuth auth;

  late final EndpointDocument document;

  late final EndpointHealth health;

  late final EndpointMcp mcp;

  late final EndpointRealtime realtime;

  late final EndpointReminder reminder;

  late final EndpointSearch search;

  late final EndpointSuggestion suggestion;

  late final EndpointGreeting greeting;

  late final Modules modules;

  @override
  Map<String, _i2.EndpointRef> get endpointRefLookup => {
    'emailIdp': emailIdp,
    'jwtRefresh': jwtRefresh,
    'action': action,
    'analytics': analytics,
    'auth': auth,
    'document': document,
    'health': health,
    'mcp': mcp,
    'realtime': realtime,
    'reminder': reminder,
    'search': search,
    'suggestion': suggestion,
    'greeting': greeting,
  };

  @override
  Map<String, _i2.ModuleEndpointCaller> get moduleLookup => {
    'serverpod_auth_idp': modules.serverpod_auth_idp,
    'serverpod_auth_core': modules.serverpod_auth_core,
  };
}
