---
title: 'Cours 5 - Sécurité et Cloud'
draft: false
weight: 50
---

# Sécurité

Les problématiques de sécurité linux ne sont pas résolues magiquement par Ansible. Tout le travail de réflexion et de sécurisation reste identique mais peut comme le reste être mieux contrôlé grace à l'approche déclarative de l'infrastructure as code.

Si cette problématique des liens entre Ansible et sécurité vous intéresse : `Security automation with Ansible`

Il est à noter tout de même qu'Ansible est généralement apprécié d'un point de vue sécurité car il n'augmente pas (vraiment) la surface d'attaque de vos infrastructure : il est basé sur ssh qui est éprouvé et ne nécessite généralement pas de réorganisation des infrastructures.

Pour les cas plus spécifiques et si vous voulez éviter ssh, Ansible est relativement agnostique du mode de connexion grâce aux plugins de connexions (voir ci-dessous).


## Authentification et SSH

Il faut idéalement éviter de créer un seul compte ansible de connexion pour toutes les machines:
- difficile à bouger
- responsabilité des connexions pas auditable (auth.log + syslog)

Il faut utiliser comme nous avons fait dans les TP des logins ssh avec les utilisateurs humain réels des machines et des clés ssh. C'est à dire le même modèle d'authentification que l'administration traditionnelle.

## Les autres modes de connexion

Le mode de connexion par défaut de Ansible est SSH cependant il est possible d'utiliser de nombreux autres modes de connexion spécifiques :

- Pour afficher la liste des plugins  disponible lancez `ansible-doc -t connection -l`.

- Une autre connexion courante est `ansible_connection=local` qui permet de configurer la machine locale sans avoir besoin d'installer un serveur ssh.

- Citons également les connexions `ansible_connection=docker` et `ansible_connection=lxd` pour configurer des conteneurs linux ainsi que `ansible_connection=winrm` pour les serveurs windows

- Pour débugger les connexions et diagnotiquer leur sécurité on peut afficher les détails de chaque connection ansible avec le mode de verbosité maximal (network) en utilisant le paramètre `-vvvv`.

## Variables et secrets

Le principal risque de sécurité lié à Ansible comme avec Docker et l'IaC en général consiste à laisser trainer des secrets (mot de passe, identités de clients, api token, secret de chiffrement / migration etc.) dans le code ou sur les serveurs (moins problématique).

Attention : les dépôts Git peuvent cacher des secrets dans leur historique.
<!-- Pour chercher et nettoyer un secret dans un dépôt l'outil le plus courant est BFG : https://rtyley.github.io/bfg-repo-cleaner/ -->


## Ansible Vault

Pour éviter de divulguer des secrets par inadvertance, il est possible de gérer les secrets avec des variables d'environnement ou avec un fichier variable externe au projet qui échappera au versionning git, mais ce n'est pas idéal.

Ansible intègre un trousseau de secret appelé , **Ansible Vault** permet de chiffrer des valeurs **variables par variables** ou des **fichiers complets**.
Les valeurs stockées dans le trousseaux sont déchiffrée à l'exécution après dévérouillage du trousseau. 

- `ansible-vault create /var/secrets.yml`
- `ansible-vault edit /var/secrets.yml` ouvre `$EDITOR` pour changer le fichier de variables.
- `ansible-vault encrypt_file /vars/secrets.yml` pour chiffrer un fichier existant
- `ansible-vault encrypt_string monmotdepasse` permet de chiffrer une valeur avec un mot de passe. le résultat peut être ensuite collé dans un fichier de variables par ailleurs en clair.

Pour déchiffrer il est ensuite nécessaire d'ajouter l'option `--ask-vault-pass` au moment de l'exécution de `ansible` ou `ansible-playbook`

Il existe également un mode pour gérer plusieurs mots de passe associés à des identifiants.

## Désactiver le logging des informations sensibles

Ansible propose une directive `no_log: yes` qui permet de désactiver l'affichage des valeurs d'entrée et de sortie d'une tâche.

Il est ainsi possible de limiter la prolifération de données sensibles dans les logs qui enregistrent le résultat des playbooks Ansible.

## Ansible dans le cloud

L'automatisation Ansible fait d'autant plus sens dans un environnement d'infrastructures dynamique :

- L'agrandissement horizontal implique de résinstaller régulièrement des machines identiques
- L'automatisation et la gestion des configurations permet de mieux contrôler des environnements de plus en plus complexes.

