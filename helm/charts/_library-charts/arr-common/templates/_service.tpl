{{- define "arr-common.service" -}}
apiVersion: v1
kind: Service
metadata:
  name: {{ .Release.Name }}
  namespace: {{ .Release.namespace }}
  annotations:
    metallb.universe.tf/allow-shared-ip: {{ .Release.Name }}
spec:
  selector:
    app: {{ .Release.Name }}
  type: {{ .Values.service.type }}
  loadBalancerIP: {{ index .Values.service.externalIPs 0 }}
  externalIPs:
  {{- range .Values.service.externalIPs }}
    - {{ . }}
  {{- end }}
  ports:
  {{- range .Values.ports }}
    - name: {{ .name }}
      port: {{ .targetPort }}
      targetPort: {{ .containerPort }}
      protocol: {{ .protocol }}
  {{- end }}
{{- end }}