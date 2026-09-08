# Mission Ninja

Une app d'entraînement pour la 1re année, à l'école Notre-Dame-de-La-Paix. L'enseignante distribue un plan de leçons par semaine; l'app en prend la partie répétitive et la rend jouable: reconnaître les voyelles et leur bruit, chanter l'alphabet, lire les chiffres de 0 à 9, compter, et écrire les lettres au doigt. Le reste du plan, celui qui se fait sur papier, se coche dans le carnet.

Thème ninja et blocs de construction, bleu et noir, tout en français canadien. Chaque bouton est une brique qui s'enfonce quand on appuie, la mascotte est un petit ninja à cagoule avec son katana, et chaque lettre de l'alphabet trouvée pose une brique d'un dragon que le ninja combat une fois fini. Chaque entraînement terminé se célèbre par une petite scène animée: le dragon, une pile de briques abattue au shuriken, ou une tour à escalader. Une voix dit chaque consigne, parce qu'il ne lit pas encore. Les étoiles gagnées font monter les ceintures, de la blanche à la noire.

Tout est généré en code: aucune dépendance tierce, aucun fichier audio, aucune image. Les effets sonores sont synthétisés au lancement, l'icône vient d'un script, le dragon est une mosaïque écrite en texte, et les lettres à tracer sont des suites de traits écrites à la main dans l'ordre où on les enseigne.

## Build

Xcode 27 ou plus récent, et `brew install xcodegen`.

```
make project   # génère MissionNinja.xcodeproj depuis project.yml
make test      # tests unitaires sur le simulateur iPhone
make run       # compile, installe et lance sur le simulateur
make ipad      # la même chose sur un simulateur iPad
make shot      # capture d'écran du simulateur dans .build/
make icon      # régénère l'icône
make lsp       # buildServer.json pour Zed, VS Code et Neovim
```

Le projet Xcode n'est pas versionné: `make project` le régénère, et le workflow aussi.

Pour tester la voix, il faut un appareil réel. Le simulateur n'a pratiquement aucune voix installée.

## Structure

```
Sources/MissionNinja/
  App/        la scène SwiftUI et l'aiguillage
  Model/      semaine, jour, glyphe, ceinture, géométrie
  Content/    catalogue des semaines, fabrique d'épreuves, bibliothèque de glyphes, plan du dragon
  Engine/     session d'entraînement, validateur de tracé, générateur aléatoire
  Store/      progression, statistiques, persistance
  Speech/     choix de la voix et prononciation
  Audio/      synthèse des effets sonores
  Theme/      palette, teintes de brique, typographie
  Views/      les écrans et leurs composants, dont la brique et le dragon
Resources/Weeks/   un fichier JSON par semaine
Tests/             la suite Swift Testing
scripts/           générateur d'icône, options d'export
```

`Model`, `Content`, `Engine` et `Store` n'importent jamais SwiftUI. Toute la logique est donc testable sans simulateur, et c'est là que vivent les règles: quelle semaine ouvrir, quelle épreuve poser, quand une étoile est gagnée, quand un trait est réussi.

## Ajouter une semaine

Une semaine est un fichier `Resources/Weeks/<lundi>.json`, nommé par la date du lundi:

```json
{
  "schema": 1,
  "id": "2026-09-14",
  "title": "Semaine du 14 au 18 septembre 2026",
  "grade": "1re année",
  "teacher": "Mme Catherine",
  "days": [
    { "name": "lundi", "atSchool": true, "note": null }
  ],
  "letters": { "vowels": ["a", "e", "i"], "alphabet": true },
  "numbers": { "from": 0, "to": 9, "counting": true },
  "tracing": ["a", "e", "i"],
  "tasks": [
    { "id": "deux-lignes", "title": "Je lis deux lignes", "place": "Duo-tang rouge, p. 2" }
  ]
}
```

L'app charge tous les fichiers du dossier, les trie, et ouvre par défaut la plus récente déjà commencée. Les autres restent accessibles depuis l'écran de lancement. Une nouvelle semaine passe donc par une PR et un merge, et TestFlight livre le build.

Les caractères de `tracing` doivent exister dans `GlyphLibrary`. Aujourd'hui: `a e i o u` en minuscule et majuscule, plus `0` à `9`.

## Écran pour les parents

Appui long de trois secondes sur le badge de ceinture. Il montre la réussite par caractère et par exercice, la série de jours, et la voix que la synthèse a réellement trouvée. Si elle n'est pas québécoise, le chemin des réglages iOS y est indiqué.

## Livraison à TestFlight

Chaque merge sur `master` déclenche `.github/workflows/testflight.yml`: archive, signature, envoi à App Store Connect, puis pose du tag. Le numéro de build est le numéro d'exécution du workflow; la version vient du dernier tag `v*`, un titre de PR en `feat` incrémente le mineur, le reste le correctif. `[skip-release]` dans le titre de la PR saute l'étape.

Le workflow lit le nom du profil de provisionnement dans le `.mobileprovision` lui-même, donc renommer le profil du côté d'Apple ne casse rien.

Secrets du dépôt:

| Secret | Contenu |
| --- | --- |
| `APPLE_DIST_CERT_P12` | base64 du `.p12` Apple Distribution |
| `APPLE_DIST_CERT_PASSWORD` | son mot de passe d'export |
| `APPLE_PROVISIONING_PROFILE` | base64 du `.mobileprovision` |
| `APPLE_KEY_P8` | base64 de la clé d'API `.p8` |
| `APPLE_KEY_ID` | identifiant de la clé |
| `APPLE_ISSUER_ID` | identifiant de l'émetteur |

Les cinq premiers, sauf le profil, valent pour tout le compte Apple et sont donc les mêmes que dans les autres dépôts. Le certificat et le profil expirent au bout d'un an.
