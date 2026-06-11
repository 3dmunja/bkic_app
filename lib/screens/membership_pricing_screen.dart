import 'package:flutter/material.dart';

class MembershipPricingScreen extends StatelessWidget {
  const MembershipPricingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
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
            border: Border.all(color: Color(0xFFE6DDCC)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 24,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: const Column(
            children: [
              Text(
                'Cjenik članstva',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF183B32),
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 14),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: 'Članarina od '),
                    TextSpan(
                      text: '2026',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    TextSpan(text: ' iznosi '),
                    TextSpan(
                      text: '1000 DKK',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    TextSpan(text: ' godišnje za zaposlene i '),
                    TextSpan(
                      text: '700 DKK',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    TextSpan(
                      text:
                          ' godišnje za studente, penzionere i ostale. Moguće je plaćanje u mjesečnim ratama.',
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF6E6558),
                  fontSize: 16,
                  height: 1.7,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const _PricingCard(
          title: 'Mjesečna članarina (zaposleni)',
          subtitle: 'Mjesečne rate za članove koji su u radnom odnosu.',
          price: '83,33',
          suffix: 'DKK / mjesečno',
          items: [
            'Godišnje: 1000 DKK',
            'Pristup članskom dijelu',
            'Obavijesti i događaji',
            'Uređivanje profila',
          ],
          note: 'Nakon registracije odabireš kategoriju i nastavljaš na uplatu.',
        ),
        const SizedBox(height: 18),
        const _PricingCard(
          highlighted: true,
          title: 'Mjesečna članarina (studenti / penzioneri)',
          subtitle:
              'Snižena članarina za studente, penzionere i ostale u ovoj kategoriji.',
          price: '58,33',
          suffix: 'DKK / mjesečno',
          items: [
            'Godišnje: 700 DKK',
            'Sve pogodnosti članstva',
            'Mjesečno plaćanje bez komplikacija',
            'Stabilna podrška džematu',
          ],
          note: 'Odaberi ovu opciju ako spadaš u sniženu kategoriju.',
        ),
        const SizedBox(height: 18),
        const _PricingCard(
          title: 'Donacija',
          subtitle: 'Dobrovoljna podrška radu džemata.',
          price: '—',
          suffix: 'po želji',
          items: [
            'Pomaže projekte i aktivnosti',
            'Bez obaveze članstva',
            'Svaka pomoć je vrijedna',
          ],
          note: 'Može i bankom / MobilePay.',
        ),
      ],
    );
  }
}

class _PricingCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String price;
  final String suffix;
  final List<String> items;
  final String note;
  final bool highlighted;

  const _PricingCard({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.suffix,
    required this.items,
    required this.note,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: highlighted
              ? const Color(0xFFCAA25A)
              : const Color(0xFFE9E2D5),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (highlighted) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFF4E8CF),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'Preporučeno',
                style: TextStyle(
                  color: Color(0xFF7A5A1F),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF183B32),
              fontSize: 24,
              fontWeight: FontWeight.w900,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF6E6558),
              fontSize: 15,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F5EF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE6DDCC)),
            ),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.end,
              spacing: 10,
              children: [
                Text(
                  price,
                  style: const TextStyle(
                    color: Color(0xFF183B32),
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    suffix,
                    style: const TextStyle(
                      color: Color(0xFF6E6558),
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '✓',
                    style: TextStyle(
                      color: Color(0xFFCAA25A),
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: Color(0xFF2F302C),
                        fontSize: 16,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            note,
            style: const TextStyle(
              color: Color(0xFF7B7164),
              fontSize: 13.5,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}