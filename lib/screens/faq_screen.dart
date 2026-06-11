import 'package:flutter/material.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  static const List<_FaqItem> leftItems = [
    _FaqItem(
      icon: '❓',
      question: 'Kako se mogu prijaviti na nadolazeće aktivnosti BKIC SAFF-a?',
      answer:
          'Prijaviti se možete putem online prijave na našoj web stranici u rubrici “Arrangemeter / Događaji”. Nakon prijave dobit ćete potvrdu e-mailom.',
      open: true,
    ),
    _FaqItem(
      icon: '🎟️',
      question: 'Koje vrste događaja organizuje BKIC SAFF?',
      answer:
          'Organizujemo radionice, predavanja, druženja, mrežne susrete i društvene aktivnosti za članove i prijatelje udruženja.',
    ),
    _FaqItem(
      icon: '⭐',
      question: 'Da li postoje pogodnosti za članove?',
      answer:
          'Da. Članovi često imaju povoljnije kotizacije, prioritet pri prijavi i pristup određenim ekskluzivnim događajima.',
    ),
    _FaqItem(
      icon: '🧾',
      question: 'Kako mogu postati član?',
      answer:
          'Na stranici “Članstvo” možete izabrati plan, popuniti prijavu i završiti uplatu.',
    ),
  ];

  static const List<_FaqItem> rightItems = [
    _FaqItem(
      icon: '📍',
      question: 'Gdje se aktivnosti održavaju?',
      answer:
          'Većina aktivnosti se održava u Odense-u. Tačna lokacija i vrijeme uvijek su navedeni u opisu događaja.',
    ),
    _FaqItem(
      icon: '✉️',
      question: 'Kako vas mogu kontaktirati?',
      answer:
          'Najbrže je preko stranice Kontakt ili putem e-maila: kontakt@bkicsaff.dk.',
    ),
    _FaqItem(
      icon: '⏱️',
      question: 'Koliko brzo odgovarate?',
      answer:
          'Obično odgovaramo u roku od 24 sata radnim danima. Vikendom može potrajati malo duže.',
    ),
    _FaqItem(
      icon: '🔒',
      question: 'Da li su moji podaci sigurni?',
      answer:
          'Da. Vaše podatke koristimo isključivo za organizaciju aktivnosti i komunikaciju, i ne dijelimo ih trećim stranama.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final allItems = [...leftItems, ...rightItems];

    return Container(
      color: const Color(0xFFFAF8F3),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _topBar(),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE8E1D5)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 24,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Često postavljana pitanja',
                  style: TextStyle(
                    color: Color(0xFF183B32),
                    fontSize: 34,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Text(
                  'BKIC SAFF Odense',
                  style: TextStyle(
                    color: Color(0xFFCAA25A),
                    fontSize: 34,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Ovdje možete brzo pronaći odgovore o članstvu, događajima i aktivnostima. Ako ne nađete ono što tražite, slobodno nam pišite – rado ćemo pomoći.',
                  style: TextStyle(
                    color: Color(0xFF6E6558),
                    fontSize: 15,
                    height: 1.7,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F5EF),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFE8E1D5)),
                  ),
                  child: Column(
                    children: allItems
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _FaqTile(item: item),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F5EF),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE8E1D5)),
                  ),
                  child: const Text(
                    'Ne možete pronaći odgovor? Posjetite stranicu Kontakt i pošaljite nam poruku. U naslov poruke možete napisati HITNO ako je zaista važno.',
                    style: TextStyle(
                      color: Color(0xFF6E6558),
                      fontSize: 13,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _topBar() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8E1D5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFCAA25A),
                  Color(0xFFF4E8CF),
                ],
              ),
            ),
            alignment: Alignment.center,
            child: const Text(
              'BK',
              style: TextStyle(
                color: Color(0xFF1B1408),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BKIC SAFF Odense',
                  style: TextStyle(
                    color: Color(0xFF183B32),
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Zajednica • Aktivnosti • Članstvo',
                  style: TextStyle(
                    color: Color(0xFF6E6558),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'FAQ',
                style: TextStyle(
                  color: Color(0xFF183B32),
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
              Text(
                'Pitanja i odgovori',
                style: TextStyle(
                  color: Color(0xFF8A8174),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FaqTile extends StatefulWidget {
  final _FaqItem item;

  const _FaqTile({
    required this.item,
  });

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  late bool open;

  @override
  void initState() {
    super.initState();
    open = widget.item.open;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8E1D5)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          setState(() {
            open = !open;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4E8CF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE8D7B5)),
                    ),
                    alignment: Alignment.center,
                    child: Text(widget.item.icon),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.item.question,
                      style: const TextStyle(
                        color: Color(0xFF183B32),
                        fontSize: 15,
                        height: 1.3,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 160),
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Color(0xFF6E6558),
                    ),
                  ),
                ],
              ),
              if (open) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.only(left: 42),
                  child: Text(
                    widget.item.answer,
                    style: const TextStyle(
                      color: Color(0xFF6E6558),
                      fontSize: 14,
                      height: 1.7,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FaqItem {
  final String icon;
  final String question;
  final String answer;
  final bool open;

  const _FaqItem({
    required this.icon,
    required this.question,
    required this.answer,
    this.open = false,
  });
}