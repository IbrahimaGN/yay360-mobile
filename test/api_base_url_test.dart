import 'package:flutter_test/flutter_test.dart';
import 'package:yay360_mobile/data/api_client.dart';

void main() {
  test('la PWA vise le relais /api du site qui l’héberge', () {
    expect(ApiClient.resoudreBaseUrl('/api', estWeb: true, origineWeb: 'https://yay360.duckdns.org'),
        'https://yay360.duckdns.org/api');
  });

  test('une adresse absolue est utilisée telle quelle', () {
    expect(ApiClient.resoudreBaseUrl('https://yay360-api.onrender.com', estWeb: false, origineWeb: ''),
        'https://yay360-api.onrender.com');
  });

  test('sans configuration : API locale (navigateur ou émulateur Android)', () {
    expect(ApiClient.resoudreBaseUrl('', estWeb: true, origineWeb: 'http://localhost:4200'), 'http://localhost:8080');
    expect(ApiClient.resoudreBaseUrl('', estWeb: false, origineWeb: ''), 'http://10.0.2.2:8080');
  });
}
