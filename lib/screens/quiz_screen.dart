import 'dart:math';
import 'package:flutter/material.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int sectionIndex = 0;
  int questionIndex = 0;
  int points = 0;
  bool answered = false;
  bool finished = false;

  late List<_Answer> shuffledAnswers;

  final List<_QuizSection> sections = [
    _QuizSection(
      title: '🕌 Islamski šarti',
      intro: 'U ovoj sekciji učiš 5 islamskih šarta — osnovne dužnosti u islamu.',
      questions: [
        _Question('Koliko islamskih šarta ima?', ['5', '6', '4'], 0, 'Tačno! Islam ima 5 šarta.', 'Netačno. Islam ima 5 šarta.'),
        _Question('Koji je prvi islamski šart?', ['Namaz', 'Šehadet', 'Hadž'], 1, 'Tačno! Prvi islamski šart je šehadet.', 'Netačno. Prvi islamski šart je šehadet.'),
        _Question('Koliko puta dnevno klanjamo farz namaze?', ['5', '3', '2'], 0, 'Tačno! Klanjamo 5 dnevnih namaza.', 'Netačno. Farz namaza ima 5.'),
        _Question('U kojem mjesecu postimo?', ['Ramazan', 'Redžeb', 'Ševval'], 0, 'Tačno! Postimo u mjesecu Ramazanu.', 'Netačno. Posti se u Ramazanu.'),
        _Question('Šta je zekat?', ['Obavezno davanje dijela imetka', 'Vrsta namaza', 'Vrsta posta'], 0, 'Tačno! Zekat je obavezno davanje dijela imetka.', 'Netačno. Zekat je obavezno davanje dijela imetka.'),
        _Question('Gdje se obavlja hadž?', ['U Medini', 'U Mekki', 'U Jerusalemu'], 1, 'Tačno! Hadž se obavlja u Mekki.', 'Netačno. Hadž se obavlja u Mekki.'),
        _Question('Da li je namaz jedan od islamskih šarta?', ['Da', 'Ne', 'Samo ponekad'], 0, 'Tačno! Namaz je jedan od islamskih šarta.', 'Netačno. Namaz jeste jedan od islamskih šarta.'),
        _Question('Da li je post jedan od islamskih šarta?', ['Ne', 'Da', 'Samo za odrasle muškarce'], 1, 'Tačno! Post je jedan od islamskih šarta.', 'Netačno. Post jeste jedan od islamskih šarta.'),
        _Question('Šta znači šehadet?', ['Svjedočenje vjere', 'Pranje prije namaza', 'Dobrovoljna sadaka'], 0, 'Tačno! Šehadet je svjedočenje vjere.', 'Netačno. Šehadet znači svjedočenje vjere.'),
        _Question('Koliko islamskih šarta musliman treba znati?', ['5', '10', '2'], 0, 'Tačno! Musliman treba znati 5 islamskih šarta.', 'Netačno. Islamskih šarta ima 5.'),
      ],
    ),
    _QuizSection(
      title: '💡 Imanski šarti',
      intro: 'U ovoj sekciji učiš 6 imanskih šarta — u šta musliman vjeruje.',
      questions: [
        _Question('Koliko imanskih šarta ima?', ['5', '6', '7'], 1, 'Tačno! Ima 6 imanskih šarta.', 'Netačno. Imanskih šarta ima 6.'),
        _Question('U koga vjerujemo kao Jednog Boga?', ['U meleke', 'U Allaha', 'U sunce'], 1, 'Tačno! Vjerujemo u Allaha.', 'Netačno. Musliman vjeruje u Allaha.'),
        _Question('Da li musliman vjeruje u meleke?', ['Da', 'Ne', 'Samo petkom'], 0, 'Tačno! Musliman vjeruje u meleke.', 'Netačno. Musliman vjeruje u meleke.'),
        _Question('Da li musliman vjeruje u Allahove knjige?', ['Da', 'Ne', 'Samo Kur\'an'], 0, 'Tačno! Musliman vjeruje u Allahove knjige.', 'Netačno. Musliman vjeruje u Allahove knjige.'),
        _Question('Da li musliman vjeruje u poslanike?', ['Da', 'Ne', 'Samo u jednog'], 0, 'Tačno! Musliman vjeruje u poslanike.', 'Netačno. Musliman vjeruje u poslanike.'),
        _Question('Da li musliman vjeruje u Sudnji dan?', ['Da', 'Ne', 'Samo stariji ljudi'], 0, 'Tačno! Musliman vjeruje u Sudnji dan.', 'Netačno. Musliman vjeruje u Sudnji dan.'),
        _Question('Šta je kader?', ['Allahova odredba', 'Vrsta dove', 'Mjesto za namaz'], 0, 'Tačno! Kader je Allahova odredba.', 'Netačno. Kader znači Allahova odredba.'),
        _Question('U šta musliman vjeruje pored Allaha?', ['U meleke', 'U sreću bez Allaha', 'U kipove'], 0, 'Tačno! Musliman vjeruje u meleke.', 'Netačno. Musliman vjeruje u meleke.'),
        _Question('Koliko je ukupno imanskih šarta?', ['4', '6', '8'], 1, 'Tačno! Ukupno je 6 imanskih šarta.', 'Netačno. Imanskih šarta ima 6.'),
        _Question('Da li je vjerovanje u Allahove knjige dio imana?', ['Da', 'Ne', 'Samo za hodže'], 0, 'Tačno! Vjerovanje u knjige je dio imana.', 'Netačno. To jeste dio imana.'),
      ],
    ),
    _QuizSection(
      title: '💧 Abdest',
      intro: 'U ovoj sekciji učiš šta je abdest, kako se uzima i šta ga kvari.',
      questions: [
        _Question('Šta je abdest?', ['Čišćenje prije namaza', 'Vrsta jela', 'Poseban bajram'], 0, 'Tačno! Abdest je čišćenje prije namaza.', 'Netačno. Abdest je čišćenje prije namaza.'),
        _Question('Da li trebamo imati abdest prije namaza?', ['Da', 'Ne', 'Samo petkom'], 0, 'Tačno! Za namaz treba abdest.', 'Netačno. Za namaz je potreban abdest.'),
        _Question('Šta peremo u abdestu?', ['Ruke i lice', 'Samo kosu', 'Samo stopala'], 0, 'Tačno! U abdestu peremo ruke, lice, ruke do laktova i noge.', 'Netačno. Abdest uključuje više dijelova tijela.'),
        _Question('Da li odlazak u toalet kvari abdest?', ['Da', 'Ne', 'Samo noću'], 0, 'Tačno! Odlazak u toalet kvari abdest.', 'Netačno. To kvari abdest.'),
        _Question('Da li učenje dove kvari abdest?', ['Da', 'Ne', 'Uvijek'], 1, 'Tačno! Učenje dove ne kvari abdest.', 'Netačno. Dova ne kvari abdest.'),
        _Question('Da li puštanje vjetra kvari abdest?', ['Da', 'Ne', 'Samo djeci'], 0, 'Tačno! To kvari abdest.', 'Netačno. Puštanje vjetra kvari abdest.'),
        _Question('Da li dubok san može pokvariti abdest?', ['Da', 'Ne', 'Nikad'], 0, 'Tačno! Dubok san može pokvariti abdest.', 'Netačno. Dubok san može pokvariti abdest.'),
        _Question('Šta prvo peremo u abdestu?', ['Ruke', 'Noge', 'Leđa'], 0, 'Tačno! Na početku se peru ruke.', 'Netačno. Na početku abdesta peru se ruke.'),
        _Question('Da li trebamo oprati lice u abdestu?', ['Da', 'Ne', 'Samo petkom'], 0, 'Tačno! U abdestu peremo lice.', 'Netačno. Lice se pere u abdestu.'),
        _Question('Ako se abdest pokvari, šta radimo?', ['Uzmem opet abdest', 'Ništa', 'Samo proučim dovu'], 0, 'Tačno! Kada se abdest pokvari, treba ga obnoviti.', 'Netačno. Treba ponovo uzeti abdest.'),
      ],
    ),
    _QuizSection(
      title: '🕌 Namazi',
      intro: 'U ovoj sekciji učiš osnovne stvari o 5 dnevnih namaza.',
      questions: [
        _Question('Koliko farz namaza ima u danu?', ['5', '3', '7'], 0, 'Tačno! U danu ima 5 farz namaza.', 'Netačno. Ima 5 dnevnih namaza.'),
        _Question('Koliko farz rekata ima Sabah?', ['2', '4', '3'], 0, 'Tačno! Sabah ima 2 farz rekata.', 'Netačno. Sabah ima 2 farz rekata.'),
        _Question('Koliko farz rekata ima Podne?', ['4', '2', '3'], 0, 'Tačno! Podne ima 4 farz rekata.', 'Netačno. Podne ima 4 farz rekata.'),
        _Question('Koliko farz rekata ima Ikindija?', ['4', '3', '2'], 0, 'Tačno! Ikindija ima 4 farz rekata.', 'Netačno. Ikindija ima 4 farz rekata.'),
        _Question('Koliko farz rekata ima Akšam?', ['3', '4', '2'], 0, 'Tačno! Akšam ima 3 farz rekata.', 'Netačno. Akšam ima 3 farz rekata.'),
        _Question('Koliko farz rekata ima Jacija?', ['4', '2', '3'], 0, 'Tačno! Jacija ima 4 farz rekata.', 'Netačno. Jacija ima 4 farz rekata.'),
        _Question('Koji je prvi dnevni namaz?', ['Sabah', 'Akšam', 'Jacija'], 0, 'Tačno! Sabah je prvi dnevni namaz.', 'Netačno. Prvi dnevni namaz je Sabah.'),
        _Question('Koji namaz se klanja nakon zalaska sunca?', ['Akšam', 'Podne', 'Sabah'], 0, 'Tačno! Akšam se klanja nakon zalaska sunca.', 'Netačno. To je Akšam.'),
        _Question('Koji je noćni namaz?', ['Jacija', 'Ikindija', 'Podne'], 0, 'Tačno! Jacija je noćni namaz.', 'Netačno. Noćni namaz je Jacija.'),
        _Question('Da li musliman treba učiti namaz postepeno?', ['Da', 'Ne', 'Samo u školi'], 0, 'Tačno! Namaz se uči postepeno, s pažnjom i trudom.', 'Netačno. Namaz se uči postepeno.'),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _shuffleAnswers();
  }

  _Question get question => sections[sectionIndex].questions[questionIndex];

  int get totalQuestions => sections.fold(0, (sum, s) => sum + s.questions.length);

  int get completedQuestions {
    int done = 0;
    for (int i = 0; i < sectionIndex; i++) {
      done += sections[i].questions.length;
    }
    return done + questionIndex;
  }

  String get status {
    if (points >= 130) return 'Mašallah!';
    if (points >= 90) return 'Lijepo napreduje';
    if (points >= 50) return 'Vrijedni učenik';
    if (points >= 20) return 'Uči osnove';
    return 'Početnik';
  }

  void _shuffleAnswers() {
    shuffledAnswers = question.answers.asMap().entries.map((entry) {
      return _Answer(entry.value, entry.key == question.correctIndex);
    }).toList();

    shuffledAnswers.shuffle(Random());
  }

  void _answer(int index) {
    if (answered) return;

    final correct = shuffledAnswers[index].isCorrect;

    setState(() {
      answered = true;
      if (correct) points += 10;
    });

    if (!correct) {
      Future.delayed(const Duration(milliseconds: 1600), () {
        if (!mounted) return;
        setState(() {
          answered = false;
          _shuffleAnswers();
        });
      });
    }
  }

  void _next() {
    setState(() {
      questionIndex++;

      if (questionIndex >= sections[sectionIndex].questions.length) {
        sectionIndex++;
        questionIndex = 0;
      }

      if (sectionIndex >= sections.length) {
        finished = true;
        return;
      }

      answered = false;
      _shuffleAnswers();
    });
  }

  void _restart() {
    setState(() {
      sectionIndex = 0;
      questionIndex = 0;
      points = 0;
      answered = false;
      finished = false;
      _shuffleAnswers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = finished ? 1.0 : completedQuestions / totalQuestions;

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              colors: [
                Color(0xFFF7F4EC),
                Color(0xFFFFFFFF),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: const Color(0xFFE8E1D5)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 24,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: finished ? _finishedBox() : _quizBox(progress),
        ),
      ],
    );
  }

  Widget _quizBox(double progress) {
    final section = sections[sectionIndex];

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF4E8CF),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFE8D7B5)),
          ),
          child: const Text(
            '🕌 Uči islam korak po korak',
            style: TextStyle(
              color: Color(0xFF9F7A32),
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Dječiji islamski program',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF183B32),
            fontSize: 30,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Status: $status',
          style: const TextStyle(color: Color(0xFF2F302C), fontSize: 17),
        ),
        Text(
          'Bodovi: $points',
          style: const TextStyle(color: Color(0xFF2F302C), fontSize: 17),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Sekcija ${sectionIndex + 1} / ${sections.length}',
              style: const TextStyle(color: Color(0xFF6E6558)),
            ),
            Text(
              'Pitanje ${questionIndex + 1} / ${section.questions.length}',
              style: const TextStyle(color: Color(0xFF6E6558)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            backgroundColor: const Color(0xFFE8E1D5),
            valueColor: const AlwaysStoppedAnimation(Color(0xFFCAA25A)),
          ),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE8E1D5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                section.title,
                style: const TextStyle(
                  color: Color(0xFF183B32),
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                section.intro,
                style: const TextStyle(
                  color: Color(0xFF6E6558),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F5EF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE8E1D5)),
                ),
                child: const Text(
                  'Moraš tačno odgovoriti na svako pitanje da bi prešao/la dalje.',
                  style: TextStyle(color: Color(0xFF6E6558)),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                question.text,
                style: const TextStyle(
                  color: Color(0xFF183B32),
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              ...List.generate(shuffledAnswers.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _answerButton(index),
                );
              }),
              if (answered) _feedbackBox(),
              if (answered && shuffledAnswers.any((a) => a.isCorrect))
                const SizedBox(height: 10),
              if (answered && shuffledAnswers.any((a) => a.isCorrect))
                Center(
                  child: FilledButton(
                    onPressed: _next,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFCAA25A),
                      foregroundColor: const Color(0xFF1B1408),
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text(
                      'Sljedeće pitanje',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _answerButton(int index) {
    final answer = shuffledAnswers[index];

    Color bg = const Color(0xFFCAA25A);
    Color fg = const Color(0xFF1B1408);

    if (answered) {
      if (answer.isCorrect) {
        bg = const Color(0xFF2E8B57);
        fg = Colors.white;
      } else {
        bg = const Color(0xFFE8E1D5);
        fg = const Color(0xFF6E6558);
      }
    }

    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: answered ? null : () => _answer(index),
        style: FilledButton.styleFrom(
          backgroundColor: bg,
          disabledBackgroundColor: bg,
          foregroundColor: fg,
          disabledForegroundColor: fg,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(
          answer.text,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  Widget _feedbackBox() {
    final correct = shuffledAnswers.any((a) => a.isCorrect);
    final selectedCorrect = answered && correct;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8, bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: selectedCorrect ? const Color(0xFFEAF4EF) : const Color(0xFFFFEDEA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selectedCorrect ? const Color(0xFFBFDCCD) : const Color(0xFFF0C4BE),
        ),
      ),
      child: Text(
        selectedCorrect ? '✅ Tačno!\n${question.ok}' : '❌ Netačno.\n${question.bad}\n\nPokušaj ponovo da bi prešao/la dalje.',
        style: TextStyle(
          color: selectedCorrect ? const Color(0xFF0F4F3A) : const Color(0xFFB3261E),
          height: 1.5,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _finishedBox() {
    return Column(
      children: [
        const Text('🌟', style: TextStyle(fontSize: 44)),
        const SizedBox(height: 10),
        const Text(
          'Mašallah!',
          style: TextStyle(
            color: Color(0xFF183B32),
            fontSize: 30,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Osvojio/la si $points bodova i završio/la sve sekcije. Mašallah, naučio/la si mnogo o osnovama islama, abdesta i namaza.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF6E6558),
            fontSize: 18,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 18),
        FilledButton(
          onPressed: _restart,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFCAA25A),
            foregroundColor: const Color(0xFF1B1408),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: const Text(
            'Počni ponovo',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }
}

class _QuizSection {
  final String title;
  final String intro;
  final List<_Question> questions;

  _QuizSection({
    required this.title,
    required this.intro,
    required this.questions,
  });
}

class _Question {
  final String text;
  final List<String> answers;
  final int correctIndex;
  final String ok;
  final String bad;

  _Question(this.text, this.answers, this.correctIndex, this.ok, this.bad);
}

class _Answer {
  final String text;
  final bool isCorrect;

  _Answer(this.text, this.isCorrect);
}