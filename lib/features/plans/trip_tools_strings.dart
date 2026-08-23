abstract class TripToolsStrings {
  // Chat Strings
  static const String tripChatTitle = 'Experience Chat';
  static const String chatEmptyTitle = 'No Messages Yet';
  static const String chatEmptyDesc =
      'Connect with your verified local host and fellow participants.';
  static const String typeMessageHint = 'Type a message...';
  static const String sendingMessage = 'Sending...';
  static const String sendFailed = 'Failed to send. Tap to retry';
  static const String retryAction = 'Retry';
  static const String messageSentError =
      'Could not send message. Saved to local outbox.';
  static const String meSenderLabel = 'You';

  // Gear Checklist Strings
  static const String gearChecklistTitle = 'Interactive Gear Checklist';
  static const String gearProgressLabel = 'Items Packed';
  static const String gearEmptyTitle = 'No Gear Items';
  static const String gearEmptyDesc =
      'Add gear items to keep track of your packing list.';
  static const String addGearButton = 'Add Custom Item';
  static const String addGearDialogTitle = 'Add Gear Checklist Item';
  static const String gearItemLabelHint =
      'Item name (e.g. Sleeping Bag, Headlamp)';
  static const String addAction = 'Add Item';
  static const String cancelAction = 'Cancel';
  static const String customBadge = 'Custom';

  // Budget Tracker Strings
  static const String budgetTrackerTitle = 'Experience Budget';
  static const String totalSpentLabel = 'Total Expenses';
  static const String categoryBreakdownTitle = 'Category Breakdown';
  static const String recentExpensesTitle = 'Expense Log';
  static const String budgetEmptyTitle = 'No Expenses Logged';
  static const String budgetEmptyDesc =
      'Log expenses to keep track of your experience budget.';
  static const String addExpenseButton = 'Log New Expense';
  static const String addExpenseDialogTitle = 'Log Experience Expense';
  static const String expenseLabelHint =
      'Expense description (e.g. Tea house dinner)';
  static const String expenseAmountHint = 'Amount in NPR (Rs.)';
  static const String categoryLabel = 'Category';
  static const String dateLabel = 'Date Spent';
  static const String saveExpenseAction = 'Save Expense';
  static const String invalidAmountError = 'Please enter a valid amount in NPR';
  static const String deleteExpenseConfirm = 'Delete this expense?';

  // Expense Categories
  static const String categoryFood = 'Food & Drinks';
  static const String categoryTransport = 'Transport';
  static const String categoryPermits = 'Permits & Fees';
  static const String categoryGear = 'Gear & Rentals';
  static const String categoryStay = 'Accommodation';
  static const String categoryTips = 'Tips & Gratuity';
  static const String categoryMisc = 'Miscellaneous';

  static const List<String> expenseCategories = [
    categoryFood,
    categoryTransport,
    categoryPermits,
    categoryGear,
    categoryStay,
    categoryTips,
    categoryMisc,
  ];
}
