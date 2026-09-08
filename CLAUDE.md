# CLAUDE.md

Ce dépôt est l'app iOS `Mission Ninja` (`dev.rbstp.missionninja`), construite pour mon garçon de 6 ans, en 1re année à l'école Notre-Dame-de-La-Paix. Son enseignante, Mme Catherine, distribue un plan de leçons en PDF chaque semaine. L'app en prend la partie répétitive et la rend jouable. Elle est distribuée par TestFlight à la famille seulement.

---

## Ajouter la semaine suivante

C'est la tâche récurrente, et presque la seule. Je fournis le PDF du plan de leçons; la marche à suivre est:

1. Extraire le texte du PDF. `pdftotext` n'est pas installé; utiliser PDFKit:

   ```
   swift - "<chemin du PDF>" <<'EOF'
   import Foundation
   import PDFKit
   let doc = PDFDocument(url: URL(fileURLWithPath: CommandLine.arguments[1]))!
   for i in 0..<doc.pageCount { print(doc.page(at: i)?.string ?? "") }
   EOF
   ```

2. Créer `Resources/Weeks/<date du lundi>.json`, en suivant le schéma de `2026-09-07.json`. Les champs qui demandent un jugement:
   - `days`: un jour par jour d'école, `atSchool: false` pour un congé, `note` pour ce qui sort de l'ordinaire (réunion, sortie, congé).
   - `letters.vowels` et `numbers`: ce que la semaine demande de reconnaître, rien de plus. Le plan de leçons est la limite; les leurres d'un exercice sont tirés dans la semaine, donc y ajouter des caractères non enseignés fausserait l'exercice.
   - `tracing`: les caractères à écrire au doigt. Chacun doit exister dans `GlyphLibrary`, sinon il est silencieusement ignoré.
   - `tasks`: les devoirs qui se font sur papier, un par ligne du plan, avec `place` pour le cahier et la page.

3. `make test`, puis une PR. Le merge sur `master` déclenche `testflight` et le build arrive sur l'appareil en une quinzaine de minutes.

Rien d'autre à toucher: l'app charge tous les fichiers du dossier, les trie, et ouvre par défaut la plus récente déjà commencée.

### Si la semaine demande un caractère sans tracé

`GlyphLibrary` couvre `a e i o u` en minuscule et majuscule, plus `0` à `9`. Pour en ajouter un, écrire son `GlyphSpec` dans `GlyphLibrary+Vowels.swift` ou un fichier voisin: une suite de traits, chacun dans le sens où va le crayon, en coordonnées normalisées avec y vers le bas. Les lignes de l'écolier sont dans `GlyphLibrary.Rule`.

Ne pas extraire les contours d'une police: un contour décrit le pourtour d'une forme pleine, pas le geste du crayon, il ne porte aucun ordre d'écriture, et les formes typographiques ne sont pas les formes scolaires (SF Pro dessine un `a` à deux étages).

Relire le résultat avec l'écran de débogage, qui numérote les départs et fléche les directions:

```
make build
xcrun simctl launch booted dev.rbstp.missionninja -screen glyphs
```

L'ordre d'écriture du 4, du 5 et du 8 varie d'une école à l'autre. Vérifier auprès de l'enseignante avant d'en encoder de nouveaux.

---

## Contraintes de conception

Elles viennent de l'usage, pas d'un goût abstrait. Les enfreindre casse l'app pour lui.

