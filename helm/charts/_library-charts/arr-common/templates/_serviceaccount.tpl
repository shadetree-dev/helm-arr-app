{{- define "arr-common.serviceaccount" -}}
{{- if .Values.serviceAccount.create -}}
apiVersion: v1
kind: ServiceAccount
metadata:
  {{- if .values.serviceAccount.name}}
    name: {{ .values.serviceAccount.name }}
  {{- else }}
    name: {{ .Release.Name }}
  {{- end }}
  labels:
    app: {{ .Release.Name }}
  annotations:
    app: {{ .Release.Name }}
automountServiceAccountToken: {{ .Values.serviceAccount.automount }}
{{- end }}
{{- end }}