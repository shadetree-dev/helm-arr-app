# *arr app Helm Library Charts

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![Type: library](https://img.shields.io/badge/Type-application-informational?style=flat-square)

# Overview

[Helm Library Charts](https://helm.sh/docs/topics/library_charts/) and examples for *arr application deployment (e.g. Sonarr, Radarr, Bazarr, Prowlarr, etc.). 

This creates a re-usable pattern for deploying multiple *arr applications in Kubernetes clusters. Since they are extremely similar and you may want to create default configurations across them that can be inherited, setting your deployment to depend on a library chart ensures consistent deployment of these applications with easy overrides!

# Prerequisites

The `storageConfig` values are targeted at using iSCSI volumes and assume you have an existing [StorageClass](https://kubernetes.io/docs/concepts/storage/storage-classes/) configured. In general, these applications utilize SQLite databases where NFS storage or other shared media *may* cause locking/corruption issues. Anecdotally, this has never happened to me, but there **has** been a substantial latency improvement in the applications' web UI by utilizing dedicated, iSCSI storage configured for the applications.

The storage configuration is out of the scope of this project, but here is an example of my `synology-iscsi` `StorageClass`.

```yaml
allowVolumeExpansion: true
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  annotations:
    meta.helm.sh/release-name: synology-csi
    meta.helm.sh/release-namespace: synology-csi
    storageclass.kubernetes.io/is-default-class: "false"
  labels:
    app.kubernetes.io/instance: synology-csi
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/name: synology-csi
    app.kubernetes.io/version: v1.2.0
    helm.sh/chart: synology-csi-0.9.3-SNAPSHOT
    helm.sh/template: storageclass.yaml
  name: synology-iscsi
  resourceVersion: "40073548"
  uid: 1ec5bb8b-6268-48b2-a50e-ddbbbe9fb31c
parameters:
  dsm: 192.168.1.50 # Your FQDN or IP for the DSM server
  formatOptions: --nodiscard
  fsType: btrfs # Assumes btrfs filesystem
  location: /volume1 # Set to your appropriate volume path
provisioner: csi.san.synology.com
reclaimPolicy: Retain
volumeBindingMode: Immediate
```

This was configured with the publicly available Synology CSI on GitHub: https://github.com/SynologyOpenSource/synology-csi

There are other ways to provision iSCSI storage natively in Kubernetes by creating a `PersistentVolume` yourself. See these examples in the [OpenShift Documentation](https://docs.openshift.com/container-platform/3.11/install_config/persistent_storage/persistent_storage_iscsi.html) for an idea on how to do this.

If you would like to modify to be able to use other volume types, you can change the `helm/charts/_library-charts/arr-common/templates/_pvc.tpl` and then make sure the `volumes` and `volumeMounts` are correctly configured in the `helm/charts/_library-charts/arr-common/templates_deployment.tpl`.

For this project, we will assume you have a `StorageClass` and CSI able to support `PeristentVolumeClaim` (PVC) mapping dynamically, or have pre-provisioned `PersistentVolumes`(PVs) you will create a PVC for.

# Getting Started

To make use of the Library Charts, you can choose to modify and build them locally as dependencies for your applications. See the `examples/` folder for how you can create an instance of your *arr application!

## Configure `Chart.yaml`

In your `Chart.yaml`, you will want to set your `dependencies` instead of just defining your application and version. This will tell `helm` to then require the defined chart as an upstream dependency, which it cannot build without.

Example:

```yaml
apiVersion: v2
name: bazarr
description: Deploys Bazarr for subtitle management
type: application
version: 0.1.0
appVersion: "0.1.0"
dependencies:
  - name: arr-common
    version: "0.1.0"
    repository: "file://../../helm/charts/_library-charts/arr-common"
    import-values:
      - defaults
```

You can set the chart and application versions to whatever you want based on your own semver of the releases. The `arr-common` dependency version will need to match what is defined in the library chart.

Set the `repository` to the local path, relative to your application / instance of *arr application.

## Configure your `app.yaml` template

Instead of creating the individual templates, like `deployment.yaml` and `service.yaml` in your `templates/` folder, you instead create a single manifest that references the resources you want from your upstream dependency charts.

Example:

```yaml
# bazarr.yaml
{{ include "arr-common.pvc" . }}
---
{{ include "arr-common.deployment" . }}
---
{{ include "arr-common.service" . }}
---
{{ include "arr-common.serviceaccount" . }}
```

This tells the application Helm chart to create an instance of each of these templates from its dependencies. Then, any `values.yaml` you provide should meet the schema needs of these templates and will override the appropriate configuration.

## `values.yaml`

For your `values.yaml` you will want to override the specific values you want. Many defaults are already set in the `arr-common` library, which you can review from the `.tpl` files and `helm/charts/_library-charts/arr-common/values.yaml` from that chart.

Example:

```yaml
replicaCount: 1
terminationGracePeriod: 60

image:
  tag: "latest"

imagePullSecrets: []
nameOverride: ""
fullnameOverride: ""

serviceAccount:
  create: false
  automount: true
  annotations: {}
  name: ""

podSecurityContext: {}

securityContext: {}

service:
  type: LoadBalancer
  externalIPs:
  - '192.168.1.75'
  
ports:
  - name: bazarr-web
    containerPort: 6767
    targetPort: 6767
    protocol: TCP

affinity: {}
nodeSelector: {}

storageConfig:
  storageClassName: synology-iscsi
  reclaimPolicy: Retain
  volumeName: ""
  volumeMode: Filesystem
  volumeSize: 10Gi
  accessModes:
    - ReadWriteOnce
```

## Installation with Helm

You will need to make sure you have gathered all dependency charts, which are defined in your *arr application charts, by running the required Helm commands. This section should help you to build and validate your charts.

### `helm dependency update`

```bash
cd examples/bazarr
helm dependency update
Hang tight while we grab the latest from your chart repositories...
Update Complete. ⎈Happy Helming!⎈
Saving 1 charts
Deleting outdated charts
```

This should create/update your `charts` folder with a new `.tgz` file like `arr-comon-<version>.tgz`. If not, make sure the relative path and versions are correct.

### `helm template`

You should be able to validate your chart and values rendering to valid `YAML` by running the `helm template` command.

```bash
helm template bazarr --namespace media-management --create-namespace ./ -f ./values.yaml
```

The above should output the rendered `YAML` for your resources. If you see errors, it should indicate where you are getting mismatches or incorrectly rendered values. For further details, you can add the `--debug` flag.

## `helm install`

Once you have the dependencies and template validated, you can go ahead and install the application. You can upgrade and/or install with the same command if you run the following:

```bash
helm upgrade --install bazarr --namespace media-management --create-namespace ./ -f ./values.yaml
```

Repeating this process for each application should get you a consistent and viable deployment for each *arr app!

```bash
helm list -n media-management                             ✭ ✱
NAME            NAMESPACE               REVISION        UPDATED                                 STATUS          CHART                   APP VERSION
bazarr          media-management        9               2024-11-18 20:20:05.660835 -0700 MST    deployed        bazarr-0.1.0            0.1.0      
prowlarr        media-management        1               2024-11-06 20:19:46.521202 -0700 MST    deployed        prowlarr-0.1.0          0.1.0      
radarr          media-management        1               2024-11-06 20:19:46.519698 -0700 MST    deployed        radarr-0.1.0            0.1.0      
radarr-comedy   media-management        1               2024-11-06 20:19:46.520798 -0700 MST    deployed        radarr-comedy-0.1.0     0.1.0      
sabnzbd         media-management        4               2024-12-15 21:59:16.958863 -0700 MST    deployed        sabnzbd-0.1.0           0.1.0      
sonarr          media-management        1               2024-11-06 20:19:46.520721 -0700 MST    deployed        sonarr-0.1.0            0.1.0    
```

**Note: In the above you can see that `sabnzbd` is also deployed here. It has very similar configuration with the values differing slightly, such as `env` having the `HAS_IPV6 = false`. You can deploy other common PVR applications with this same Helm Library chart in many situations, but YMMV!**

# License

You are free to do whatever you want with these charts! Please see the `LICENSE.md`, but in general, these projects are simply configuration of existing, open source resources with generalized examples you can draw from for your own configuration. Nothing is proprietary nor sensitive in this project and can be freely shared.