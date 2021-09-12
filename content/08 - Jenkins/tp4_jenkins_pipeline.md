---
title: TP4 - Créer le pipeline Jenkins 
draft: false
---



## Le plugin kubernetes (configurer un cloud dans Jenkins)

Une fois le plugin Kubernetes installé, Jenkins est capable de lancer automatiquement des agents dans kubernetes pour effectuer des jobs divers en particulier dans notre cas un pipeline de CI/CD.

Pour cela nous avons besoin:

1. que le plugin soit configuré pour se connecter à un cluster
1. qu'un modèle (template de pod) spot défini pour créer des agents qui permettent d'exécuter les étapes de notre pipeline dans des conteneurs contenant les outils nécessaires
1. que des ServiceAccount/Role/RoleBidings soient configurés pour autoriser Jenkins à déployer et contrôler des resources dans un ou plusieurs namespace de notre cluster
    - pour que Jenkins ait le droit de créer des agents
    - pour que ces agents ait le droit de créer les resources Kubernetes du déploiement

- Allez voir dans l'interface d'administration de Jenkins ``

## Pipeline as groovy code


## Tests unitaires dans un conteneur Python


```groovy
    stage("unit tests") {
        container('python') {
          git url: "${env.REPO_ADDRESS}", branch: "${env.REPO_BRANCH}"
          sh "pip install -r requirements.txt"
          sh "python -m pytest src/tests/unit_tests.py --verbose"
        }
    }
```

## Docker build, tag, login and push



### Comment tagguer notre image ?


## Déploiement en mode beta et Tests fonctionnels

- créer des namespace prod et dev
- créer deux roles et deux rolebindings

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: jenkins-deploy-role
  namespace: dev
rules:
  - apiGroups:
        - "*"
        # - apps
        # - autoscaling
        # - batch
        # - extensions
        # - networking.k8s.io
        # - policy
        # - rbac.authorization.k8s.io
    resources:
      - pods
      # - componentstatuses
      - configmaps
      # - daemonsets
      - deployments
      # - events
      # - endpoints
      # - horizontalpodautoscalers
      - ingresses
      # - jobs
      # - limitranges
      # - namespaces
      # - nodes
      - pods
      # - persistentvolumes
      # - persistentvolumeclaims
      # - resourcequotas
      # - replicasets
      # - replicationcontrollers
      # - serviceaccounts
      - services
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
```


```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: jenkins-deploy-roleb
  namespace: dev
subjects:
  - kind: ServiceAccount
    name: jenkins
    namespace: jenkins
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: jenkins-deploy-role
```


<!-- on pourrait aussi faire des tests de performance ici -->

### Que faire en cas d'échec ?

Il faut toujours se poser la question de l'échec et tester ses pipelines en les faisant échouer.

Désinstaller la release de test et supprimer l'image beta

<!-- try/catch -->

## Nettoyer !!!

désinstaller la release de dev si les tests sont ok




## Release : pousser une version validée de notre logiciel


## Déploiement en production et tests !

## Nettoyage final


<!-- virer les différents artefacts inutiles -->
<!-- prune les images beta, garder les releases -->


## Utiliser un Jenkinsfile et un pipeline multibranches

<!-- quel nom de domaine pour les stagiaires -->