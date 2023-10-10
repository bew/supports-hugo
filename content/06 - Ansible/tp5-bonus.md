---
title: "TP5 Bonus - Automatisation du déploiement avec Gitlab CI" 
draft: false
weight: 51
---

 ## Versionner le projet et utiliser la CI Gitlab avec Ansible pour automatiser le déploiement

- Créez un compte sur la forge logicielle `gitlab.com` et créez un projet (dépôt) public.
- Affichez et copiez `cat ~/.ssh/id_ed25519.pub`.
- Dans `(User) Settings > SSH Keys`, collez votre clé publique copiée dans la quesiton précédente.
- Suivez les instructions pour pousser le code du projet Ansible sur ce dépôt.
- Cliquez sur `Web IDE`, un bouton à droite dans l'interface de gitlab. Cet éditeur permet de développer directement dans le navigateur et commiter vos modification directement dans des branches sur le serveur.

- Ajoutez à la racine du projet un fichier `.gitlab-ci.yml` avec à l'intérieur:

```yaml
image:
  # This linux container (docker) we will be used for our pipeline : ubuntu bionic with ansible preinstalled in it
  name: williamyeh/ansible:ubuntu18.04

variables:
    ANSIBLE_CONFIG: $CI_PROJECT_DIR/ansible.cfg

deploy:
  # The 3 lines after this are used activate the pipeline only when the master branch changes
  only:
    refs:
      - master
  script:
    - ansible --version
```

En poussant du nouveau code dans master ou en mergant dans master le playbook est automatiquement lancé dans un pipeline: c'est le principe de la CI/CD Gitlab. `only: refs: master` sert justement à indiquer de limiter l'exécution des pipelines à la branche master.

- Cliquez sur `commit` dans le web IDE et cochez `merge to master branch`. Une fois validé votre code déclenche donc directement une exécution du pipeline.

- Vous pouvez retrouver tout l'historique de l'exécution des pipelines dans la Section `CI / CD > Jobs` rendez vous dans cette section pour observer le résultat de la dernière exécution.

!!! Notre pipeline nous permet uniquement de vérifier la bonne disponibilité d'ansible.

!!! Il est basé une image docker contenant Ansible pour ensuite executer notre projet d'IaC.

Nous allons maintenant configurer le pipeline pour qu'il puisse se connecter à nos serveurs de cloud. Pour cela nous avons principalement besoin de charger l'identité/clé SSH dans le contexte du pipeline et la déverrouiller.

- Affichez le contenu de votre clé privée SSH
- Visitez dans le projet dans la section `Settings> CI/CD > variables` et ajoutez une variable `ID_SSH_PRIVKEY` en mode `protected` (sans l'option `masked`).

- Pour charger l'identité dans le contexte du pipeline ajoutez la section `before_script` suivante entre `variables` et `deploy`:

```bash
before_script: # some steps to execute before the main pipeline stage

  # Those command lines are use to activate the SSH identity in the pipeline container
  # so the SSH command from the deploy stage will be able to authenticate.
  - eval `ssh-agent -s` > /dev/null # activate the agent software which manage the ssh identity
  - echo "$ID_SSH_PRIVKEY" > /tmp/privkey # getting the identity key from gitlab to put it in a file
  - chmod 600 /tmp/privkey # restrict access to this file because ssh require it
  - ssh-add /tmp/privkey; rm /tmp/privkey # unlock identity for connection and remove the key file
  - mkdir -p /root/.ssh # create an ssh configuration folder
  - echo -e "Host *\n\tStrictHostKeyChecking no\n\n" > /root/.ssh/config # configure ssh not to bother of server identity (slightly unsecure mode for the workshop)

```

- Remplacez `ansible --version` par un ping de toutes les machines.
- Relancez le pipeline en commitant(et en poussant) vos modifications dans `master`.

- Allez observer le job en cours d'exécution.

- Enfin lançons notre playbook principal en remplaçant la commande ansible précédente dans le pipeline et commitant

- Ajoutez une plannification dans la section `CI / CD`.

## Bonus: Créez une planification pour le rolling upgrade de notre application

<!-- - Modifiez `only: refs:` pour ajouter la branche `rolling_upgrade`. -->
<!-- - Modifier la commande ansible pour lancer le playbook d'upgrade. -->
- Dans `CI / CD > Schedules` ajoutez un job planifié toute les 5 min (en production toutes les nuits serait plus adapté).
- Observez le résultat.

## Bonus: un déploiement plus sécurisé avec un _webhook_

### Logs dans Ansible et création du script d'exécution

Pour suivre ce qu'il se passe, ajoutez la ligne suivante dans votre fichier `ansible.cfg` pour spécifier le chemin du fichier de logs (`ansible_log.txt` en l'occurrence) :

```bash
log_path=./ansible_log.txt
```

- à la racine du dépôt Ansible, créez un script Bash nommé `ansible-run.sh`, copiez et collez le contenu suivant dans le fichier `ansible-run.sh` et en remplaçant :

```bash
#!/bin/bash
ansible-playbook deploy_docker_app.yml --diff -v
```

- rendez le script exécutable avec `chmod +x ansible-run.sh`

- dans un terminal, faites `bash ansible-run.sh` pour tester votre script de déploiement.

### Installation et configuration du Webhook

Sur votre serveur de déploiement (celui avec le projet Ansible), installez le paquet `webhook` en utilisant la commande suivante :

```bash
sudo apt install webhook
```
Ensuite, créons un fichier de configuration pour le webhook.

- Avec `nano` ou `vi` par exemple, faites `sudo nano /etc/webhook.conf`, modifiez-le avec le contenu suivant **en adaptant la partie `/home/formateur/projet-ansible` avec le chemin de votre projet**, puis enregistrez et quittez le fichier (pour `nano`, en appuyant sur `Ctrl + X`, suivi de `Y`, puis appuyez sur `Entrée`) :

```json
[
  {
    "id": "redeploy-webhook",
    "command-working-directory": "/home/formateur/projet-ansible",
    "execute-command": "/home/formateur/projet-ansible/ansible-run.sh",
    "include-command-output-in-response": true,
  }
]
```

### Lancement et test du webhook

Lancez le webhook en utilisant la commande suivante dans un nouveau terminal (si le terminal se ferme, le programme s'arrêtera) :

```bash
/usr/bin/webhook -nopanic -hooks /etc/webhook.conf -port 9999 -verbose
```

Pour tester le webhook, ouvrez simplement un navigateur web et accédez à l'URL suivante en remplaçant `localhost` par l'adresse IP de votre serveur si nécessaire :

```
http://localhost:9999/hooks/redeploy-webhook
```

Le webhook exécutera le script `ansible-run.sh`, qui lancera votre playbook Ansible et affichera son retour (ou une erreur).

### Intégration à Gitlab CI

Dans un fichier `.gitlab-ci.yml` vous n'avez plus qu'à appeler `curl http://votredomaine:9999/hooks/redeploy-webhook` pour déclencher l'exécution de votre playbook Ansible en réponse à une requête depuis les serveurs de Gitlab.

Cette configuration est bien plus sécurisée, même si en production nous protégerions le webhook avec un mot de passe (token) pour éviter que le webhook soit déclenché abusivement si quelqu'un en découvrait l'URL.
