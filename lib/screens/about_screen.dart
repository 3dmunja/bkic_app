import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const String _logoUrl =
      'https://bkicsaff.dk/wp-content/uploads/user_registration_uploads/profile-pictures/BKIC_SAFF_Logo_1.jpeg';

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
                Color(0xFF14110D),
                Color(0xFF0B0A08),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            border: Border.all(color: Color(0x22FFFFFF)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x88000000),
                blurRadius: 28,
                offset: Offset(0, 16),
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
                  color: Color(0xFFC9D4FF),
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              SizedBox(height: 18),
              Text(
                'BKIC SAFF Odense je zajednica koja okuplja članove kroz vjeru, kulturu i međusobnu podršku. Naš cilj je da gradimo snažne veze, njegujemo tradiciju i stvaramo prostor u kojem se svi osjećaju dobrodošlo.',
                style: TextStyle(
                  color: Color(0xFFBFB7AA),
                  fontSize: 16,
                  height: 1.7,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Kroz aktivnosti, događaje i zajedničke projekte radimo na jačanju zajedništva i podršci porodicama, posebno kroz edukaciju, humanitarni rad i društveni angažman.',
                style: TextStyle(
                  color: Color(0xFFBFB7AA),
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
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0x22FFFFFF)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x88000000),
                  blurRadius: 28,
                  offset: Offset(0, 16),
                ),
              ],
            ),
            child: Stack(
              children: [
                Image.network(
                  _logoUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 260,
                    color: const Color(0xFF171715),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.image_not_supported_outlined,
                      color: Colors.white54,
                      size: 42,
                    ),
                  ),
                ),
                Positioned(
                  left: 18,
                  right: 18,
                  bottom: 18,
                  child: Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: const Color(0xCC000000),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text(
                      'Zajedništvo, podrška i aktivan život zajednice u BKIC SAFF Odense.',
                      style: TextStyle(
                        color: Color(0xFFBFB7AA),
                        fontSize: 14,
                        height: 1.45,
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
                color: Color(0xFFF1EEE8),
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