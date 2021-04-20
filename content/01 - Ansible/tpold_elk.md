---
draft: true
---

Installation d'un cluster Elastic avec Ansible

Mettre en place son cluster
---------------------------

On va utiliser trois machines virtuelles avec 1 Go de RAM pour notre cluster.

1.  Importer deux machines Ubuntu Server (1GB) (appelez-les elk-node1 et elk-node2)
2.  Nous utilisons toujours la machine Ubuntu Desktop (1GB) (master)
3.  Copier sur le TP1 pour mettre les 3 machines dans le même réseau
4.  Allumer les trois machines.
5.  Dans chacune, trouver un terminal/tty et lancez `**ip a**` ou
    `**ifconfig**`
6.  Relevez les adresses IP des trois machines :

-   node 1
-   node 2
-   master

1.  Vérifiez que vous pouvez pinguer les autres machines du cluster

Installer Elasticsearch
-----------------------

1. Téléchargez dans roles les fichier **elasticsearch.zip** et **kibana.zip**
2. Décompressez ces dossiers avec **unzip**
3. Observez l'intérieur du rôle elasticsearch complet. Combien de variables utilise ce rôle ? Combien de handlers ?

3. Lancez `ansible-playbook setup_elastic.yml` après avoir pris soin de vérifier que hosts visait le groupe `elk_nodes`. Les requirements sont installés ! Voyez les `ok` et `changed` apparaissant lorsque vous lancez le playbook : Ansible est verbeux, il informe de sa réussite.
4.  Ajoutez à la suite ces trois commandes (tasks) Ansible (qui vont servir à installer Elasticsearch sur chacun des nodes) :
```yaml
- name: Install a list of packages
  apt:
    name: "{{ packages }}"
    state: present
  vars:
    packages:
    - apt-transport-https
    - uuid-runtime
    - openjdk-11-jre-headless-
    - gpg

- name: Add elasticsearch repo GPG key
  apt_key:
    url: <url>
  state: present

- name: Add elasticsearch apt repo
  apt_repository:
    repo: <repo debian>
    state: present

- name: Install Elasticsearch # requires java preinstalled
  apt: pkg=elasticsearch state=present
```

1.  Complétez ces commande à l'aide des paramètres ci-dessous
    - URL de la clé GPG des dev de Elasticsearch :
    https://artifacts.elastic.co/GPG-KEY-elasticsearch

    - répertoire Debian pour Elasticsearch :
    `deb https://artifacts.elastic.co/packages/6.x/apt stable main`

2.  Relancez le playbook !


Configurer Elasticsearch en cluster
-----------------------------

1.  Il manque la configuration ! Ajoutez une nouvelle commande pour
    créer le fichier de configuration :
```yaml
- name: Configure Elasticsearch.
  template:
    src: <template>
    dest: /etc/elasticsearch/elasticsearch.yml
  owner: root
  group: elasticsearch
  mode: 0740
  notify: restart elasticsearch
```

1. Observez le fichier `template/elasticsearch.yml.j2` : c'est un modèle de fichier de configuration. Il contient des trous `{{ var }}` qui doivent être remplis par les variables du playbook.
2. Ajoutez les variables suivantes avant les tasks (attention aux alignements ! `vars` doit être aligné avec `tasks:`) :
```yaml
vars:
  - elasticsearch_cluster_name: elk_formation
  - elasticsearch_network_host: "0.0.0.0"
  - elasticsearch_http_port: 9200
  - elk_node_ips:
    - 10.0.2.4
    - 10.0.2.5
```
Pensez à changer les IP pour désigner vos nœuds Elasticsearch.

1.  Ajoutez la fin suivante au playbook :
```yaml
  - name: Start Elasticsearch.
    systemd:
    name: elasticsearch
    state: restarted
    enabled: yes
    daemon_reload: yes #required before first run

  - name: Make sure Elasticsearch is running before proceeding.
    wait_for: host={{ elasticsearch_network_host }} port={{
elasticsearch_http_port }} delay=3 timeout=300

handlers:
  - name: restart elasticsearch
    service: name=elasticsearch state=restarted
```

(attention aux alignements : handlers est au même niveau que tasks)

