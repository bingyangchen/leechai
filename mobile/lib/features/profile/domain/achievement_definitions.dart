enum AchievementRepeatType { oneTime, perPeriod }

enum AchievementId {
  firstEntry,
  hundredEntries,
  thousandEntries,
  streak7Days,
  streak30Days,
  streak100Days,
  monthlyPerfect,
  fourWeekendsStreak,
  backfillStreak3,
  secondAccount,
  firstBudget,
  firstCustomTag,
  budgetGuardian,
  positiveCashflow,
  firstIncome,
  oneYear,
  nightOwl,
  lucky777,
}

extension AchievementIdX on AchievementId {
  String get key {
    switch (this) {
      case AchievementId.firstEntry:
        return 'first_entry';
      case AchievementId.hundredEntries:
        return 'hundred_entries';
      case AchievementId.thousandEntries:
        return 'thousand_entries';
      case AchievementId.streak7Days:
        return 'streak_7_days';
      case AchievementId.streak30Days:
        return 'streak_30_days';
      case AchievementId.streak100Days:
        return 'streak_100_days';
      case AchievementId.monthlyPerfect:
        return 'monthly_perfect';
      case AchievementId.fourWeekendsStreak:
        return 'four_weekends_streak';
      case AchievementId.backfillStreak3:
        return 'backfill_streak_3';
      case AchievementId.secondAccount:
        return 'second_account';
      case AchievementId.firstBudget:
        return 'first_budget';
      case AchievementId.firstCustomTag:
        return 'first_custom_tag';
      case AchievementId.budgetGuardian:
        return 'budget_guardian';
      case AchievementId.positiveCashflow:
        return 'positive_cashflow';
      case AchievementId.firstIncome:
        return 'first_income';
      case AchievementId.oneYear:
        return 'one_year';
      case AchievementId.nightOwl:
        return 'night_owl';
      case AchievementId.lucky777:
        return 'lucky_777';
    }
  }

