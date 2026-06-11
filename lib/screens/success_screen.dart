import 'package:flutter/material.dart';

class SuccessScreen extends StatelessWidget {
  const SuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Container(
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              colors: [
                Color(0xFFF7F4EC),
                Color(0xFFFFFFFF),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: Color(0xFFE8E1D5)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 24,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            children: [
              const Text(
                '🌿 Uspjeh u islamu',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  color: Color(0xFF183B32),
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'U svijetu gdje se uspjeh često mjeri novcem, statusom i slavom,\n'
                'pravi uspjeh nije ono što posjedujemo — već ono što nosimo u svom srcu.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  height: 1.7,
                  color: Color(0xFF6E6558),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'U islamu, uspjeh znači živjeti život ispunjen vjerom, iskrenošću i dobrim djelima.\n'
                'Najveći uspjeh nije prolazan — on je vječan.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  height: 1.7,
                  color: Color(0xFF6E6558),
                ),
              ),
              const SizedBox(height: 22),
              _quoteBox(
                '“Onaj ko bude udaljen od Vatre i uveden u Džennet — taj je uspio.”',
                '(Ali ‘Imran, 185)',
              ),
              const SizedBox(height: 18),
              _quoteBox(
                '“Uspio je onaj ko svoju dušu očisti.”',
                '(Eš-Šems, 9)',
              ),
              const SizedBox(height: 22),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Bullet(text: 'Iskrena vjera'),
                  _Bullet(text: 'Dobra djela'),
                  _Bullet(text: 'Pomaganje drugima'),
                  _Bullet(text: 'Povratak Allahu (tevba)'),
                ],
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F5EF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE8E1D5)),
                ),
                child: const Column(
                  children: [
                    Text(
                      '“A Allahovo zadovoljstvo je veće od svega.”',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF183B32),
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      '(Et-Tevbe, 72)',
                      style: TextStyle(
                        color: Color(0xFF9F7A32),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '🤲 Kada srce pronađe mir — tada počinje prava sreća.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  color: Color(0xFF183B32),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _quoteBox(String text, String source) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8E1D5)),
      ),
      child: Column(
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontStyle: FontStyle.italic,
              color: Color(0xFF183B32),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            source,
            style: const TextStyle(
              color: Color(0xFF9F7A32),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;

  const _Bullet({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          const Text(
            '✔',
            style: TextStyle(
              color: Color(0xFFCAA25A),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF2F302C),
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}