1.  Jouer le playbook enfin complet. Si la dernière tâche échoue, recréez vos machines avec 2gb de RAM, réinstallez Python sur chaque machine (`ansible all --become -m raw -a 'ln -s /usr/bin/python3 /usr/bin/python'`), puis relancez **setup_elastic.yml**. Tout est remis comme avant en quelques minutes et Elasticsearch devrait mieux fonctionner maintenant.
2.  Lancez les commandes de diagnostic

- `curl http://10.0.2.4:9200/_cat/nodes?pretty`
- `curl -XGET 'http://10.0.2.4:9200/_cluster/state?pretty'`

Si tout est bien configuré vous devriez voir une liste de deux nœuds
signifiant que les deux nœuds Elasticsearch se « connaissent ».

    Pour ajouter un nouveau nœud !

- importer une nouvelle machine
- l'ajouter au fichier hosts
- ajoutez les IP dans `vars`
- relancer le playbook… **#magic !**

Installer Kibana
----------------

### Installer kibana
    
Pour installer kibana (le GUI web de elasticsearch) il faut idéalement un nouveau noeud et un autre playbook très proche celui que nous venons de compléter.

```ini
[kibana_nodes] 
kibana_node ansible_host=<ip>
```
    
- Lancez le playbook `ping.yml` après avoir changé `hosts: elastic_nodes` en `hosts: all` dans ce playbook. Vous devriez maintenant atteindre 3 serveurs au lieu de deux.
- Copier `setup_elastic.yml` et renommer le en `setup_kibana.yml`.
- Remplacez son contenu par :

```yml
- hosts: <group>
  become: yes

  vars:
    - kibana_server_port: 5601
    - kibana_server_host: "0.0.0.0"
    - kibana_elasticsearch_url: "http://<elastic_node_ip>:9200"
    - kibana_elasticsearch_username: ""
    - kibana_elasticsearch_password: ""

  tasks:
    - name: Install apt requirements
      apt:
        name: 
          - apt-transport-https
          - uuid-runtime
          - openjdk-11-jre-headless
          - gpg
        state: present
        update_cache: yes

    - name: Add elasticsearch repo GPG key
      apt_key:
        url: https://artifacts.elastic.co/GPG-KEY-elasticsearch
        state: present

    - name: Add elasticsearch apt repo
      apt_repository:
        repo: "deb https://artifacts.elastic.co/packages/6.x/apt stable main"
        state: present

    - name: Install Kibana
      apt: 
        name: <package_name>
        state: <state>

    - name: Configure Kibana.
      template:
        src: <template_name>
        dest: /etc/kibana/kibana.yml
        owner: root
        group: kibana
        mode: 0740 # Kibana service run with user kibana in group kibana
      notify: restart kibana

    - name: Create kibana log file
      file:
        state: touch
        path: /var/log/kibana.log
        owner: kibana
        mode: 740

    - name: Start Kibana.
      systemd:
        name: kibana
        state: started
        enabled: yes
        daemon_reload: yes #required before first run

  handlers:
    - name: restart kibana
      service:
      	name: kibana
        state: restarted
```

- Remplacez : <elastic_node_ip> par l'IP d'un des nœuds Elasticsearch dans le playbook pour Kibana

- Complétez les (4) trous dans le playbook de façon logique et en s'inspirant du précédent.
- Lancer : `ansible-playbook setup_kibana.yml`
- Accéder à `http://<ip_kibana>:5601` dans firefox :D
- Vérifier que le groupe `kibana_node` dans hosts pointe bien vers `elk-master`

- Lancez : `ansible-playbook setup_kibana.yml`

- Accédez à localhost:5601 dans firefox :D


----------



<!--

- Pour "boucher les trous" de la configuration, ajoutez les variables suivantes (section vars: prendre exemple sur le cours) avant les tasks : attention aux alignement ! `vars:` doit être aligné avec `tasks:`

```yml
vars:
  - elasticsearch_cluster_name: elk_formation
  - elasticsearch_network_host: "0.0.0.0"
  - elasticsearch_http_port: 9200
  - elk_node_ips:
    - <ip_node_1>
    - <ip_node_2>
```

- Pensez à changer les ips pour désigner vos nœuds elastic.
- Lorsqu'on change la configuration il faut généralement recharger ou redémarrer le service : ajoutez la fin suivante au playbook :

