{{- define "arr-common.deployment" -}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}
  namespace: {{ .Release.namespace }}
  labels:
    app: {{ .Release.Name }}
spec:
  {{- if .Values.serviceAccount.name }}
  serviceAccountName: {{ .Values.serviceAccount.name }}
  {{- else if .Values.serviceAccount.create }}
  serviceAccountName: {{ .Release.Name }}
  {{- end }}
  progressDeadlineSeconds: 600
  replicas: 1
  revisionHistoryLimit: 5
  selector:
    matchLabels:
      app: {{ .Release.Name }}
  strategy:
    rollingUpdate:
      maxSurge: 0
      maxUnavailable: 1
    type: RollingUpdate
  template:
    metadata:
      labels:
        app: {{ .Release.Name }}
    spec:
      {{- if .Values.affinity }}
      affinity:
        {{- toYaml .Values.affinity | nindent 8 }}
      {{- end }}
      {{- if .Values.securityContext }}
      securityContext:
        {{- toYaml .Values.securityContext | nindent 8 }}
      {{- end }}
      containers:
        - name: {{ .Release.Name }}
          {{- if .Values.podSecurityContext }}
          securityContext:
            {{- toYaml .Values.podSecurityContext | nindent 12 }}
          {{- end }}
          {{- if .Values.env }}
          env:
            {{- range .Values.env }}
            - name: {{ .name }}
              value: {{ .value | quote }}
            {{- end }}
          {{- end }}
          {{- if .Values.image.repository }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          {{- else }}
          image: "linuxserver/{{ .Release.Name }}:{{ .Values.image.tag }}"
          {{- end }}
          imagePullPolicy: "{{ .Values.image.pullPolicy }}"
          ports:
            {{- range .Values.ports }}
            - name: {{ .name }}
              containerPort: {{ .containerPort }}
              protocol: {{ .protocol }}
            {{- end }}
          resources:
            {{- if .Values.resources }}
            limits:
              {{- range $key, $value := .Values.resources.limits }}
              {{ $key }}: {{ $value }}
              {{- end }}
            requests:
              {{- range $key, $value := .Values.resources.requests }}
              {{ $key }}: {{ $value }}
              {{- end }}
            {{- end }}
          stdin: true
          terminationMessagePath: /dev/termination-log
          terminationMessagePolicy: File
          tty: true
          volumeMounts:
            # Fixed config volume mount
            - name: {{ .Release.Name }}-config
              mountPath: /config
            # Additional volume mounts from values.yaml
            {{- if .Values.volumeMounts }}
            {{- range .Values.volumeMounts }}
            - name: {{ .name }}
              mountPath: {{ .mountPath }}
              {{- if .readOnly }}
              readOnly: {{ .readOnly }}
              {{- end }}
            {{- end }}
            {{- end }}

      volumes:
        - name: {{ .Release.Name }}-config
          persistentVolumeClaim:
            claimName: {{ .Release.Name }}-pvc
        {{- if .Values.volumes }}
        {{- range .Values.volumes }}
        - name: {{ .name }}
          {{- if .persistentVolumeClaim }}
          persistentVolumeClaim:
            claimName: {{ .persistentVolumeClaim.claimName }}
          {{- end }}
          {{- if .nfs }}
          nfs:
            server: {{ .nfs.server }}
            path: {{ .nfs.path }}
          {{- end }}
        {{- end }}
        {{- end }}

      dnsPolicy: ClusterFirst
      hostname: {{ .Values.hostname }}
      restartPolicy: Always
      schedulerName: default-scheduler
      securityContext: {}
      terminationGracePeriodSeconds: {{ .Values.terminationGracePeriod }}
{{- end }}
