---
name: rebase
description: Effectuer un git rebase interactif de manière non-interactive
---

# Git rebase interactif

Utilise le script `git-rebase-non-interactive.js` situé dans ce dossier de skill.

## Utilisation

```bash
~/.claude/skills/rebase/git-rebase-non-interactive.js HEAD~N << 'EOF'
pick abc123 Message
drop def456 Message à supprimer
fixup ghi789 À fusionner avec le précédent
pick jkl012 Autre message
exec git commit --amend -m "Nouveau message pour renommer"
EOF
```

## Actions disponibles

- `pick` : garder le commit tel quel
- `drop` : supprimer le commit
- `fixup` : fusionner avec le commit précédent (garde le message du précédent)
- `squash` : fusionner avec le commit précédent (combine les messages)
- `exec git commit --amend -m "..."` : renommer le commit juste au-dessus

## Workflow

1. Faire un `git log --oneline` pour voir les commits
2. Construire le todo avec les actions souhaitées
3. Lancer la commande avec le heredoc
