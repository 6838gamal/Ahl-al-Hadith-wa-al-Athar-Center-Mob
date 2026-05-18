class ApiEndpoints {
  ApiEndpoints._();

  static const String login = '/auth/login';
  static const String adminLogin = '/auth/admin-login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';

  static const String users = '/users';
  static String userById(String id) => '/users/$id';
  static const String updateMe = '/users/me';
  static const String changePassword = '/users/me/password';

  static const String conversations = '/messages/conversations';
  static String createConversation = '/messages/conversations';
  static String conversationMessages(String id) => '/messages/conversations/$id/messages';
  static String sendMessage(String id) => '/messages/conversations/$id/messages';
  static String messageReaction(String msgId) => '/messages/messages/$msgId/reactions';
  static String deleteMessage(String msgId) => '/messages/messages/$msgId';

  static const String groups = '/groups';
  static String joinGroup(String id) => '/groups/$id/join';
  static String leaveGroup(String id) => '/groups/$id/leave';

  static const String courses = '/courses';
  static String enrollCourse(String id) => '/courses/$id/enroll';

  static const String tickets = '/tickets';
  static String ticketById(String id) => '/tickets/$id';
  static String ticketReplies(String id) => '/tickets/$id/replies';
  static String updateTicket(String id) => '/tickets/$id';

  static const String notifications = '/notifications';
  static const String notificationsUnread = '/notifications/unread-count';
  static const String markAllRead = '/notifications/read-all';
  static String markRead(String id) => '/notifications/$id/read';

  static const String adminDashboard = '/admin/dashboard';
  static const String adminUsers = '/admin/users';
  static String adminUserById(String id) => '/admin/users/$id';
  static const String adminPendingUsers = '/admin/pending-users';
  static String approveUser(String id) => '/admin/users/$id/approve';
  static String rejectUser(String id) => '/admin/users/$id/reject';
  static const String adminActivity = '/admin/activity';
}