- **Il ne lit pas encore.** Toute consigne est parlée. Un texte à l'écran sert au parent qui accompagne, jamais à lui.
- **Ne jamais mettre la bonne réponse en évidence avant qu'il ait répondu.** Un contour sur la lettre attendue se lit avant le texte, même sans savoir lire, et vide l'exercice de son sens.
- **La voix parle lentement** (`Speaker.rate` à 0,36): à 6 ans, la cadence par défaut passe trop vite.
- **Consignes courtes.** On dit la chose deux fois, sans consigne autour: une consigne parlée revient dix fois par séance. Une lettre se nomme « la lettre a », en une seule phrase, parce qu'un nom d'une syllabe passe trop vite et qu'une pause entre « la lettre » et « a » colle le « a » à la phrase suivante. Un chiffre se dit par son mot, deux fois. Sur le mur des voyelles, une lettre se présente par un mot qui commence par elle (« La lettre i grec, comme dans », puis le mot seul; quatre mots par voyelle dans `Pronunciation`, accent ou pas): « y fait i » ne voulait rien dire pour lui. Le mot est un énoncé à part, sinon la voix fait la liaison « dans‿étoile » et il entend « zétoile ». Pas de mot que la voix écorche (igloo devenait « iglou »).
- **Aucun échec.** Une mauvaise réponse montre la bonne, la voix la redit, et l'épreuve revient plus tard. Un tracé ne rate pas: le curseur s'arrête, l'aide arrive après deux secondes et demie, la tolérance s'élargit après deux « Effacer ».
- **Le tracé valide une suite de points de passage, pas une continuité.** Un gribouillage assez patient finit par valider un glyphe. C'est un compromis assumé: à 6 ans, ne jamais bloquer vaut plus que rendre la triche impossible. La proportion de mouvement hors piste est mesurée et l'écran parent montre « propres sur total », ce qui informe sans punir.
- **Bleu et noir, en briques.** Ce sont ses couleurs, et il adore les blocs de construction. Tout ce qui se touche est une `Brick` (bleue si c'est l'action principale, noire sinon) qui s'enfonce à l'appui, ou un gros tenon (`StudButtonStyle`) quand le bouton est rond; les écrans reposent sur une `Baseplate`. La miniature du dragon dans le dojo est immobile (`animated: false`): un dragon qui vit redessine à chaque trame. L'or est réservé aux étoiles et au tenon de départ du tracé, le vert à une bonne réponse, le rouge seulement à une erreur, et discrètement. Le jaune n'apparaît que dans la fente des yeux du minifig.
- **Le ninja est un minifig**, cagoule noire qui couvre toute la tête, bandeau bleu, habit noir et katana. Pas de pantalon d'une autre couleur.
- **Le dragon de l'alphabet** est un `DragonBlueprint`: une mosaïque en texte, construite à partir de la gueule pour qu'on reconnaisse la bête dès les premières lettres. Chaque lettre trouvée pose des briques, il se reconstruit à chaque partie, et fini, le ninja l'attaque tout seul (voir les célébrations); un toucher le fait rugir de nouveau. Pour le redessiner, modifier les lignes de `standard` et relancer les tests, qui vérifient qu'il reste assez de briques et que l'œil arrive tôt.
- **Chaque fin d'entraînement se célèbre par une petite scène animée** (`Celebration`): le ninja qui combat le dragon, qui abat une pile de briques au shuriken, ou qui grimpe une tour de briques. Tirée au hasard à l'affichage; l'alphabet finit toujours sur son dragon. Les sons ne jouent qu'au premier tour, ensuite la scène boucle en silence. Se relit avec `-screen scenes`.
- **Le minifig bouge d'un bloc.** Pas d'animation propre à une partie du corps: une `.animation` sur la tête la faisait partir avant le corps. Torse, hanches et jambes sont une seule silhouette, le katana est tenu dans la main droite, devant.
- **Compter des briques, jamais en rangées régulières.** Cinq par ligne laissait lire six comme « cinq et un » sans compter. La disposition (`CountingLayout`, testé) tire des cases au hasard avec l'identifiant de l'épreuve comme graine. VoiceOver n'annonce jamais le compte: c'est la réponse.
- **Les mélanges changent à chaque ouverture d'un écran**, avec `SeededRandom.fresh()`.
- **Français canadien, bon langage.** Pas d'anglicisme, et la terminologie de l'école: un chiffre va de 0 à 9, un nombre s'écrit avec des chiffres. La consigne à l'écran dit « nombre » dès que la valeur dépasse 9.

---

## Style de code

- Commentaires rares, et seulement quand le pourquoi n'est pas déductible du code. Un bon commentaire explique une décision ou un piège évité, jamais ce que la ligne dit déjà.
- Aucun tiret cadratin, ni dans le code, ni dans les commentaires, ni dans l'interface.
- Pas d'abstraction spéculative, et on supprime ce qui n'est plus utilisé.
- **`Model`, `Content`, `Engine` et `Store` n'importent jamais SwiftUI.** C'est ce qui rend tout le jeu de règles testable sans simulateur, et c'est la contrainte à préserver en priorité lors d'un ajout.
- Swift 6 en `SWIFT_STRICT_CONCURRENCY: complete`. Deux pièges déjà rencontrés: le `deinit` d'une classe `@MainActor` est `nonisolated` et ne peut pas toucher ses propres propriétés (d'où les petits porteurs de jetons de notification), et `UserDefaults` n'est pas annoté `Sendable` dans le SDK.
- Tests en Swift Testing. Un appel `mutating` ne passe pas dans `#expect`: extraire le résultat dans une variable d'abord.

---

## Commandes

```
make test                              # la suite complète, sans simulateur pour la logique
make run                               # iPhone
make run SIM='iPad Pro 13-inch (M5)'   # iPad
make shot                              # capture du simulateur démarré
make icon                              # régénère l'icône (la tête du minifig, dessinée avec Paint et BrickTone)
```

Pour voir un écran directement, sans naviguer, en Debug:

```
xcrun simctl launch booted dev.rbstp.missionninja -screen dojo
```

Écrans: `dojo`, `letters`, `numbers`, `vowels`, `alphabet`, `trace`, `log`, `glyphs`, `scenes` (les trois célébrations de fin).

L'écran des parents s'ouvre par un appui long de trois secondes sur le badge de ceinture.

**La voix se vérifie sur un appareil réel.** Le simulateur n'a pratiquement aucune voix installée, donc un test de prononciation y est sans valeur.

Après toute modification d'un workflow, `devolutions-actionlint .github/workflows/*.yml` doit passer.

---

## Ce qui reste à faire

- La reconnaissance du prénom des amis de la classe, demandée par le plan de leçons du 7 septembre. Il faut la liste des prénoms, et la synthèse vocale les écorche: prévoir des enregistrements.
- Les majuscules autres que `A E I O U` dans `GlyphLibrary`, quand une semaine les demandera.
