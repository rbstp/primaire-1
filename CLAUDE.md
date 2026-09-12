# CLAUDE.md

Ce dépôt est l'app iOS `Mission Ninja` (`dev.rbstp.missionninja`), construite pour mon garçon de 6 ans, en 1re année à l'école Notre-Dame-de-La-Paix. Son enseignante, Mme Catherine, distribue un plan de leçons en PDF chaque semaine. L'app en prend la partie répétitive et la rend jouable. Elle est distribuée par TestFlight à la famille seulement.

---

## Deux entrées: la semaine et le cursus

L'écran d'ouverture demande d'abord quoi entraîner:

- **La semaine en cours**, le plan de leçons de Mme Catherine (`Resources/Weeks/<lundi>.json`). C'est le gros bouton bleu, parce que c'est ce qu'il ouvre tous les soirs.
- **Français** et **Mathématiques**, tout le cursus de l'année (`Resources/Curriculum/francais.json`, `mathematiques.json`), bloc par bloc. Ça sert quand la feuille de la semaine n'est pas encore arrivée, ou quand on veut revenir sur un bloc passé.

Un bloc de cursus se joue dans le même dojo qu'une semaine: `Curriculum.lesson(_:)` en fabrique une `Week` sans jours ni devoirs. Les tuiles du dojo n'apparaissent que si le bloc a de la matière pour elles, donc un bloc de français n'offre pas de chiffres et un bloc de maths n'offre ni lettres ni mots. La ceinture reste celle de la semaine civile: peu importe ce qu'il entraîne, les étoiles tombent dans la semaine en cours.

### Le cursus de français

36 blocs, un par semaine de l'année, recopiés du cahier de l'enseignante. Chacun porte:

