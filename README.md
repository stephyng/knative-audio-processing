# knative-audio-processing

Follow these steps (Monolithic):

mc alias set local http://127.0.0.1:<> minioadmin minioadmin
mc mb local/knative-audio-processor
mc admin config set local notify_webhook:knative endpoint="http://knative-audio-processor.default.svc.cluster.local/minio-event"
mc admin service restart local
mc event add local/knative-audio-processor arn:minio:sqs::knative:webhook --event put
*upload mp3 File to MinIO Bucket*



Follow these steps (Microservices):

mc alias set local http://127.0.0.1:<> minioadmin minioadmin
mc mb local/knative-audio-processor
mc admin config set local notify_webhook:knative endpoint="http://knative-minio-processor.default.svc.cluster.local/minio-event"
mc admin service restart local
mc event add local/knative-audio-processor arn:minio:sqs::knative:webhook --event put
*upload mp3 File to MinIO Bucket*



For any pod LOG information, use the following command:
kubectl logs -l serving.knative.dev/service=<SERVICE> -c user-container --tail=100