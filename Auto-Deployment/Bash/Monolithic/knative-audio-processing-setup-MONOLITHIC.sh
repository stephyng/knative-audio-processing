#!/bin/bash

set -e

echo "🚀 Knative audio-feldolgozó környezet beállítása..."
echo "---"

# Minikube indítása
echo "🟡 Minikube indítása..."
minikube start || { echo "❌ Hiba a minikube indításakor."; exit 1; }
echo "✅ Minikube elindult."
echo "---"

# Knative Serving telepítése
echo "🟡 Knative Serving (v1.14.0) telepítése..."
kubectl apply -f https://github.com/knative/serving/releases/download/knative-v1.14.0/serving-crds.yaml
sleep 5
kubectl apply -f https://github.com/knative/serving/releases/download/knative-v1.14.0/serving-core.yaml
sleep 5
echo "✅ CRD-k és Core telepítve."

# Kourier Ingress konfigurálása
echo "🟡 Kourier telepítése és konfigurálása..."
kubectl apply -f https://github.com/knative-extensions/net-kourier/releases/download/knative-v1.14.0/kourier.yaml
sleep 5
kubectl patch configmap/config-network -n knative-serving --type merge -p '{"data":{"ingress.class":"kourier.ingress.networking.knative.dev"}}'
kubectl patch configmap/config-domain -n knative-serving --type merge -p '{"data":{"127.0.0.1.sslip.io":""}}'
echo "✅ Kourier beállítva."
echo "---"

# Knative Eventing telepítése
echo "🟡 Knative Eventing (v1.19.7) telepítése..."
kubectl apply -f https://github.com/knative/eventing/releases/download/knative-v1.19.7/eventing-crds.yaml
sleep 5
kubectl apply -f https://github.com/knative/eventing/releases/download/knative-v1.19.7/eventing-core.yaml
sleep 5
kubectl apply -f https://github.com/knative/eventing/releases/download/knative-v1.19.7/in-memory-channel.yaml
sleep 5
kubectl apply -f https://github.com/knative/eventing/releases/download/knative-v1.19.7/mt-channel-broker.yaml
sleep 5
echo "✅ Eventing telepítve."
echo "---"

# Knative Kafka Broker telepítése
echo "🟡 Knative Kafka Broker (v1.19.8) telepítése..."
kubectl apply -f https://github.com/knative-extensions/eventing-kafka-broker/releases/download/knative-v1.19.8/eventing-kafka-controller.yaml
sleep 5
kubectl apply -f https://github.com/knative-extensions/eventing-kafka-broker/releases/download/knative-v1.19.8/eventing-kafka-broker.yaml
sleep 5
kubectl apply -f https://github.com/knative-extensions/eventing-kafka-broker/releases/download/knative-v1.19.8/eventing-kafka-post-install.yaml
sleep 5
echo "✅ Kafka Broker telepítve."
echo "---"

# Nodeselector engedélyezése
echo "🟡 Nodeselector engedélyezése a Knative Serving-ben..."
kubectl -n knative-serving patch cm config-features --type merge -p '{"data":{"kubernetes.podspec-nodeselector":"enabled"}}'
echo "✅ Nodeselector engedélyezve."
echo "---"

# Service-ek telepítése
echo "🟡 Microservice-ek telepítése..."
kubectl apply -f ./Monolithic/Minio/minio-deployment.yaml
kubectl apply -f ./Monolithic/Deployments/kafka-broker-receiver-patch.yaml

# -----------------------------
kubectl apply -f ./Monolithic/Deployments/aws-k3s-service-autoscale-off.yaml
echo "🕒 Várakozás, amíg a knative-audio-processor pod létrejön és Running állapotba kerül..."
while [[ -z $(kubectl get pods -l serving.knative.dev/service=knative-audio-processor -o jsonpath='{.items[0].metadata.name}' 2>/dev/null) ]]; do
  sleep 2
done
POD_NAME=$(kubectl get pods -l serving.knative.dev/service=knative-audio-processor -o jsonpath='{.items[0].metadata.name}')
while [[ $(kubectl get pod $POD_NAME -o jsonpath='{.status.phase}') != "Running" ]]; do
  sleep 3
done
echo "✅ A knative-audio-processor pod fut (Running)."
kubectl wait --for=condition=Ready pod -l serving.knative.dev/service=knative-minio-processor
echo "✅ A knative-audio-processor pod készen áll."

echo "🎉 **Telepítés befejezve!** Minden komponens elvileg fut a minikube klaszterben."
echo "---"