```yml
    - name: Setup Heap Memory size in /etc/elasticsearch/jvm.options
      lineinfile:
        path: /etc/elasticsearch/jvm.options
        regexp: "^-Xm{{ item }}.*"
        line: "-Xm{{ item }}800m"    
      loop:
        - 's'
        - 'x'
      notify: restart elasticsearch

    - name: Start Elasticsearch.
      systemd:
        name: elasticsearch
        state: <state>
        enabled: yes
        daemon_reload: yes #required before first run

    - name: Make sure Elasticsearch is running before proceeding.
      wait_for:
        host: "{{ elasticsearch_network_host }}"
        port: "{{ elasticsearch_http_port }}"
        delay: 3
        timeout: 60

  handlers:
    - name: restart elasticsearch
      service:
        name: elasticsearch
        state: <state>
```

(attention aux alignements : handlers est au même niveau que tasks)

-  Jouez le playbook enfin complet.

Si votre playbook s'est exécuté sans erreurs, c'est que elastic devrais être installé. Pour vérifier sont fonctionnement essayons de le contacter sur le réseau:
    
- Lancez les commandes suivantes:

```bash
curl http://<ip_node_1>:9200/_cat/nodes?pretty
curl -XGET '<ip_node_2>:9200/_cluster/state?pretty'
```

Si tout est bien configuré vous devriez voir une liste de deux nœuds signifiant que les deux elastic se « connaissent ».


- Ajoutez un nouveau noeud `kibana_node` au `Vagrantfile` en copiant et modifiant la section adéquate.
- Lancez `vagrant up` pour créer le troisième noeud.
- Ajoutez un nouveau groupe à la fin de l'inventaire comme suit:

- Créez un commit dans le dépot pour sauvegarder tout ce travail :D !

### Correction

La correction du TP se trouve dans le dépôt modèle `https://github.com/e-lie/ansible-tpl-elk-forma` dans la branche `correction_elastic_install_vagrant`. -->












<!-- 
Finir l'installation d'Elasticsearch et Kibana
----------------------------------------------

Les nœuds elasticsearch fonctionnent mais il ne sont pas connectés entre
eux. Pour cela il doivent être configurés avec la liste de leurs
voisins. Il faut donc changer le fichier de configuration elasticsearch.

D'abord : comment récupérer automatiquement la liste des ip des nœuds du
groupe elastic_node ? Il y a une variable pour cela : **groups**

1.  À la fin du fichier **roles/elastisearch/tasks/main.yml** ajoutez 3
    tâches de debug pour le vérifier :

- debug:

msg: "{{ groups }}"

- debug:

msg: "{{ groups.elastic_nodes }}"

- debug:

msg: "{{ groups.elastic_nodes.0 }}"

La première tâche vous affiche un long dictionnaire de variables.
**groups.elastic_nodes** récupère juste la liste des ip du groupe qui
nous intéresse et **groups.elastic_nodes.0** vous permet de récupérer
la première ip de la liste.

1.  Avec ça nous pouvons dire à chaque elastic de rencontrer ses
    voisins. Ouvrez le fichier
    **roles/elastisearch/templates/elasticsearch.yml.j2**.
2.  Remplacez la ligne #discovery.zen.ping.unicast.hosts: (ligne 73)
    par :

discovery.zen.ping.unicast.hosts:

{% for node_ip in groups.elastic_nodes %}

- {{ node_ip }}

{% endfor %}

Il s'agit d'une boucle **for** comme en python : groups.elastic_nodes
est une liste. À chaque tour de boucle Ansible ajoute une ip au fichier
de config de elasticsearch.

1.  Relancez le playbook **elastic.yml**
2.  Récupérez l'ip d'un nœud elastic. Dans un navigateur, visitez **<ip
    elastic>:9200/_cat/nodes?pretty** Si tout est bien configuré vous
    devriez voir une liste de trois nœuds signifiant que les trois
    elastic se « connaissent ».
3.  Pour installer kibana, copiez **elastic.yml** en **kibana.yml**,
    changez **elastic_nodes** par **kibana_nodes** et le rôle
    elasticsearch par kibana.
4.  Ajoutons une variable pour précisez l'ip d'un nœud elastic. Au
    dessus de **tasks:**, ajoutez :

vars:

- kibana_elasticsearch_url: "http://{{ groups.elastic_nodes.1
}}:9200"

1.  Lancez le playbook kibana.yml
2.  Attendez 20 secondes puis visitez dans un navigateur **<ip
    kibana>:5601 : woahh ;D**
 -->
