---
title: "TP5 Bonus - Automatisation du déploiement avec Gitlab CI" 
draft: false
weight: 51
---

 ## Versionner le projet et utiliser la CI gitlab avec Ansible pour automatiser le déploiement

- Créez un compte sur la forge logicielle `gitlab.com` et créez un projet (dépôt) public `tp4_infra`.
- Affichez et copiez `cat ~/.ssh/id_ed25519.pub`.
- Dans `(User) Settings > SSH Keys`, collez votre clé publique copiée dans la quesiton précédente.
- Suivez les instructions pour pousser le code du tp4 sur ce dépôt.
- Cliquez sur `web IDE`, un bouton à droite dans l'interface de gitlab. Cet éditeur permet de développer directement dans le navigateur et commiter vos modification directement dans des branches sur le serveur.

- Ajoutez à la racine du projet un fichier `.gitlab-ci.yml` avec à l'intérieur:

```yaml
image:
  # This linux container (docker) we will be used for our pipeline : ubuntu bionic with ansible preinstalled in it
  name: williamyeh/ansible:ubuntu18.04

variables:
    ANSIBLE_CONFIG: $CI_PROJECT_DIR/ansible.cfg

deploy:
  # The 3 lines after this are used activate the pipeline only when the master branche changes
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

- Affichez le contenu de votre clé privé `.ssh/id_ed25519`
- Visitez dans le projet dans la section `Settings> CI/CD > variables` et ajoutez une variable `ID_SSH_PRIVKEY` en mode `protected` (sans l'option `masked`).

- Pour charger l'identité dans le contexte du pipeline ajoutez la section `before_script` suivante entre `variables` et `deploy`:

```yaml
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
- Relancez le pipeline en commitant(/poussant) vos modifications dans master.

- Allez observer le job en cours d'exécution.

- Enfin lançons notre playbook principal en remplaçant la commande ansible précédente dans le pipeline et commitant. 

- Ajoutez une plannification dans la section `CI / CD`.

## Bonus: Créez une branche spécifique et une plannification pour le rolling upgrade de notre application

- Modifiez `only: refs:` pour ajouter la branche `rolling_upgrade`.
- Modifier la commande ansible pour lancer le playbook d'upgrade.
- Dans `CI / CD > Schedules` ajoutez un job plannifié toute les 5 min (en production toute les nuits serait plus adapté).
- Observez le résultat.

