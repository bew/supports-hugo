---
draft: true
title: Notes
---

elastic :
https://www.ekino.fr/publications/une-solution-dapm-dans-la-suite-elastic/
https://openapm.io/landscape
https://openapm.io/landscape?agent=elastic-beats,elastic-apm-agent&data-processing=logstash&visualization=kibana&dashboarding=kibana&storage=elasticsearch&collector=elastic-apm&showCommercial=true&showFormats=true

https://www.elastic.co/fr/subscriptions

## APM

https://www.youtube.com/watch?v=2sdOvuLiBb8
https://www.elastic.co/guide/en/apm/get-started/current/index.html

WTF ?? http://localhost:5601/app/kibana#/home/tutorial/logstashLogs?\_g=()

localhost:5601/app/kibana#/home/tutorial/systemLogs?\_g=() http://localhost:5601/app/kibana#/home/tutorial/nginxLogs?\_g=()

si y a osquery dans filebeat en module, logstash sert vraiment pas à grand chose qia,d ù$eùe

https://github.com/lmenezes/cerebro-docker
http://docs.elastichq.org/installation.html#environment-variables
https://www.elastic.co/guide/en/sense/current/installing.html

parler d'ECS ? Non

http://goinbigdata.com/how-to-create-your-own-cluster-with-virtualbox/

    https://www.digitalocean.com/community/tutorials/how-to-set-up-a-production-elasticsearch-cluster-on-ubuntu-14-04e

TODO:

Questions:

- IV) :
  - Présenter trois types d'aggrégations:
    bucket, metric (une dimension de vos données), pipeline (composée)
    exemple vous voulez calculer le prix moyen par companies
    aggréger les avions par companies, combiner à avec une aggrégation avg
    faire un schéma au tableau en plusieurs étapes pour bien expliquer
  - Trouver Utiliser cet exemple dans Kibana pour faire un graphique.
- V) Life in a cluster:

  - Remettre dans le slide la syntaxe pour mettre à jour les shards d'un cluster
  - Ajouter supprimer un noeud ? réindexer

  - Parler des nodes et des shards
    - un slides sur les nodes
    - un sur les Shards
      Des bouts de tableaux d'index.
      (Toute une logistique de copies des informations pour que ce soit facile d'accès
      et rapide à mettre à jour).
    - Haute Dispo
      - un service qui a 100% de disponibilité et qui est résiliant.
      - redondance
      - autonomie (healthcheck + election)
      - basculement dynamique (load balancing)
      - migrations et mises à jour progressives
    - Shard principal et replicat
    - La formule du green
    - En cas de chute de noeud
      - load balancing
      - Élection d'un nouveau master node
  - Tester ensemble:
    - calculer la répartition pour un cluster à 2 ou 3 noeuds
    - changer les propriétés de l'index

GET /\_cluster/health

PUT /blogs/\_settings
{
"number_of_replicas" : 2
}

PUT /blogs
{
"settings" : {
"number_of_shards" : 3,
"number_of_replicas" : 1
}
} - vérifier le status du cluster - supprimer un noeuds
le service est-il toujours

https://www.elastic.co/guide/en/elasticsearch/reference/current/modules-discovery-bootstrap-cluster.html#modules-discovery-bootstrap-cluster-joining

FIXME: séarer clustering d'elasticsrarch de Lucene det de l'api elasticsearch dans le cours.
Couper 1er cours par exos

---

Retours 11/09 :
- Sécu logstash => append only etc.
- sécu de migrating, draining, jeu de test ?
- types d'archi ELK conseillées => sortir des schémas depuis outil stylé de création de stack monitoring + compartimentage VM
- formations précédentes demander si y a eu et OBLIGER GENS A ETRE HOMOGENES DATA OU SYSADMIN pour pouvoir aller plus loin (mais du coup faut des super TP avancés)
- si "mise en oeuvre" en 1J faut que ce soit thémmatique : soit enrolement d'agents et wzuh/ossec, soit archi cluster et ILM et backups, soit débitage grok logstash, soit API ES avancé dev tools, soit dashboards kibana super complexes
- rajouter partie "droit d'en connaitre" : RBAC Kibana + ES, "Espaces Kibana", vrai TP ES RBAC
- GROS TP sur painless et sur le raffinage / retraitement de documents dans les index, à mettre aussi dans cours