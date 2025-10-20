import 'dart:math';

class BotNameGenerator {
  /// 입문자/초보자/초급용 봇 이름 50개 (beginner/rookie/easy)
  static final List<String> easyPoolNames = [
    'James Smith', 'John Johnson', 'Robert Williams', 'Michael Brown', 'William Jones',
    'David Garcia', 'Richard Miller', 'Joseph Davis', 'Thomas Rodriguez', 'Charles Martinez',
    'Mary Anderson', 'Patricia Taylor', 'Jennifer Thomas', 'Linda Moore', 'Barbara Jackson',
    'Elizabeth Martin', 'Susan Lee', 'Jessica Thompson', 'Sarah White', 'Karen Harris',
    'Daniel Clark', 'Matthew Lewis', 'Anthony Robinson', 'Mark Walker', 'Donald Young',
    'Steven Allen', 'Paul King', 'Andrew Wright', 'Joshua Lopez', 'Kenneth Hill',
    'Emily Scott', 'Ashley Green', 'Lisa Adams', 'Nancy Baker', 'Betty Gonzalez',
    'Margaret Nelson', 'Sandra Carter', 'Dorothy Mitchell', 'Kimberly Perez', 'Donna Roberts',
    'Christopher Turner', 'Brian Phillips', 'George Campbell', 'Edward Parker', 'Ronald Evans',
    'Timothy Edwards', 'Jason Collins', 'Jeffrey Stewart', 'Ryan Morris', 'Jacob Rogers',
  ];

  /// 중급용 봇 이름 50개 (medium) - 겹치지 않음
  static final List<String> mediumPoolNames = [
    'Nicholas Murphy', 'Alexander Cook', 'Eric Bailey', 'Stephen Rivera', 'Kevin Cooper',
    'Larry Reed', 'Justin Bailey', 'Scott Howard', 'Brandon Ward', 'Benjamin Torres',
    'Samuel Peterson', 'Frank Gray', 'Gregory Ramirez', 'Raymond James', 'Patrick Watson',
    'Jack Brooks', 'Dennis Kelly', 'Jerry Sanders', 'Tyler Price', 'Aaron Bennett',
    'Jose Wood', 'Adam Barnes', 'Henry Ross', 'Nathan Henderson', 'Douglas Coleman',
    'Zachary Jenkins', 'Peter Perry', 'Kyle Powell', 'Walter Long', 'Ethan Patterson',
    'Jeremy Hughes', 'Harold Flores', 'Keith Washington', 'Christian Butler', 'Roger Simmons',
    'Noah Foster', 'Gerald Gonzales', 'Carl Bryant', 'Terry Alexander', 'Sean Russell',
    'Austin Griffin', 'Arthur Diaz', 'Lawrence Hayes', 'Jesse Myers', 'Dylan Ford',
    'Jordan Hamilton', 'Bryan Graham', 'Billy Sullivan', 'Bruce Wallace', 'Albert Woods',
  ];

  /// 고급용 봇 이름 50개 (hard) - 겹치지 않음
  static final List<String> hardPoolNames = [
    'Willie Wells', 'Gabriel Webb', 'Logan Simpson', 'Alan Stevens', 'Juan Tucker',
    'Philip Porter', 'Randy Hunter', 'Harry Hicks', 'Vincent Crawford', 'Bobby Henry',
    'Johnny Boyd', 'Russell Mason', 'Louis Morales', 'Howard Kennedy', 'Eugene Warren',
    'Carlos Dixon', 'Todd Ramos', 'Jesse Reyes', 'Earl Burns', 'Cameron Gordon',
    'Travis Shaw', 'Jeffrey Holmes', 'Leonard Rice', 'Keith Robertson', 'Joe Hunt',
    'Danny Black', 'Dustin Daniels', 'Harold Palmer', 'Curtis Mills', 'Sean Nichols',
    'Luis Grant', 'Erik Knight', 'Tony Ferguson', 'Glen Stone', 'Corey Hawkins',
    'Phillip Dunn', 'Marcus Perkins', 'Mitchell Hudson', 'Jerome Spencer', 'Terrence Gardner',
    'Oscar Stephens', 'Chester Payne', 'Lester Pierce', 'Franklin Berry', 'Calvin Matthews',
    'Eddie Lawrence', 'Norman Chambers', 'Maurice Holt', 'Clifford Quinn', 'Leroy Soto',
  ];

  /// 난이도별 봇 이름 생성 (시드 기반)
  static String generateName({required int seed, required String difficulty}) {
    List<String> pool;

    if (difficulty == 'beginner' || difficulty == 'rookie' || difficulty == 'easy') {
      pool = easyPoolNames;
    } else if (difficulty == 'medium') {
      pool = mediumPoolNames;
    } else if (difficulty == 'hard') {
      pool = hardPoolNames;
    } else {
      // 기본값: easy pool
      pool = easyPoolNames;
    }

    final random = Random(seed);
    return pool[random.nextInt(pool.length)];
  }

  /// 랜덤 이름 생성 (테스트용)
  static String generateRandomName({String difficulty = 'beginner'}) {
    final random = Random();
    return generateName(seed: random.nextInt(1000000), difficulty: difficulty);
  }
}
