---
title: TP4 - Créer le pipeline Jenkins 
draft: false
---



## Le plugin kubernetes (configurer un cloud dans Jenkins)

Une fois le plugin Kubernetes installé, Jenkins est capable de lancer automatiquement des agents dans kubernetes pour effectuer des jobs divers en particulier dans notre cas un pipeline de CI/CD.

Cela rend Jenkins fortement scalable car il peut lancer automatiquement de multiple agents et les détruire à la fin de la tâche.

Pour cela nous avons besoin:

1. que le plugin soit configuré pour se connecter à un cluster
1. qu'un modèle (template de pod) spot défini pour créer des agents qui permettent d'exécuter les étapes de notre pipeline dans des conteneurs contenant les outils nécessaires
1. que des ServiceAccount/Role/RoleBidings soient configurés pour autoriser Jenkins à déployer et contrôler des resources dans un ou plusieurs namespace de notre cluster
    - pour que Jenkins ait le droit de créer des agents
    - pour que ces agents ait le droit de créer les resources Kubernetes du déploiement

- Allez voir dans l'interface d'administration de Jenkins `Gérer les noeuds > Clouds > Kubernetes`

On y indique comment Jenkins se connecte au cluster Kubernetes pour y créer ses agents:
- adresse du cluster
- serviceAccount et namespace ou il a le droit de créer des ressources
- modèle de pod pour les agents Kubernetes (quelques conteneurs contenant les outils pour les étapes du pipeline)
- détails de connection des agents au master (avec JNLP sur le port 50000 par défaut)
## Pipeline as groovy code

Comme la plupart des éléments de Jenkins, les pipelines peuvent être configuré à l'aide de l'interface tentaculaire ou de fichiers de code. Nous allons bien sur choisir la 2e option.

Les pipelines sont écris en utilisant un DSL (sous langage spécialisé) basé groovy ("Java en mode script").

- Créez un nouveau job de type pipeline appelé `test_k8s_plugin`.

- Dans le formulaire de code en bas de la page ajoutez le code suivant:

```groovy
podTemplate(
  label: 'jenkins-k8s-test',
  namespace: "jenkins",
  serviceAccount: "jenkins",
  yaml: """
apiVersion: v1
kind: Pod
metadata:
  labels:
    component: ci
spec:
  containers:
    - name: alpine
      image: alpine
      command:
        - cat
      tty: true
"""
) {
  node('jenkins-k8s-test') {
    stage("test k8s") {
        container('alpine') {
          sh "echo 'hello k8s plugin'"
        }
    }
  }
}
```

## Tests unitaires dans un conteneur Python

- Créer un nouveau pipeline `monstericon-cicd`

- Dans le champ de code collez:

```groovy
import java.text.SimpleDateFormat

currentBuild.displayName = new SimpleDateFormat("yy.MM.dd").format(new Date())

// ###############
env.BASE_DOMAIN = "<votre domaine de base>" // e.g. myjenkinscluster.domain.eu
// ###############

env.REPO_ADDRESS = "https://github.com/Uptime-Formation/corrections_tp.git"
env.REPO_BRANCH = "jenkins_application"
env.REGISTRY_ADDRESS = "registry.${BASE_DOMAIN}"
env.APP_ADDRESS_BETA = "monstericon-beta.${BASE_DOMAIN}"
env.APP_ADDRESS_PROD = "monstericon.${BASE_DOMAIN}"
env.APP_NAME="monstericon"
env.IMAGE = "${env.REGISTRY_ADDRESS}/${env.APP_NAME}"
env.TAG = "${currentBuild.displayName}"
env.TAG_BETA = "${env.TAG}-${env.BRANCH_NAME}"

def nodelabel = "jenkins-k8sagent-${UUID.randomUUID().toString()}"

podTemplate(
  label: nodelabel,
  namespace: "jenkins",
  serviceAccount: "jenkins",
  yaml: """
apiVersion: v1
kind: Pod
metadata:
  labels:
    component: ci
spec:
  containers:
    - name: python
      image: python:3.9
      command:
        - cat
      tty: true
    - name: kubectl
      image: tecpi/kubectl-helm
      command: ["cat"]
      tty: true
"""
) {
    node(nodelabel){
    // instructions ici
    }
}
```

