import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import '../services/action_service.dart';
import '../services/action_executor.dart';

class ActionEndpoint extends Endpoint {
  final _actionService = ActionService();

  Future<ButlerAction?> objectify(Session session, String text) async {
    return _actionService.parseAction(session, text);
  }

  Future<bool> execute(Session session, ButlerAction action) async {
    return ActionExecutor().execute(session, action);
  }
}
