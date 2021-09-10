---
title: TP2 - Déployer notre application dans plusieurs contextes avec `kustomize`
draft: false
---


## Reprendre le déploiement du TP3 kubernetes pour l'adapté un déploiement multienvironnement

Pour continuer, nous allons reprendre la correction du TP1 avec en plus le déploiement kubernetes du TP3 kubernetes.

- Pour cela, dans le projet `tp_jenkins_application`, commitez vos modifications puis lancez `git checkout jenkins_tp2_base`

- Ouvrez ensuite le projet `tp2_infra_et_app` dans VSCode.

## Déployer à partir d'un dépôt privé

Jusqu'ici nous avons poussé nos images docker sur le Docker Hub qui est gratuit et déjà configuré pour que docker récupère les image dessus par défaut. Généralement il est impossible d'utiliser ce repository public pour des logiciels d'une entreprise car cela révèle le fonctionnement et les failles des logiciels que vous y stocker.

De plus le hub Docker est souvent lent car surchargé.

Plus généralement nous aimerions avoir un répository privé et interne à notre cluster:
- pour la vitesse
- pour la sécurité

Pour avoir un répository privé il existe de nombreuses solutions. On peut mentionner:
- un compte commercial docker hub
- un compte commercial sur quay.io
- Utiliser gitlab
- Installer un repository avec `Harbor` (puissant mais lourd à installer et configurer)
- Installer un répository docker simple en https (idéalement avec un login par mot de passe ou autre)

Nous allons opter pour la dernière solution pour sa simplicité et sa versatilité.

- Chercher sur artifacthub le chart `docker-registry` de `twun`.

- Créez un fichier `docker-registry/values.yaml` pour configurer notre installation contenant:

```yaml
ingress:
  enabled: true
  path: /
  hosts:
    - registry.<votrenom>.vagrantk3s.dopl.uk
  tls:
    - hosts:
      - registry.<votrenom>.vagrantk3s.dopl.uk
      secretName: docker-registry-tls-cert
  annotations:
    kubernetes.io/ingress.class: "nginx"
    kubernetes.io/tls-acme: "true"
    cert-manager.io/cluster-issuer: acme-dns-issuer-prod
    nginx.ingress.kubernetes.io/proxy-body-size: "0" # important pour mettre une max body size illimitée pour nginx et pouvoir pousser des grosses images de plusieurs Gio
persistence:
  enabled: true
  size: 10Gi
service:
  port: 5000
  type: ClusterIP
replicaCount: 1
```
<!-- ```
secrets:
  htpasswd: <votre htpassword voir suite>
``` -->

- Complétez le nom de domaine avec votre nom.

