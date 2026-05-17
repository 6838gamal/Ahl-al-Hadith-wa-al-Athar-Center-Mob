class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';
  static const String me = '/auth/me';
  static const String changePassword = '/auth/change-password';

  // Users
  static const String users = '/users';
  static String userById(String id) => '/users/$id';
  static const String pendingUsers = '/users/pending';
  static String approveUser(String id) => '/users/$id/approve';
  static String rejectUser(String id) => '/users/$id/reject';
  static String banUser(String id) => '/users/$id/ban';

  // Messaging
  static const String conversations = '/conversations';
  static String conversationById(String id) => '/conversations/$id';
  static String messages(String conversationId) => '/conversations/$conversationId/messages';
  static String sendMessage(String conversationId) => '/conversations/$conversationId/messages';
  static String deleteMessage(String conversationId, String messageId) =>
      '/conversations/$conversationId/messages/$messageId';

  // Groups
  static const String groups = '/groups';
  static String groupById(String id) => '/groups/$id';
  static String groupMessages(String id) => '/groups/$id/messages';
  static String groupMembers(String id) => '/groups/$id/members';

  // Courses
  static const String courses = '/courses';
  static String courseById(String id) => '/courses/$id';
  static String courseLessons(String id) => '/courses/$id/lessons';

  // Tickets
  static const String tickets = '/tickets';
  static String ticketById(String id) => '/tickets/$id';
  static String assignTicket(String id) => '/tickets/$id/assign';
  static String closeTicket(String id) => '/tickets/$id/close';

  // Notifications
  static const String notifications = '/notifications';
  static const String markAllRead = '/notifications/read-all';
  static String markRead(String id) => '/notifications/$id/read';

  // Admin
  static const String adminStats = '/admin/stats';
  static const String adminUsers = '/admin/users';
  static const String adminLogs = '/admin/logs';
  static const String adminSettings = '/admin/settings';
}
