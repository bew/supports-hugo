---
title: "TP6 Bonus - Serveur de contrôle AWX" 
draft: false
weight: 26
---
## Installer AWX ou Rundeck

- AWX : sur Kubernetes avec k3s

- Rundeck : avec Docker ou autre
`docker run --rm -it -p 4440:4440 rundeckpro/enterprise:4.17.0`

## Explorer AWX

- Identifiez vous sur awx avec le login `admin` et le mot de passe précédemment configuré.

- Dans la section modèle de projet, importez votre projet. Un job d'import se lance. Si vous avez mis le fichier `requirements.yml` dans  `roles` les roles devraient être automatiquement installés.

- Dans la section crédentials, créez un crédential de type machine. Dans la section clé privée copiez le contenu du fichier `~/.ssh/id_ssh_tp` que nous avons configuré comme clé ssh de nos machines. Ajoutez également la passphrase que vous avez configuré au moment de la création de cette clé.

- Créez une ressource inventaire. Créez simplement l'inventaire avec un nom au départ. Une fois créé vous pouvez aller dans la section `source` et choisir de l'importer depuis le `projet`, sélectionnez `inventory.cfg` que nous avons configuré précédemment. 
<!-- Bien que nous utilisions AWX les ip n'ont pas changé car AWX est en local et peut donc se connecter au reste de notre infrastructure LXD. -->

- Pour tester tout cela vous pouvez lancez une tâche ad-hoc `ping` depuis la section inventaire en sélectionnant une machine et en cliquant sur le bouton `executer`.

- Allez dans la section modèle de job et créez un job en sélectionnant le playbook `site.yml`.

- Exécutez ensuite le job en cliquant sur la fusée. Vous vous retrouvez sur la page de job de AWX. La sortie ressemble à celle de la commande mais vous pouvez en plus explorer les taches exécutées en cliquant dessus.

- Modifiez votre job, dans la section `Plannifier` configurer l'exécution du playbook site.yml toutes les 15 minutes.

- Allez dans la section plannification. Puis visitez l'historique des Jobs.