Ce code contient d'une part tous les paramètres, sous forme de variables d'environnement, notre pipeline comme par exemple le nom de domaine, le dépôt git et l'image docker utilisés.

D'autre part il déclare un modèle de pod pour l'agent Jenkins contenant les deux conteneurs dont nous aurons besoin pour réaliser la CI/CD (en plus du noeud docker du TP3 nécessaire pour le build) :

- un conteneur `python:3.9` pour lancer les tests
- un conteneur `kubectl` pour pouvoir déployer, monitorer et supprimer l'application dans le cluster

Les deux conteneurs sont lancés avec la commande `cat` de façon à rester allumé infiniment en attendant d'executer des taches envoyées par Jenkins.

Créons maintenant un stage (étape principale) du pipeline pour les tests unitaires:

- Ajoutez les instruction suivantes:

```groovy
    stage("unit tests") {
        container('python') {
          git url: "${env.REPO_ADDRESS}", branch: "${env.REPO_BRANCH}"
          sh "pip install -r requirements.txt"
          sh "python -m pytest src/tests/unit_tests.py --verbose"
        }
    }
```

Pour exécuter les tests unitaires, il suffit d'installer les dépendances puis de lancer le fichier python à l'intérieur du conteneur python.

Mais avant il faut récupérer le code en utilisant le plugin `git` de Jenkins.

Le code ainsi récupéré est téléchargé dans le dossier de travail de Jenkins et il est partagé entre tous les conteneurs du pod. Il est donc inutile de le récupérer dans chaque conteneur.

- Exécutez le pipeline dans l'interface BlueOcean de Jenkins.

Si tout va bien le stage devrait bien fonctionner.

## Docker build, tag, login and push

Une fois les tests unitaires validés on peut supposer que le logiciel est raisonnable peu buggé et qu'il est pertinent de construire une image et la pousser sur le dépôt.

Comme discuté dans le TP3 nous allons utiliser pour cela un noeud docker à part en tant qu'agent jenkins SSH pour des raisons de sécurité de notre cluster.

- Ajoutez le code suivant après le premier stage:

```groovy
    node("ssh-docker-agent") {
      stage("build") {
        git url: "${env.REPO_ADDRESS}", branch: "${env.REPO_BRANCH}"
        sh "sudo docker image build -t ${env.IMAGE}:${env.TAG_BETA} ."
        sh "sudo docker login ${env.REGISTRY_ADDRESS} -u 'none', -p 'none'"
        sh "sudo docker image push ${env.IMAGE}:${env.TAG_BETA}" // need ingress nginx bodysize 0 for the registry
      }
    }
```

Quelques remarques:

- Nous utilisons massivement les variables d'environnement ici pour pouvoir facilement paramétrer les tags à appliquer sur l'image.

- Pourquoi doit-on à nouveau récupérer le code avec git ?

Réponse: parce que nous ne sommes plus dans le pod pour ce stage. Jenkins ne peut pas partager le dossier de travail entre deux noeud hétérogènes automatiquement.

- On pourrait avoir besoin de se connecter au registry avec un identifiant et pour cela on devrait utiliser un crédential Jenkins dans le pipeline avec la syntaxe:

```groovy
withCredentials([usernamePassword(
    credentialsId: "docker-registry-login",
    usernameVariable: "USER",
    passwordVariable: "PASS"
)]) {
    sh "sudo docker login -u $USER -p $PASS ${env.REGISTRY_ADDRESS}"
}
```

#### Comment tagguer notre image ?

Il est important de pouvoir correctement identifier les artefacts (objets fabriqués) par les pipelines de CI/CD. On les identifie généralement à l'aide du **numéro de commit**,  de la **branche** et de l'**horodatage** du **"build"**.

Jenkins fournit pour cela diverses variables d'environnement et on peut utiliser des fonctions externe comme pour la date ici.