Il existe de nombreuses solutions pour intégrer Ansible avec les principaux providers de cloud (modules ansible, plugins d'API, intégration avec d'autre outils d'IaC Cloud comme Terraform ou Cloudformation).

## Inventaires dynamiques

Les inventaires que nous avons utilisés jusqu'ici impliquent d'affecter à la main les adresses IP des différents noeuds de notre infrastructure. Cela devient vite ingérable.

La solution ansible pour ne pas gérer les IP et les groupes à la main est appelée `inventaire dynamique` ou `inventory plugin`. Un inventaire dynamique est simplement un programme qui renvoie un JSON respectant le format d'inventaire JSON ansible, généralement en contactant l'API du cloud provider ou une autre source.

```
$ ./inventory_terraform.py
{
  "_meta": {
    "hostvars": {
      "balancer0": {
        "ansible_host": "104.248.194.100"
      },
      "balancer1": {
        "ansible_host": "104.248.204.222"
      },
      "awx0": {
        "ansible_host": "104.248.204.202"
      },
      "appserver0": {
        "ansible_host": "104.248.202.47"
      }
    }
  },
  "all": {
    "children": [],
    "hosts": [
      "appserver0",
      "awx0",
      "balancer0",
      "balancer1"
    ],
    "vars": {}
  },
  "appservers": {
    "children": [],
    "hosts": [
      "balancer0",
      "balancer1"
    ],
    "vars": {}
  },
  "awxnodes": {
    "children": [],
    "hosts": [
      "awx0"
    ],
    "vars": {}
  },
  "balancers": {
    "children": [],
    "hosts": [
      "appserver0"
    ],
    "vars": {}
  }
}%  
```

On peut ensuite appeler `ansible-playbook` en utilisant ce programme plutôt qu'un fichier statique d'inventaire: `ansible-playbook -i inventory_terraform.py configuration.yml`

## Étendre et intégrer Ansible

### La bonne pratique : utiliser un plugin d'inventaire pour alimenter

Bonne pratique : Normalement l'information de configuration Ansible doit provenir au maximum de l'inventaire. Ceci est conforme à l'orientation plutôt déclarative d'Ansible et à son exécution descendante (master -> nodes). La méthode à privilégier pour intégrer Ansible à des sources d'information existantes est donc d'utiliser ou développer un **plugin d'inventaire**.

[https://docs.ansible.com/ansible/latest/plugins/inventory.html](https://docs.ansible.com/ansible/latest/plugins/inventory.html)

On peut cependant alimenter le dictionnaire de variable Ansible au fur et à mesure de l'exécution, en particulier grâce à la directive `register` et au module `set_fact`.

Exemple:

```yaml
# this is just to avoid a call to |default on each iteration
- set_fact:
    postconf_d: {}

- name: 'get postfix default configuration'
  command: 'postconf -d'
  register: postconf_result
  changed_when: false

# the answer of the command give a list of lines such as:
# "key = value" or "key =" when the value is null
- name: 'set postfix default configuration as fact'
  set_fact:
    postconf_d: >
      {{ postconf_d | combine(dict([ item.partition('=')[::2]map'trim') ])) }}
  loop: postconf_result.stdout_lines
```

On peut explorer plus facilement la hiérarchie d'un inventaire statique ou dynamique avec la commande:

```
ansible-inventory --inventory <inventory> --graph
```

### Principaux type de plugins possibles pour étendre Ansible

[https://docs.ansible.com/ansible/latest/dev_guide/developing_plugins.html](https://docs.ansible.com/ansible/latest/dev_guide/developing_plugins.html)

- modules
- inventory plugins
- connection plugins
- callback plugins : https://docs.ansible.com/ansible/latest/collections/index_callback.html
- lookup plugins : https://docs.ansible.com/ansible/latest/collections/index_lookup.html et https://docs.ansible.com/ansible/latest/plugins/lookup.html
- filter plugins

<!-- ### Intégration Ansible et AWS

Pour les VPS de base Amazon EC2 : utiliser un plugin d'inventaire AWS et les modules adaptés.

- Module EC2: [https://docs.ansible.com/ansible/latest/modules/ec2_module.html](https://docs.ansible.com/ansible/latest/modules/ec2_module.html).
- Plugin d'inventaire: [https://docs.ansible.com/ansible/latest/plugins/inventory/aws_ec2.html](https://docs.ansible.com/ansible/latest/plugins/inventory/aws_ec2.html). -->

<!-- ### Intégration Ansible Nagios


**Possibilité 1** : Gérer l'exécution de tâches Ansible et le monitoring Nagios séparément, utiliser le [module nagios](https://docs.ansible.com/ansible/latest/modules/nagios_module.html) pour désactiver les alertes Nagios lorsqu'on manipule les ressources monitorées par Nagios.

**Possibilité 2** : Laisser le contrôle à Nagios et utiliser un plugin pour que Nagios puisse lancer des plays Ansible en réponse à des évènements sur les sondes. -->

### Ansible et Terraform

Voir TP4.

### Ansible et Kubernetes

- pour déployer un cluster initialement, avec `kubespray`
- pour ajouter et supprimer des ressources K8S avec le module `community.kubernetes.k8s`

## Exécuter Ansible en production : les stratégies d'exécution:

https://docs.ansible.com/ansible/latest/user_guide/playbooks_strategies.html


## Serveur pour exécuter Ansible dans une équipe

- AWX/Tower
  - Serveur officiel RedHat et sa version open source
  - assez lourd et installable uniquement dans kubernetes/openshift
  - très puissant
  - plein de plugins d'intégration
  - logging des exécutions assez optimal

- Jenkins
  - Un peu vieux mais très versatile
  - un bon plugin ansible
  - gestion de ansible-vault et des credentials

- Rundeck
  - une alternative à AWX/Ansible Tower assez populaire et plus légère

- Gitlab
  - faisable mais pas très bien intégré

- Un simple serveur avec Ansible d'installé

- Depuis la machine de chaque adminsys, en clonant les bonnes versions des dépôts Git, en récupérant un Vault et en poussant les logs de façon centralisée

## Exemple d'installation complexe

![](../../images/ansible/ansible_admin.png)