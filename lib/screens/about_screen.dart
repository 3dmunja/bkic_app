import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const String _logoUrl =
      'https://bkicsaff.dk/wp-content/uploads/2026/06/BKIC_SAFF_Logo_2.png';

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [
                Color(0xFFF7F4EC),
                Color(0xFFFFFFFF),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
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
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'O nama',
                style: TextStyle(
                  color: Color(0xFFCAA25A),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
              SizedBox(height: 18),
              Text(
                'Uđite u svijet BKIC SAFF-a',
                style: TextStyle(
                  color: Color(0xFF183B32),
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              SizedBox(height: 18),
              Text(
                'BKIC SAFF Odense je zajednica koja okuplja članove kroz vjeru, kulturu i međusobnu podršku. Naš cilj je da gradimo snažne veze, njegujemo tradiciju i stvaramo prostor u kojem se svi osjećaju dobrodošlo.',
                style: TextStyle(
                  color: Color(0xFF6E6558),
                  fontSize: 16,
                  height: 1.7,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Kroz aktivnosti, događaje i zajedničke projekte radimo na jačanju zajedništva i podršci porodicama, posebno kroz edukaciju, humanitarni rad i društveni angažman.',
                style: TextStyle(
                  color: Color(0xFF6E6558),
                  fontSize: 16,
                  height: 1.7,
                ),
              ),
              SizedBox(height: 22),
              _AboutCheckItem(
                text:
                    'Jasna misija i vrijednosti zasnovane na zajedništvu i poštovanju',
              ),
              _AboutCheckItem(
                text: 'Aktivnosti i događaji za sve generacije',
              ),
              _AboutCheckItem(
                text: 'Transparentan rad i podrška projektima džemata',
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
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
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  color: const Color(0xFFF8F5EF),
                  child: Image.network(
                    _logoUrl,
                    width: double.infinity,
                    height: 260,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Container(
                      height: 260,
                      color: const Color(0xFFF8F5EF),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.image_not_supported_outlined,
                        color: Color(0xFF8A8174),
                        size: 42,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F5EF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE8E1D5)),
                ),
                child: const Text(
                  'Zajedništvo, podrška i aktivan život zajednice u BKIC SAFF Odense.',
                  style: TextStyle(
                    color: Color(0xFF6E6558),
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AboutCheckItem extends StatelessWidget {
  final String text;

  const _AboutCheckItem({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '✓',
            style: TextStyle(
              color: Color(0xFFCAA25A),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF2F302C),
                fontSize: 15.5,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}