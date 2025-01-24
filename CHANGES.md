# Changelog

#### 0.1.0
- Initial commit of this project for public review and use.
- Includes the baseline resources for any *arr application to run in Kubernetes with Helm Library charts.
    - Also includes examples in the `examples/` folder for:
        - `bazarr`
        - `prowlarr`
        - `radarr`
        - `sonarr`
- Configures `_pvc.tpl` with iSCSI and existing `StorageClass` as a prerequisite. In the future, may re-add the conditional parsing of NFS volume type.