  AchievementDefinition get definition {
    switch (this) {
      case AchievementId.firstEntry:
        return const AchievementDefinition(
          achievementId: AchievementId.firstEntry,
          name: '初來乍到',
          description: '完成你的第一筆記帳，開啟理財習慣養成之路吧！',
          conditionText: '記錄第一筆帳',
          target: 1,
        );
      case AchievementId.firstIncome:
        return const AchievementDefinition(
          achievementId: AchievementId.firstIncome,
          name: '第一桶金',
          description: '首次記錄一筆收入。',
          conditionText: '記錄第一筆收入',
          target: 1,
        );
      case AchievementId.streak7Days:
        return const AchievementDefinition(
          achievementId: AchievementId.streak7Days,
          name: '連續一週',
          description: '連續 7 天都有記帳，習慣正在養成了呢！',
          conditionText: '連續 7 天記帳',
          target: 7,
        );
      case AchievementId.streak30Days:
        return const AchievementDefinition(
          achievementId: AchievementId.streak30Days,
          name: '連續一月',
          description: '連續 30 天記帳不斷更，看來你已經把記帳融入生活囉～',
          conditionText: '連續 30 天記帳',
          target: 30,
        );
      case AchievementId.streak100Days:
        return const AchievementDefinition(
          achievementId: AchievementId.streak100Days,
          name: '連續百日',
          description: '連續 100 天！你的表現令我刮目相看！',
          conditionText: '連續 100 天記帳',
          target: 100,
        );
      case AchievementId.monthlyPerfect:
        return const AchievementDefinition(
          achievementId: AchievementId.monthlyPerfect,
          name: '全勤模範',
          description: '整個月一天都沒漏記，全勤達人就是你！',
          conditionText: '單月每天都有記帳',
          target: 31,
          repeatType: AchievementRepeatType.perPeriod,
        );
      case AchievementId.fourWeekendsStreak:
        return const AchievementDefinition(
          achievementId: AchievementId.fourWeekendsStreak,
          name: '週末不打烊',
          description: '連續 4 個週末都有記帳，連假日也不放過～',
          conditionText: '連續 4 個週末都有記帳',
          target: 4,
        );
      case AchievementId.backfillStreak3:
        return const AchievementDefinition(
          achievementId: AchievementId.backfillStreak3,
          name: '補登達人',
          description: '連續 3 次事後補登昨天的帳，不忘記任何一筆！',
          conditionText: '連續 3 次補登昨日帳務',
          target: 3,
        );
      case AchievementId.secondAccount:
        return const AchievementDefinition(
          achievementId: AchievementId.secondAccount,
          name: '資產總管',
          description: '建立第二個帳戶，從記帳邁向資產管理囉～',
          conditionText: '建立第二個帳戶',
          target: 2,
        );
      case AchievementId.firstBudget:
        return const AchievementDefinition(
          achievementId: AchievementId.firstBudget,
          name: '精打細算',
          description: '首次設定並啟用預算，理財更上一層樓！',
          conditionText: '設定並啟用預算',
          target: 1,
        );
      case AchievementId.firstCustomTag:
        return const AchievementDefinition(
          achievementId: AchievementId.firstCustomTag,
          name: '分類強迫症',
          description: '建立並用上自訂分類或標籤，帳目一目了然～',
          conditionText: '建立並使用自訂標籤',
          target: 1,
        );
      case AchievementId.budgetGuardian:
        return const AchievementDefinition(
          achievementId: AchievementId.budgetGuardian,
          name: '預算守門員',
          description: '單月支出沒爆預算，守得好！',
          conditionText: '單月支出未超過預算',
          target: 1,
        );
      case AchievementId.positiveCashflow:
        return const AchievementDefinition(
          achievementId: AchievementId.positiveCashflow,
          name: '開源節流',
          description: '單月收入大於支出，正現金流達成，厲害！',
          conditionText: '單月收入大於支出',
          target: 1,
          repeatType: AchievementRepeatType.perPeriod,
        );
      case AchievementId.hundredEntries:
        return const AchievementDefinition(
          achievementId: AchievementId.hundredEntries,
          name: '百筆達成',
          description: '累積記帳滿 100 筆，持續記錄的習慣已經養成囉～',
          conditionText: '累積記帳 100 筆',
          target: 100,
        );
      case AchievementId.thousandEntries:
        return const AchievementDefinition(
          achievementId: AchievementId.thousandEntries,
          name: '記帳大師',
          description: '累積記帳滿 1,000 筆，我願稱你為記帳大師！',
          conditionText: '累積記帳 1,000 筆',
          target: 1000,
        );
      case AchievementId.oneYear:
        return const AchievementDefinition(
          achievementId: AchievementId.oneYear,
          name: '歲月如梭',
          description: '使用滿一週年，感謝你一路相伴～',
          conditionText: '使用滿一週年',
          target: 1,
        );
      case AchievementId.nightOwl:
        return const AchievementDefinition(
          achievementId: AchievementId.nightOwl,
          name: '夜貓子',
          description: '凌晨 2～4 點還在記帳，夜貓認證！',
          conditionText: '在凌晨 2～4 點記帳',
          target: 1,
          isSecret: true,
        );
      case AchievementId.lucky777:
        return const AchievementDefinition(
          achievementId: AchievementId.lucky777,
          name: '幸運七七七',
          description: '單筆金額出現 777，幸運數字眷顧你。',
          conditionText: '單筆金額包含 777',
          target: 1,
          isSecret: true,
        );
    }
  }
}

class AchievementDefinition {
  const AchievementDefinition({
    required this.achievementId,
    required this.name,
    required this.description,
    required this.conditionText,
    required this.target,
    this.repeatType = AchievementRepeatType.oneTime,
    this.isSecret = false,
  });

  final AchievementId achievementId;
  final String name;
  final String description;
  final String conditionText;
  final int target;
  final AchievementRepeatType repeatType;
  final bool isSecret;

  String get id => achievementId.key;
}

const List<AchievementId> _achievementDisplayOrder = [
  AchievementId.firstEntry,
  AchievementId.firstIncome,
  AchievementId.streak7Days,
  AchievementId.streak30Days,
  AchievementId.streak100Days,
  AchievementId.monthlyPerfect,
  AchievementId.fourWeekendsStreak,
  AchievementId.backfillStreak3,
  AchievementId.secondAccount,
  AchievementId.firstBudget,
  AchievementId.firstCustomTag,
  AchievementId.budgetGuardian,
  AchievementId.positiveCashflow,
  AchievementId.hundredEntries,
  AchievementId.thousandEntries,
  AchievementId.oneYear,
  AchievementId.nightOwl,
  AchievementId.lucky777,
];

List<AchievementDefinition> get achievementDefinitions =>
    _achievementDisplayOrder.map((id) => id.definition).toList();