Il sera ensuite nécessaire de supprimer selectivement (on parle de pruning) les versions anciennes de notre image pour éviter le remplissage extrêment rapide de notre dépôt.

## Déploiement en mode beta et Tests fonctionnels

Maintenant que notre logiciel est testé statiquement avec les tests unitaires, nous aimerions le tester plus profondément avec des tests fonctionnels et d'intégration.

Pour cela il va d'abord falloir le déployer dans un environnement de `ci` car ces deux types de tests reposent sur l'ensemble des parties de notre application en particulier `redis` et `dnmonster` ici.

Pour le déploiement il est nécessaire de créer des namespace et de donner à Jenkins le droit de manipuler des ressources Kubernetes dans ce namespace.

C'est la fonction des objets de type `Role` et `RoleBinding` associés à un `ServiceAccount`:

- Le `ServiceAccount` est une sorte de compte utilisateur du cluster mais destiné aux programmes tournant dans le cluster. C'est ce qui donne à Kubernetes la possibilité d'être programmé de l'intérieur tout en garantissant un bon niveau de sécurité.

- Le `Role` est un ensemble de permissions détaillées sur les actions à appliquées aux ressources Kubernetes (un matrice ressources x action x apigroup)

- Enfin pour associer un `Role` à un compte sur le cluster (`ServiceAccount` ou User) on utilise un `RoleBinding`.

Appliquons ces éléments à notre cluster dans Lens :

- Créer des namespaces `prod` et `ci`

- Créer deux `Role` avec le code suivant (en changeant le namespace `ci` par `prod` pour le deuxième)

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: jenkins-deploy-role
  namespace: ci
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

- De même créez deux `RoleBinding` dans les namespaces `ci` et `prod`


```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: jenkins-deploy-roleb
  namespace: ci
subjects:
  - kind: ServiceAccount
    name: jenkins
    namespace: jenkins
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: jenkins-deploy-role
```

- Pour vérifier que ces configurations sont correctes lancez `kubectl auth can-i create deployment --as=system:serviceaccount:jenkins:jenkins -n ci` et `kubectl auth can-i create ingress --as=system:serviceaccount:jenkins:jenkins -n prod`

- Ajoutez le stage suivant au pipeline et relancez:

```groovy
 stage("functionnal tests") {
      try {
        container("kubectl") {
          sh "env"
          sh "kubectl kustomize k8s/overlays/dev | envsubst | tee manifests.yaml"
          sh "kubectl apply -f manifests.yaml -n ci"
          sh "kubectl -n ci rollout status deployment ${env.APP_NAME}"
        }
        container("python") {
          sh 'echo "nameserver 1.1.1.1" | tee /etc/resolv.conf' // fuck DNS resolution screw with functionnal tests
          sh "python src/tests/functionnal_tests.py http://${APP_ADDRESS_BETA}"
        }
      } catch(e) {
          error "Failed functional tests"
      } finally {
        container("kubectl") {
          sh "kubectl delete -f manifests.yaml -n ci" // uninstall test release
        }
      }
    }
```

Remarques:

- La partie déploiement s'effectue dans le conteneur `kubectl`
- ce code paramètre la kustomization en utilisant les variables d'environnement du pipeline grace à un utilitaire unix classique `envsubst`.
- La commande `kubectl -n ci rollout status deployment ${env.APP_NAME}` permet de surveiller le déploiement `monstericon` pour valider que l'application s'est bien lancée. On pourrait de même vérifier que l'ingress, les certificats ou les autres parties sont bien crées.

#### Que faire en cas d'échec ?

Enfin remarquons la construction `try` / `catch` / `finally` :

- Si les tests échouent on ne peux pas simplement ici arrêter le pipeline. Il faut désinstaller correctement la release de test sinon Jenkins risque de remplir rapidement notre cluster avec des releases échouées. 

- On utilise pour cela `finally` qui s'exécute de toute façon que le déploiement et les tests fonctionnent ou non.

