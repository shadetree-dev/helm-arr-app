{{- define "arr-common.pvc" -}}
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: {{ .Release.Name }}-pvc
  namespace: {{ .Release.namespace }}
spec:
  storageClassName: {{ .Values.storageConfig.storageClassName }}
  {{- if .Values.storageConfig.volumeName }}
  volumeName: {{ .Values.storageConfig.volumeName }}
  {{- end }}
  volumeMode: {{ .Values.storageConfig.volumeMode }}
  accessModes:
    {{- range .Values.storageConfig.accessModes }}
    - {{ . }}
    {{- end }}
  resources:
    requests:
      storage: {{ .Values.storageConfig.volumeSize }}
{{- end }}