- `sounds`: les graphèmes enseignés, lettres seules et digrammes ensemble (`"ou"`, `"an"`, `"ill"`). Les lettres seules alimentent le jeu d'écoute, **cumulées depuis le début de l'année**: en janvier la classe les a toutes vues, et un leurre qu'il n'a jamais rencontré n'est pas un leurre. Un digramme ne nomme aucune lettre, donc il reste dans le titre du bloc et hors du jeu.
- `sight`: les mots éclair, ceux que la classe mémorise d'un coup d'oeil (l'éclair jaune du cahier).
- `decode`: les mots à décoder (la graine verte du cahier).

Les deux listes nourrissent le même jeu, « Trouve le mot »: la voix dit le mot deux fois, les mots du bloc sont sur la table, il touche le bon. C'est le jeu « Oreille ouvre-toi » que l'enseignante propose aux parents, et il ne demande rien qu'il ne sache faire: il ne lit rien à voix haute.

**Un mot dont un homophone est dans la même liste n'y entre pas.** À l'oreille la question n'aurait pas de réponse. C'est pourquoi la semaine 12 garde `non` sans `nom`, la semaine 17 `lait` sans `laid`, la semaine 19 `noir` sans `noire`, et la conjugaison d'*aimer* s'arrête à `vous aimez`, parce que `ils aiment` se dit comme `il aime`. Un test vérifie qu'aucun bloc ne répète un mot ni sa forme parlée; l'homophonie, elle, se juge à l'oreille en ajoutant la donnée.

Il faut **au moins trois mots** pour que la tuile apparaisse (`WordPlan.playable`): à deux, une bonne réponse sur deux vient du hasard. Les semaines 2 et 25 n'en ont pas assez et n'offrent donc que les lettres.

### Le cursus de mathématiques

Les tranches de la grille des nombres, comme les feuilles « Je lis des nombres » du cartable: 0 à 9, puis chaque dizaine jusqu'à 90 à 99, puis la révision. Chaque bloc va de 0 jusqu'au haut de sa tranche avec `focus` sur la tranche, donc neuf épreuves sur dix portent sur ce qu'il travaille et la dixième révise. Le dénombrement en briques ne sert que jusqu'à 20, donc `counting` est faux au-delà.

L'aide-mémoire *1-2-3 avec Nougat* (fractions, géométrie, mesure, heure, statistiques) n'est pas dans l'app: aucune de ces notions n'a d'épreuve, et en inventer une sans l'avoir vue en classe ne rendrait pas service.

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
   - `letters.vowels` et `numbers`: ce que la semaine demande de reconnaître, rien de plus. Le plan de leçons est la limite; les leurres d'un exercice sont tirés dans la semaine, donc y ajouter des caractères non enseignés fausserait l'exercice. Le `e` traîne ses accents avec lui (`LetterPlan.accents`), et chaque voyelle a besoin d'au moins un objet dans `PictureLibrary`, sinon elle ne sert que de leurre dans le jeu des voyelles.
   - `numbers.focus`: facultatif, la tranche sur laquelle les épreuves insistent (neuf fois sur dix) quand la semaine va plus loin que ce qu'il travaille vraiment. Une épreuve ne mélange jamais la tranche et le reste: un 4 parmi 12, 14 et 17 se devine sans lire.
   - `tracing`: les caractères à écrire au doigt. Chacun doit exister dans `GlyphLibrary`, sinon il est silencieusement ignoré.
   - `names`: les prénoms des amis de la classe, écrits comme sur les cartes de l'autobus (« Mme Sylvie » inclus). Liste vide: les deux tuiles de prénoms disparaissent. Un prénom avec une espace se fait entendre mais ne se construit pas.
   - `tasks`: les devoirs qui se font sur papier, un par ligne du plan, avec `place` pour le cahier et la page.
   - `words`: facultatif, les mots de la semaine, en `sight` et `decode` comme dans le cursus. Le plus souvent il suffit de recopier ceux du bloc de français correspondant.

3. `make test`, puis une PR. Le merge sur `master` déclenche `testflight` et le build arrive sur l'appareil en une quinzaine de minutes.

Rien d'autre à toucher: l'app charge tous les fichiers du dossier, les trie, et ouvre par défaut la plus récente déjà commencée.

### Si la semaine demande un caractère sans tracé

`GlyphLibrary` couvre `a e é è i o u` en minuscule, `A E I O U` en majuscule, plus `0` à `9`. Pour en ajouter un, écrire son `GlyphSpec` dans `GlyphLibrary+Vowels.swift` ou un fichier voisin: une suite de traits, chacun dans le sens où va le crayon, en coordonnées normalisées avec y vers le bas. Les lignes de l'écolier sont dans `GlyphLibrary.Rule`.

Ne pas extraire les contours d'une police: un contour décrit le pourtour d'une forme pleine, pas le geste du crayon, il ne porte aucun ordre d'écriture, et les formes typographiques ne sont pas les formes scolaires (SF Pro dessine un `a` à deux étages).

Relire le résultat avec l'écran de débogage, qui numérote les départs et fléche les directions:

```
make build
xcrun simctl launch booted dev.rbstp.missionninja -screen glyphs
```

L'ordre des chiffres vient de la bande « Tracer des chiffres » de l'aide-mémoire *Nougat* (p. 5, qui reproduit le *Cahier A* p. 2), donc c'est bien celui de sa classe: le 4 part à gauche par un angle droit, le 5 se fait d'un seul trait depuis le haut à droite, le 8 part en haut et va vers la gauche. Pour une lettre, l'ordre varie encore d'une école à l'autre: vérifier auprès de l'enseignante avant d'en encoder de nouvelles.

---

## Contraintes de conception

Elles viennent de l'usage, pas d'un goût abstrait. Les enfreindre casse l'app pour lui.

- **Il ne lit pas encore.** Toute consigne est parlée. Un texte à l'écran sert au parent qui accompagne, jamais à lui.
- **Ne jamais mettre la bonne réponse en évidence avant qu'il ait répondu.** Un contour sur la lettre attendue se lit avant le texte, même sans savoir lire, et vide l'exercice de son sens.
- **La voix parle lentement** (`Speaker.rate` à 0,36): à 6 ans, la cadence par défaut passe trop vite.
- **Consignes courtes.** On dit la chose deux fois, sans consigne autour: une consigne parlée revient dix fois par séance. Une lettre se nomme « la lettre a », en une seule phrase, parce qu'un nom d'une syllabe passe trop vite et qu'une pause entre « la lettre » et « a » colle le « a » à la phrase suivante. Un chiffre se dit par son mot, deux fois, et l'objet du jeu des voyelles par son nom, deux fois.
- **Aucun échec.** Une mauvaise réponse montre la bonne, la voix la redit, et l'épreuve revient plus tard. Un tracé ne rate pas: une flèche montre le sens du départ, le curseur s'arrête, l'aide arrive après deux secondes et demie, la tolérance s'élargit après deux « Effacer ». Dans l'alphabet, deux erreurs de suite illuminent la rangée qui contient la lettre, jamais la lettre. Dans la construction d'un prénom, deux erreurs de suite allument la brique suivante et la voix nomme la lettre.
- **Le tracé valide une suite de points de passage, pas une continuité.** Un gribouillage assez patient finit par valider un glyphe. C'est un compromis assumé: à 6 ans, ne jamais bloquer vaut plus que rendre la triche impossible. La proportion de mouvement hors piste est mesurée et l'écran parent montre « propres sur total », ce qui informe sans punir.
- **Bleu et noir, en briques.** Ce sont ses couleurs, et il adore les blocs de construction. Tout ce qui se touche est une `Brick` (bleue si c'est l'action principale, noire sinon) qui s'enfonce à l'appui, ou un gros tenon (`StudButtonStyle`) quand le bouton est rond; les écrans reposent sur une `Baseplate`. La miniature du dragon dans le dojo est immobile (`animated: false`): un dragon qui vit redessine à chaque trame. L'or est réservé aux étoiles et au tenon de départ du tracé, le vert à une bonne réponse, le rouge seulement à une erreur, et discrètement. Le jaune n'apparaît que dans la fente des yeux du minifig.
- **Le ninja est un minifig**, cagoule noire qui couvre toute la tête, bandeau bleu, habit noir et katana. Pas de pantalon d'une autre couleur.
- **Le dragon de l'alphabet** est un `DragonBlueprint`: une mosaïque en texte, construite à partir de la gueule pour qu'on reconnaisse la bête dès les premières lettres. Chaque lettre trouvée pose des briques, il se reconstruit à chaque partie, et fini, le ninja l'attaque tout seul (voir les célébrations); un toucher le fait rugir de nouveau. Pour le redessiner, modifier les lignes de `standard` et relancer les tests, qui vérifient qu'il reste assez de briques et que l'œil arrive tôt.
- **Chaque fin d'entraînement se célèbre par une petite scène animée** (`Celebration`): le ninja qui combat le dragon, qui abat une pile de briques au shuriken, ou qui grimpe une tour de briques. Tirée au hasard à l'affichage; l'alphabet finit toujours sur son dragon. Les sons ne jouent qu'au premier tour, ensuite la scène boucle en silence. Se relit avec `-screen scenes`.
- **Le minifig bouge d'un bloc.** Pas d'animation propre à une partie du corps: une `.animation` sur la tête la faisait partir avant le corps. Torse, hanches et jambes sont une seule silhouette, le katana est tenu dans la main droite, devant. Seule exception: sur l'écran d'ouverture il fait tourner son katana dans la main (`swordAngle`, piloté par `withAnimation` depuis `SubjectPickerView`), un tour complet par le bas pour ne jamais balayer le visage.
- **Compter des briques par groupes de cinq.** Les cinq complets sont des piles avec un « 5 » sur la brique du dessus, comme la classe groupe; le reste tombe en vrac sur des cases tirées au hasard (`CountingLayout`, testé) avec l'identifiant de l'épreuve comme graine, parce qu'une rangée régulière laissait lire six comme « cinq et un » sans compter. Jusqu'à vingt briques. VoiceOver n'annonce jamais le compte: c'est la réponse.
- **Les mélanges changent à chaque ouverture d'un écran**, avec `SeededRandom.fresh()`.
- **Les voyelles se jouent en images.** On montre un objet en briques (`PictureLibrary`), la voix le nomme deux fois et il choisit la lettre par laquelle le mot commence. Le mot ne s'écrit jamais à l'écran: écrit, il donne la réponse. La lettre est lue sur le mot lui-même, donc « école » commence par `é` et « escargot » par `e`; l'accent grave est là comme leurre, aucun mot d'enfant ne commence par `è`. Un objet n'entre dans la liste que si un enfant de six ans le nomme sans aide et que la voix dit le mot proprement (igloo devenait « iglou »). Se relit avec `-screen pictures`.

- **La police partout, sauf dans le tracé.** Les lettres et les chiffres s'affichent avec la police (SF Pro arrondie, en gras), même si elle dessine un `a` à deux étages: c'est celui des livres et des affiches de la classe. Seul le sélecteur du tracé les dessine avec les traits de `GlyphLibrary` (`GlyphMark`), parce que la brique qu'il touche là montre le geste qu'il s'apprête à faire. Ce que la bibliothèque ne couvre pas garde la police là aussi.

- **Les mots se montrent, ne se lisent pas à voix haute.** La voix dit le mot deux fois, les mots du bloc sont sur la table, il touche le bon. Un mot par rangée, parce qu'un mot se lit de gauche à droite et ne se reconnaît pas d'un coup d'oeil comme une lettre.
- **Les prénoms se disent, ne s'écrivent pas.** Le prénom est dit deux fois et il choisit parmi cinq cartes (toute la classe si elle est plus petite): à moins, la première lettre suffit. Pour le construire, il entend le prénom et remet ses briques dans l'ordre, sans modèle écrit. « Mme » se lit « Madame »; les prénoms que la voix écorche ont une graphie phonétique dans `Pronunciation`, à vérifier sur l'appareil.
- **La ceinture est celle de la semaine.** Tout se classe par semaine civile, du lundi au dimanche (`ProgressStore.weekKey`), et la ceinture repart à blanc le lundi: les seuils (`Belt`) sont faits pour cinq soirs, noire à 160. Le total d'étoiles depuis le début reste pour le parent. Le temps compté est le temps au premier plan, filé à la semaine où il se termine.
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

Écrans: `subjects` (l'ouverture), `weeks`, `francais`, `maths`, `dojo`, `letters`, `numbers`, `words`, `names`, `build`, `vowels`, `alphabet`, `trace`, `log`, `summary`, `parent`, `glyphs`, `pictures` (les objets du jeu des voyelles), `scenes` (les trois célébrations de fin). Un écran lancé ainsi est la racine de la pile: il n'a pas de bouton de retour. `-unit <id>` ouvre l'écran sur un bloc du cursus au lieu de la semaine en cours:

```
xcrun simctl launch booted dev.rbstp.missionninja -screen dojo -unit fr-12
```

L'écran des parents s'ouvre par un appui long de trois secondes sur le badge de ceinture. Ses statistiques sont celles de la semaine en cours; le « Bilan des semaines », aussi accessible depuis l'écran de sélection des semaines, montre chaque semaine avec sa ceinture, ses étoiles et son temps.

**La voix se vérifie sur un appareil réel.** Le simulateur n'a pratiquement aucune voix installée, donc un test de prononciation y est sans valeur.

Après toute modification d'un workflow, `devolutions-actionlint .github/workflows/*.yml` doit passer.

---

## Ce qui reste à faire

- Vérifier sur l'appareil la prononciation des prénoms (Hayden, Madison, Nolan, Charlie). Si la voix les écorche malgré la graphie phonétique, prévoir des enregistrements.
- Les majuscules autres que `A E I O U` dans `GlyphLibrary`, et le `y` minuscule, que la semaine nomme sans le faire écrire. Faute de tracé, ces lettres s'affichent dans la police.
- Le sens du trait des accents (`é`, `è`) suit la lecture, de gauche à droite. À vérifier auprès de l'enseignante.
- Le point de départ du `9` est au bord droit de la boucle; l'aide-mémoire le met un peu plus haut, au coin. Même forme, même sens, même fin: à corriger seulement si le tenon doré le déroute.