- En effet si les tests fonctionnent on veut nettoyer à la fin de ce stage. Mais si on mettait le nettoyage simplement a la fin du stage sans `try` / `catch` / `finally`, un échec impliquerait que le nettoyage ne serait pas effectué.

Il faut toujours se poser la question de l'échec et tester ses pipelines en les faisant échouer.



<!-- Désinstaller la release de test et supprimer l'image beta -->

<!-- try/catch -->

<!-- ## Nettoyer !!! -->

<!-- désinstaller la release de dev si les tests sont ok -->

## Release : pousser une version validée de notre logiciel

Maintenant que nos tests sont tous concluants, nous aimerions pousser l'image de notre logiciel (buildée habituellement à partir du dernier commit de `main`) pour en faire la dernière version stable dans le dépot.

Pour cela nous allons retourner dans le conteneur Docker pour tagguer et pousser l'image.

- Ajoutez le stage suivant au pipeline et lancez le:

```groovy
    node("ssh-docker-agent") {
      stage("release") {
        sh "sudo docker pull ${env.IMAGE}:${env.TAG_BETA}"
        sh "sudo docker pull ${env.IMAGE}:latest"

        sh "sudo docker image tag ${env.IMAGE}:${env.TAG_BETA} ${env.IMAGE}:rollback"

        sh "sudo docker image tag ${env.IMAGE}:${env.TAG_BETA} ${env.IMAGE}:${env.TAG}"
        sh "sudo docker image tag ${env.IMAGE}:${env.TAG_BETA} ${env.IMAGE}:latest"

        sh "sudo docker login -u 'none' -p 'none' ${env.REGISTRY_ADDRESS}"

        sh "sudo docker image push ${env.IMAGE}:${env.TAG}"
        sh "sudo docker image push ${env.IMAGE}:latest"
        sh "sudo docker image push ${env.IMAGE}:rollback"
      }
    }
```

On taggue ici l'image avec le nom du build et aussi avec `latest` qui signifie dernière version stable.

## Déploiement en production et tests !

On peut maintenant déployer en production. Collez le code suivant à la suite du pipeline:

```groovy

    stage("Production deploy and tests") {
      try {
        container("kubectl") {
          sh "env"
          sh "kubectl kustomize k8s/overlays/prod | envsubst | tee manifests.yaml"
          sh "kubectl apply -f manifests.yaml -n prod"
          sh "kubectl -n prod rollout status deployment ${env.APP_NAME}"
        }
        container("python") {
          sh 'echo "nameserver 1.1.1.1" | tee /etc/resolv.conf' // fuck DNS resolution that screw with functionnal tests
          sh "python src/tests/functionnal_tests.py http://${APP_ADDRESS_BETA}"
        }
      } catch(e) {
          error "Failed production tests -> should rollback"
      } finally {
        container("kubectl") {
           // clean images and useless releases etc
        }
      }
    }
```

- Ici on répète sensiblement les même étapes que pour le déploiement de test mais dans le contexte de production:
    - dans le namespace prod
    - avec l'overlay prod (version production du déploiement)

- Concernant les tests on pourrait ici les adapter pour vérifier plus de paramètres en particulier des choses spécifiques à la production. Mais ces tests doivent ne pas être trop longs pour que le rollback soit rapide en cas de problème.

<!-- 
## Fin du pipeline
 -->

## Utiliser un Jenkinsfile et un pipeline multibranches

Maintenant que notre pipeline fonctionne, on aimerait pouvoir le déclencher automatiquement à chaque merge dans la branche `main`/`master`.

On voudrait également pouvoir créer une multitude de pipeline as code de test pour les différentes branches de notre projet.

C'est pour cela qu'on utilise généralement un job Jenkins de type `multibranch pipeline` basé sur un Jenkinsfile.

- Allez sur la page d'accueil de `BlueOcean` pour créer un nouveau pipeline.

- Sélectionnez type `Git` et ajoutez le dépôt `https://github.com/Uptime-Formation/corrections_tp.git` sans credential.

- Le pipeline se lance