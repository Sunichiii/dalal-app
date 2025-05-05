abstract class SearchEvent {}

class SearchGroups extends SearchEvent {
  final String query;
  SearchGroups(this.query);
}

class SendJoinRequest extends SearchEvent {
  final String groupId;
  final String groupName;
  final String userName;
  final String userId;

  SendJoinRequest({required this.groupId, required this.groupName, required this.userName, required this.userId});
}