<!-- - Nous allons générer un secret pour le mot de passe htpassword avec `docker run --rm --entrypoint htpasswd registry:2.6.2 -Bbn <votreuser> <votrepassword>`. Collez ce hash dans le values.yaml précédent

 (il faudrait idéalement créer le secret à la main ou ajouter un gestionnaire de secret ici mais il n'y a pas de solution simple). -->


- Modifiez le `helmfile` de `tp_jenkins_infra` pour ajouter la release du `docker-registry` (dans le namespace `docker-registry`) en vous inspirant des autres et de la doc artifacthub.

- Appliquez le helmfile comme dans le tp0.

- Ajoutez le nom de domaine `registry.<votrenom>.vagrantk3s.dopl.uk` aux deux fichiers `/etc/hosts` de votre machine hote et de votre machine vagrant k3s (pour que le cluster connaisse aussi le nom). 

- Connectez vous avec `docker login registry.<votrenom>.vagrantk3s.dopl.uk -u <votreuser> -p <votrepassword>`

- Poussez une image par exemple `python:3.9` en la tagguant avec l'adresse du dépot:
    - `docker tag python:3.9 registry.<votrenom>.vagrantk3s.dopl.uk/python:3.9`

- Maintenant buildez l'image monstericon en lançant `docker build -t monstericon .` depuis le dossier `tp2_monsterstack_deploy_multienv`.

- Tagguez l'image avec `docker tag monstericon registry.<votrenom>.vagrantk3s.dopl.uk/monstericon`

- Puis `docker push registry.<votrenom>.vagrantk3s.dopl.uk/monstericon`

## Faire varier une installation kubernetes

Nous avons besoin de pouvoir déployer notre application **monsterstack** dans Kubernetes de façon légèrement différente selon les environnements `prod` et `dev`.

### Créer les fichiers de base `kustomize`

Kustomize fonctionne en partant de fichiers ressource kubernetes de base et en écrasant certaines parties du fichiers avec de nouvelles valeurs appelées overlays.

- Ouvrez les fichiers dans `k8s/base`

- Les fichiers de base ne contienne que les information de base non spécifiques à un environnement.

- Quelques sont les paramètres qui doivent varier en fonction de l'environnement ?
  - la version de l'image utilisée !
  - les replicats
  - le port de monstericon (5000 en dev et 9090 en prod)
  - resource quota éventuellement
  - les noms des différentes resources

L'idée générale est de supprimer tous ces paramètres variables des fichiers de base pour les reporter dans un autre ensemble de fichier pour chaque environnement.

### Environnement de production

La prod contiendra une seule version de l'application avec des paramètres de production.

- Commitez vos modifications puis lancez `git checkout jenkins_tp2_correction`.

- Remplacez automatiquement toutes les instances de `<votrenom>` par votre nom avec la fonction de search and replace de VSCode.

- Observez les fichiers dans le dossier `overlays/prod`. Il contiennent les paramètres spécifiques de la production à ajouter par dessus les fichiers de base

- Depuis le dossier `k8s` lancez la commande `kubectl kustomize overlays/prod > result.yaml` puis observez ce fichier `resultprod.yaml`.

- Créez un namespace de prod pour le déploiement avec `kubectl create namespace prod`

- Supprimez le fichier précédent et appliquez la configuration de prod avec `kubectl apply -k overlays/prod -n prod`

### Autres déploiement de version de développement de notre application

Nous voulons déployer plusieurs version de la même application automatiquement:

- Donc il faut éviter les conflits de nom pour nos objets. Une solution simple est d'utiliser de multiples namespaces
- Il faut également que la version de l'image et le nom de domaine du ingress puisse changer dynamiquement au moment du déploiement.

Sinon le principe est un peu le même que pour la production seules les valeurs sont différentes : moins de replicat, le port de dev.

- Depuis le dossier `k8s` vous pouvez lancer la commande `kubectl kustomize overlays/dev > result.yaml` pour observez le résultat dans le fichier `result.yaml`

- Puis déployer dans le namespace default: `kubectl apply -k overlays/dev`

- vérifiez le fonctionnement en visitant le domaine de l'ingress.

- Supprimez cette installation avec `kubectl delete -k overlays/dev`

### Changer le nom de domaine avec une variable

Pour changer le nom de domaine dynamiquement, nous allons utiliser une configMap contenant une variable d'environnement et une variable kustomize.

- Ajoutez au fichier `overlays/dev/kustomization.yaml` la section suivante:

```yaml
vars:
- name: INGRESS_SUBDOMAIN
  objref:
    kind: ConfigMap
    name: environment-variables
    apiVersion: v1
  fieldref:
    fieldpath: data.INGRESS_SUBDOMAIN

configMapGenerator:
- name: environment-variables
  envs: [release.env]
  behavior: create
```

Cette section très verbeuse indique à kubectl/kustomize de:

- créer une `configMap` pour configurer notre application à partir d'un fichier `release.env`
- utiliser la valeur `INGRESS_SUBDOMAIN` provenant de cette configmap pour faire une substitution dans les fichiers k8s.

Maintenant:

- Ajoutez un fichier `overlay/dev/release.env` contenant : `INGRESS_SUBDOMAIN=monstericon-beta`. On pourrait utiliser ce fichier pour ajouter pleins de variables d'environnement pour configurer notre application.

- Remplacez dans `overlay/dev/monster-ingress.yaml` le sous domaine `monstericon` par `$(INGRESS_SUBDOMAIN)`

### Changer l'image à déployer dans la kustomization

On voudrait également pouvoir changer rapidement l'image à déployer depuis la kustomization pour pouvoir déployer des instances de développement dans de nombreuses versions.

- Pour cela ajoutez à `overlay/dev/kustomization.yaml` la section:

```yaml
images:
- name: monstericon
  newName: registry.<votrenom>.vagrantk3s.dopl.uk/monstericon
  newTag: beta
```

- Modifiez également dans `overlay/dev/monstericon-deploy.yaml` l'image en `monstericon`

### Déployer dans un namespace à part

- Créez un namespace `beta` avec `kubectl create namespace beta`.

- Déployez `kubectl apply -k overlays/dev -n beta`

- Testez le fonctionnement en visitant le domaine de l'ingress dans le namespace `beta`


## Désinstaller et nettoyer

- Désinstallez vos `prod` et `dev` en remplacant simplement `apply` par `delete` dans les commandes `kubectl apply` précédentes.

- Supprimez ensuite le namespace `beta` (une fois qu'il ne contient plus rien sinon la suppression se bloquera)

## Correction

Dans le dépot de corrections: 

- Commitez vos modifications puis lancez `git checkout jenkins_tp2_correction`
