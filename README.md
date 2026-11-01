# YAY360 Mobile

Application Flutter pour les femmes enceintes et leur conjoint, connectée à l'API Spring Boot YAY360.

## Fonctionnalités

- Inscription patiente, connexion et création du compte conjoint à partir d'une invitation.
- Session JWT conservée dans le stockage sécurisé de l'appareil.
- Déclaration de grossesse et tableau de bord (semaine, date prévue, rendez-vous à venir).
- Repères prénataux hebdomadaires, demandes de rendez-vous et signalement de symptômes.
- Invitation du conjoint au dossier familial.
- Assistant IA conversationnel avec consentement explicite avant chaque envoi, historique limité à 12 messages et avertissement médical.
- Thèmes clair et sombre, commutables depuis l'écran de connexion et l'en-tête de l'application.

L'identité visuelle utilise le rose poudré `#E87A90`, le teal médical `#2A9D8F`, des neutres doux et des couleurs dédiées aux états de succès, de vigilance et d'urgence.

L'assistant fournit des informations générales, ne pose pas de diagnostic et ne remplace pas un professionnel de santé. Le message et l'historique soumis sont transmis au fournisseur IA configuré par l'API. Ne saisissez pas de données directement identifiantes. L'assistant reste indisponible tant qu'il n'est pas configuré côté backend.

## Lancer l'application

Prérequis : Flutter 3.44 ou une version compatible avec le Dart SDK `^3.12.2`, et l'API YAY360 lancée sur le port 8080.

```bash
flutter pub get
flutter run
```

L'URL API est choisie selon la plateforme : Flutter Web utilise `http://localhost:8080`, et l'émulateur Android utilise `http://10.0.2.2:8080` pour joindre l'ordinateur hôte. Pour un simulateur iOS ou un appareil physique, indiquez une URL accessible depuis cet appareil :

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8080
```

Remplacez `192.168.1.10` par l'adresse IP locale de l'ordinateur qui exécute l'API. L'accès HTTP est prévu pour le développement local ; configurez HTTPS pour tout déploiement.

## Lancer la plateforme mobile

L'application mobile se lance indépendamment de Docker Compose. Démarrez d'abord l'API YAY360 sur le port 8080, puis lancez Flutter depuis ce dossier :

```bash
flutter run
```

Pour lancer la version Web mobile dans un navigateur :

```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080
```

Pour produire et lancer une application Android native sur un émulateur ou un téléphone, utilisez `flutter run` ou `flutter build apk` ; Compose ne démarre pas l'application mobile.

Pour ouvrir la version mobile Web sur un téléphone du même réseau, configurez une URL d'API joignable depuis ce téléphone, par exemple `--dart-define=API_BASE_URL=http://192.168.1.10:8080`. Configurez également le backend pour autoriser l'origine du frontend mobile utilisé.

Les invitations de conjoint ne peuvent pas être envoyées par e-mail tant que le fournisseur d'e-mail du backend n'est pas configuré. Le backend journalise le token d'invitation pour les essais.

## Vérifier

```bash
flutter analyze
flutter test
```
