# Règles de review

Lu **uniquement** par l'agent `reviewer` (skill `review`). Ne duplique pas `CLAUDE.md` (déjà fourni au reviewer) : ce fichier dit quoi juger bloquant, quoi regarder en priorité, quoi ignorer.

## Bloquant (verdict CHANGEMENTS REQUIS)

- Test supprimé, désactivé, ou assertion affaiblie pour faire passer le build, sans explication dans la description de la PR (règle de `CLAUDE.md`).
- Index, drag data, JSON ou fichier `user://` utilisé sans validation (bornes d'index, type, existence).
- `.uid`, `.import` ou `.godot/` modifiés à la main ; `uid://` invalide dans un `.tscn` / `.tres`.
- Logique de gameplay ajoutée dans un autoload.
- Resource partagée mutée pour de l'état propre à une instance (utiliser `ItemInstance`).
- Composant qui s'appuie sur `get_node("chemin/fragile")` ou sur le type concret de son parent au lieu d'un `@export` ou d'un signal.
- `await` sur un node qui peut être libéré entre-temps, ou signal connecté sans déconnexion alors que l'émetteur vit plus longtemps.
- Commit ou description de PR qui mentionne Claude ou une IA (`Co-Authored-By`, « Generated with … »).
- `addons/` modifié autrement que par l'installation ou la mise à jour documentée d'un plugin.

## À vérifier en priorité

- Nouveau comportement non trivial sans test, ni explication de pourquoi il n'est pas testable.
- Un bug corrigé sans test de non-régression.
- Dans les tests : un seul comportement par test, pas de `if` ni de boucle, `auto_free` sur les nodes créés, `monitor_signals` appelé **avant** l'action qui émet le signal, `await` avant d'asserter un comportement dépendant du temps.
- Test qui reproduit l'implémentation au lieu de vérifier un comportement observable.
- Sur les lignes ajoutées ou modifiées : typage statique complet (paramètres, retours, variables), variables d'une lettre, `print` oublié, fonction publique ou `class_name` sans commentaire `##`, nombres ou chaînes magiques.
- Cohérence avec « call down, signal up » : un enfant qui appelle son parent au lieu d'émettre un signal.
- Historique : messages de commit en Conventional Commits (description en anglais, minuscule), un commit = une intention, PR en français avec le gabarit Problème / Solution / Implémentation / Recette.

## À ignorer

- Les défauts préexistants listés dans « Points connus à ne pas reproduire » de `CLAUDE.md`, tant que le diff ne touche pas la zone concernée. S'il la touche, les signaler comme « à améliorer », jamais bloquants.
- Le contenu de `addons/gdUnit4/` : code tiers, non relu.
- Rendu, shaders, SubViewports et « feeling » : hors périmètre des tests.
- Style et formatage purs.
