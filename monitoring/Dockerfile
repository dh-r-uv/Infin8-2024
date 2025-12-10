FROM docker.elastic.co/beats/metricbeat:7.17.0
COPY mb.yml /usr/share/metricbeat/metricbeat.yml
USER root
RUN chmod go-w /usr/share/metricbeat/metricbeat.yml
