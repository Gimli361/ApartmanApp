import 'package:flutter/material.dart';
import '../../../core/strings.dart';

class OylamaListScreen extends StatelessWidget {
  const OylamaListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.how_to_vote_outlined,
                  size: 48,
                  color: Colors.purple,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Oylamalar',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Apartman kararları için oy kullanın, açık oylamaları takip edin ve geçmiş sonuçları görüntüleyin.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], height: 1.5),
              ),
              const SizedBox(height: 32),
              OutlinedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.schedule),
                label: const Text('Yakında'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
