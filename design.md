


          
让我先搜索项目中关于 openfuyao-system-controller 的相关代码和文档。
        
            
toolName: search_codebase
            
status: success
          
query: openfuyao-system-controller implementation, architecture and design
          

        
            
toolName: file_search
            
status: success
          
          

        
            
toolName: view_folder
            
status: success
          
d:\code\github\openfuyao-system-controller
          

        
            
toolName: view_files
            
status: success
          
            
filePath: d:\code\github\openfuyao-system-controller\entrypoint.sh
          

        
            
toolName: view_files
            
status: success
          
            
filePath: d:\code\github\openfuyao-system-controller\install.sh
          

        
            
toolName: view_files
            
status: success
          
            
filePath: d:\code\github\openfuyao-system-controller\consts.sh
          

        
            
toolName: view_files
            
status: success
          
            
filePath: d:\code\github\openfuyao-system-controller\preinstall.sh
          

        
            
toolName: view_files
            
status: success
          
            
filePath: d:\code\github\openfuyao-system-controller\uninstall.sh
          
基于代码分析，我为您提供 openfuyao-system-controller 的详细设计文档。

---

# openfuyao-system-controller 详细设计说明书

## 1. 概述

### 1.1 项目定位

openfuyao-system-controller 是 openFuyao 平台的管理面部署控制器，用于在 Kubernetes 集群上快速部署和卸载 openFuyao 管理面组件。

### 1.2 核心功能

| 功能 | 说明 |
|------|------|
| 管理面部署 | 一键部署 openFuyao 管理面所有组件 |
| 管理面卸载 | 一键卸载 openFuyao 管理面所有组件 |
| 组件编排 | 按依赖关系有序部署各组件 |
| 证书管理 | 自动生成和管理服务证书 |
| 镜像管理 | 支持在线/离线镜像仓库配置 |

---

## 2. 架构设计

### 2.1 整体架构

```
┌─────────────────────────────────────────────────────────────────────┐
│                     Kubernetes Cluster (管理集群)                    │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │            openfuyao-system-controller Namespace             │   │
│  │  ┌────────────────────────────────────────────────────────┐  │   │
│  │  │                 Deployment (initContainer)              │  │   │
│  │  │  ┌──────────────────────────────────────────────────┐  │  │   │
│  │  │  │              Installer Container                  │  │  │   │
│  │  │  │  ┌────────────────────────────────────────────┐  │  │  │   │
│  │  │  │  │  entrypoint.sh                             │  │  │  │   │
│  │  │  │  │    ├── install.sh (安装)                   │  │  │  │   │
│  │  │  │  │    └── uninstall.sh (卸载)                 │  │  │  │   │
│  │  │  │  └────────────────────────────────────────────┘  │  │  │   │
│  │  │  └──────────────────────────────────────────────────┘  │  │   │
│  │  └────────────────────────────────────────────────────────┘  │   │
│  └──────────────────────────────────────────────────────────────┘   │
│                              │                                       │
│                              │ Helm/kubectl                         │
│                              ▼                                       │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │                   openfuyao-system Namespace                  │   │
│  │  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐             │   │
│  │  │oauth-server │ │console-svc  │ │monitoring   │ ...         │   │
│  │  └─────────────┘ └─────────────┘ └─────────────┘             │   │
│  └──────────────────────────────────────────────────────────────┘   │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │                     monitoring Namespace                      │   │
│  │  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐             │   │
│  │  │ prometheus  │ │alertmanager │ │node-exporter│ ...         │   │
│  │  └─────────────┘ └─────────────┘ └─────────────┘             │   │
│  └──────────────────────────────────────────────────────────────┘   │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │                    ingress-nginx Namespace                    │   │
│  │  ┌─────────────────────────────────────────────────────────┐ │   │
│  │  │              ingress-nginx-controller                   │ │   │
│  │  └─────────────────────────────────────────────────────────┘ │   │
│  └──────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
```

### 2.2 组件依赖关系

```
┌─────────────────────────────────────────────────────────────────────┐
│                         安装顺序（从下到上）                          │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│    ┌──────────────────────────────────────────────────────────┐     │
│    │           应用层                     │     │
│    │  installer-website  │  installer-service                  │     │
│    └──────────────────────────────────────────────────────────┘     │
│                              ▲                                       │
│    ┌──────────────────────────────────────────────────────────┐     │
│    │           业务层                       │     │
│    │  console-website │ console-service │ marketplace-service │     │
│    │  application-management │ plugin-management │ web-terminal│    │
│    └──────────────────────────────────────────────────────────┘     │
│                              ▲                                       │
│    ┌──────────────────────────────────────────────────────────┐     │
│    │           监控层                      │     │
│    │  monitoring-service │ kube-prometheus │ metrics-server   │     │
│    └──────────────────────────────────────────────────────────┘     │
│                              ▲                                       │
│    ┌──────────────────────────────────────────────────────────┐     │
│    │           认证层                     │     │
│    │  oauth-server │ oauth-webhook │ user-management-operator │     │
│    └──────────────────────────────────────────────────────────┘     │
│                              ▲                                       │
│    ┌──────────────────────────────────────────────────────────┐     │
│    │           基础设施层                │     │
│    │  ingress-nginx │ local-harbor │ cert-manager             │     │
│    └──────────────────────────────────────────────────────────┘     │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 3. 核心组件设计

### 3.1 组件清单

| 组件 | 命名空间 | 类型 | 说明 |
|------|----------|------|------|
| ingress-nginx | ingress-nginx | DaemonSet | Ingress 控制器 |
| metrics-server | kube-system | Deployment | 资源监控 |
| kube-prometheus | monitoring | 多资源 | 监控栈 |
| local-harbor | openfuyao-system | Helm | 本地镜像仓库 |
| oauth-server | openfuyao-system | Helm | OAuth 认证服务 |
| oauth-webhook | openfuyao-system | Helm | OAuth Webhook |
| console-service | openfuyao-system | Helm | 控制台服务 |
| console-website | openfuyao-system | Helm | 控制台前端 |
| monitoring-service | openfuyao-system | Helm | 监控服务 |
| marketplace-service | openfuyao-system | Helm | 应用市场服务 |
| application-management | openfuyao-system | Helm | 应用管理服务 |
| plugin-management | openfuyao-system | Helm | 插件管理服务 |
| user-management-operator | openfuyao-system | Helm | 用户管理 Operator |
| web-terminal-service | openfuyao-system | Helm | Web 终端服务 |
| installer-website | openfuyao-system | Helm | 安装向导前端 |
| installer-service | openfuyao-system | Helm | 安装向导服务 |

### 3.2 组件配置常量

```bash
# 命名空间
OPENFUYAO_SYSTEM_NAMESPACE="openfuyao-system"
OPENFUYAO_SYSTEM_CONTROLLER_NAMESPACE="openfuyao-system-controller"
INGRESS_NGINX_NAMESPACE="ingress-nginx"
MONITOR_NAMESPACE="monitoring"

# 镜像仓库
FUYAO_REPO="oci://cr.openfuyao.cn/charts"
FUYAO_RGISTRY="cr.openfuyao.cn/openfuyao"

# 服务地址
LOCAL_HARBOR_HOST="https://local-harbor.openfuyao-system.svc.cluster.local"
OAUTH_SERVER_HOST="https://oauth-server.openfuyao-system.svc.cluster.local:9096"
CONSOLE_SERVICE_HOST="https://console-service.openfuyao-system.svc.cluster.local:443"
MONITORING_HOST="https://monitoring-service.openfuyao-system.svc.cluster.local:443"
```

---

## 4. 部署流程设计

### 4.1 安装流程

```
┌─────────────────────────────────────────────────────────────────────┐
│                         安装流程                                     │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  1. 环境检查                                                         │
│     ├── 检查 kubectl 可用性                                          │
│     ├── 检查 helm 可用性                                             │
│     └── 检查集群状态                                                 │
│                                                                      │
│  2. 基础设施层安装                                                   │
│     ├── install_ingress_nginx()      # Ingress 控制器               │
│     └── install_helm_chart_repository() # 本地 Harbor               │
│                                                                      │
│  3. 认证层安装                                                       │
│     ├── install_oauth_webhook()      # OAuth Webhook                │
│     ├── install_oauth_server()       # OAuth Server                 │
│     └── install_user_management_operator() # 用户管理               │
│                                                                      │
│  4. 监控层安装                                                       │
│     ├── install_metrics_server()     # Metrics Server               │
│     ├── install_kube_prometheus()    # Prometheus 栈                │
│     └── install_monitoring_service() # 监控服务                     │
│                                                                      │
│  5. 业务层安装                                                       │
│     ├── install_console_service()    # 控制台服务                   │
│     ├── install_console_website()    # 控制台前端                   │
│     ├── install_marketplace_service() # 应用市场                    │
│     ├── install_application_management_service() # 应用管理         │
│     ├── install_plugin_management_service() # 插件管理              │
│     └── install_web_terminal_service() # Web 终端                   │
│                                                                      │
│  6. 应用层安装                                                       │
│     ├── install_installer_website()  # 安装向导前端                 │
│     └── install_installer_service()  # 安装向导服务                 │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### 4.2 卸载流程

```
┌─────────────────────────────────────────────────────────────────────┐
│                         卸载流程（逆序）                             │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  1. 应用层卸载                                                       │
│     ├── uninstall_installer_website()                               │
│     └── uninstall_installer_service()                               │
│                                                                      │
│  2. 业务层卸载                                                       │
│     ├── uninstall_web_terminal_service()                            │
│     ├── uninstall_plugin_management_service()                       │
│     ├── uninstall_application_management_service()                  │
│     ├── uninstall_marketplace_service()                             │
│     ├── uninstall_console_website()                                 │
│     └── uninstall_console_service()                                 │
│                                                                      │
│  3. 监控层卸载                                                       │
│     ├── uninstall_monitoring_service()                              │
│     ├── uninstall_kube_prometheus()                                 │
│     └── uninstall_metrics_server()                                  │
│                                                                      │
│  4. 认证层卸载                                                       │
│     ├── uninstall_user_management_operator()                        │
│     └── uninstall_oauth_webhook_and_oauth_server()                  │
│                                                                      │
│  5. 基础设施层卸载                                                   │
│     ├── uninstall_helm_chart_repository()                           │
│     └── uninstall_ingress_nginx()                                   │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 5. 核心模块设计

### 5.1 入口模块

```bash
#!/bin/bash
# 安装执行路径
BASE_INSTALL_EXEC_DIR="/opt"
SUB_EXEC_DIR="openFuyao/openfuyao-system-install"
INSTALL_EXEC_DIR="$BASE_INSTALL_EXEC_DIR/$SUB_EXEC_DIR"

# 拷贝脚本文件到宿主机
function copy_to_host() {
    info_log "copy install files to host"
    nsenter -i/proc/1/ns/ipc -m/proc/1/ns/mnt -n/proc/1/ns/net \
        mkdir -p "${INSTALL_EXEC_DIR}"
    cp -rf /home/openfuyao-system/* /mnt/opt/${SUB_EXEC_DIR}
}

# 安装 openfuyao-system
function install_openfuyao_system() {
    info_log "start install openfuyao-system"
    copy_to_host

    nsenter -i/proc/1/ns/ipc -m/proc/1/ns/mnt -n/proc/1/ns/net \
        bash -c "cd ${INSTALL_EXEC_DIR} && ./install.sh \
            -r ${OPENFUYAO_REGISTRY} \
            --enableHttps=${ENABLE_HTTPS} \
            --repo=${HELM_REPORITORY_URL} \
            --harborAdminPassword=${HARBOR_ADMIN_PASSWORD} \
            ..."

    remove_tmp_files
}

# 卸载 openfuyao-system
function uninstall_openfuyao_system() {
    info_log "start uninstall openfuyao-system"
    copy_to_host

    nsenter -i/proc/1/ns/ipc -m/proc/1/ns/mnt -n/proc/1/ns/net \
        bash -c "cd ${INSTALL_EXEC_DIR} && ./uninstall.sh -r ${OPENFUYAO_REGISTRY}"

    remove_tmp_files
}
```

### 5.2 Helm Chart 下载模块

```bash
function download_charts_with_retry() {
    local chart_name=$1
    local chart_version=$2

    if [ ! -d "${CHART_PATH}" ]; then
        mkdir -p "${CHART_PATH}"
    fi

    local cur_path=$(pwd)
    cd "${CHART_PATH}"

    if [ -f "${chart_name}-${chart_version}.tgz" ]; then
        info_log "${chart_name}-${chart_version}.tgz already exists, skip downloading"
        cd "${cur_path}"
        return
    fi

    info_log "Downloading ${chart_name} chart"

    local attempts=0
    while [ $attempts -lt 3 ]; do
        if [ "$IS_ONLINE" = "false" ]; then
            helm fetch "${chart_name}" --repo "${OPENFUYAO_REPO}" --version "${chart_version}"
        else
            helm fetch "${FUYAO_REPO}/${chart_name}" --version "${chart_version}"
        fi
        if [ $? -eq 0 ]; then
            info_log "Successfully downloaded ${chart_name} chart"
            break
        else
            ((attempts++))
            sleep 2
        fi
    done

    if [ $attempts -eq 3 ]; then
        fatal_log "Failed to download $chart_name after 3 attempts."
    fi

    cd "${cur_path}"
}
```

### 5.3 证书管理模块

```bash
function create_service_cert() {
    local service_name=$1
    local common_name=$2
    shift 2
    local sans=("$@")

    info_log "Creating certificate for ${service_name}"

    local cert_dir="${FUYAO_CERTS_PATH}/${service_name}"
    mkdir -p "${cert_dir}"

    # 生成私钥
    openssl genrsa -out "${cert_dir}/${service_name}.key" 2048

    # 创建 CSR 配置
    cat > "${cert_dir}/csr.conf" <<EOF
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name

[req_distinguished_name]

[v3_req]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names

[alt_names]
EOF

    local i=1
    for san in "${sans[@]}"; do
        echo "DNS.${i} = ${san}" >> "${cert_dir}/csr.conf"
        ((i++))
    done

    # 生成证书
    openssl req -new -key "${cert_dir}/${service_name}.key" \
        -out "${cert_dir}/${service_name}.csr" \
        -subj "/CN=${common_name}" \
        -config "${cert_dir}/csr.conf"

    openssl x509 -req -in "${cert_dir}/${service_name}.csr" \
        -CA "${FUYAO_CERTS_PATH}/ca.crt" \
        -CAkey "${FUYAO_CERTS_PATH}/ca.key" \
        -CAcreateserial \
        -out "${cert_dir}/${service_name}.crt" \
        -days 3650 \
        -extensions v3_req \
        -extfile "${cert_dir}/csr.conf"
}
```

### 5.4 组件安装模块示例

```bash
function install_console_service() {
    # 检查是否已安装
    if [ -n "${CONSOLE_SERVICE_INSTALLED}" ]; then
        info_log "console_service has been installed, skip installation"
        return
    fi

    info_log "Start installing console_service"

    # 创建命名空间
    create_namespace "${SESSION_SECRET_NAMESPACE}"

    # 检查依赖
    is_ingress_nginx_running
    if [ $? -eq 0 ]; then
        info_log "ingress nginx pod status is normal, go on."
    else
        fatal_log "ingress nginx pod status is abnormal"
    fi

    # 等待 DNS 就绪
    kubectl wait -n kube-system --for=condition=ready pod -l k8s-app=kube-dns

    # 下载 Chart
    download_charts_with_retry "${CONSOLE_SERVICE_CHART_NAME}" "${CONSOLE_SERVICE_CHART_VERSION}"

    # 根据配置选择安装方式
    if [ "${ENABLE_HTTPS}" == "true" ]; then
        create_service_cert "${CONSOLE_SERVICE}" "${CONSOLE_SERVICE}" \
            "${CONSOLE_SERVICE}.${OPENFUYAO_SYSTEM_NAMESPACE}" \
            "${CONSOLE_SERVICE}.${OPENFUYAO_SYSTEM_NAMESPACE}.${DNS_3_SUFFIX}" \
            "${CONSOLE_SERVICE}.${OPENFUYAO_SYSTEM_NAMESPACE}.${DNS_4_SUFFIX}"
        install_console_service_enable_https
    else
        install_console_service_disable_https
    fi

    info_log "Completing the installation of console-service"
}

function install_console_service_enable_https() {
    local chart_path="./${CHART_PATH}/${CONSOLE_SERVICE_CHART_NAME}-${CONSOLE_SERVICE_CHART_VERSION}.tgz"

    helm install "${CONSOLE_SERVICE_RELEASE_NAME}" "${chart_path}" \
        -n "${OPENFUYAO_SYSTEM_NAMESPACE}" \
        --set ingress.secretName="${INGRESS_NGINX_NAMESPACE}/${INGRESS_NGINX_TLS_SECRET}" \
        --set images.core.repository="${REGISTRY}"/console-service \
        --set images.core.tag="${CONSOLE_SERVICE_IMAGE_TAG}" \
        --set symmetricKey.tokenKey="$(openssl rand -base64 32)" \
        --set symmetricKey.secretKey="$(openssl rand -base64 32)" \
        --set config.enableHttps=true \
        --set serverHost.localHarbor="${LOCAL_HARBOR_HOST}" \
        --set serverHost.oauthServer="${OAUTH_SERVER_HOST}" \
        --set-file config.tlsCert="./${FUYAO_CERTS_PATH}/${CONSOLE_SERVICE}/${CONSOLE_SERVICE}.crt" \
        --set-file config.tlsKey="./${FUYAO_CERTS_PATH}/${CONSOLE_SERVICE}/${CONSOLE_SERVICE}.key" \
        --set-file config.rootCA="./${FUYAO_CERTS_PATH}/ca.crt"
}
```

---

## 6. 部署配置

### 6.1 Kubernetes Deployment 配置

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: openfuyao-system-controller
  namespace: openfuyao-system-controller
spec:
  replicas: 1
  selector:
    matchLabels:
      app: openfuyao-system-controller
  template:
    metadata:
      labels:
        app: openfuyao-system-controller
    spec:
      # 节点亲和性：优先调度到控制平面节点
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
              - matchExpressions:
                  - key: kubernetes.io/os
                    operator: In
                    values:
                      - linux
          preferredDuringSchedulingIgnoredDuringExecution:
            - weight: 10
              preference:
                matchExpressions:
                  - key: node-role.kubernetes.io/master
                    operator: Exists
            - weight: 20
              preference:
                matchExpressions:
                  - key: node-role.kubernetes.io/control-plane
                    operator: Exists

      # 容忍控制平面污点
      tolerations:
        - key: "node-role.kubernetes.io/master"
          effect: "NoSchedule"
        - key: "node-role.kubernetes.io/control-plane"
          effect: "NoSchedule"

      # 使用宿主机网络和 PID 命名空间
      hostNetwork: true
      hostPID: true

      initContainers:
        - name: installer
          image: {{ .repo }}openfuyao-system-controller:{{ .tagVersion }}
          imagePullPolicy: IfNotPresent
          securityContext:
            privileged: true
          env:
            - name: NODE_NAME
              valueFrom:
                fieldRef:
                  fieldPath: spec.nodeName
            - name: OPENFUYAO_REGISTRY
              value: "{{ .repo }}"
            - name: ENABLE_HTTPS
              value: "true"
            - name: HELM_REPORITORY_URL
              value: "{{ .helmRepo }}"
            - name: HARBOR_ADMIN_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: harbor-credentials
                  key: HARBOR_ADMIN_PASSWORD
          command:
            - /bin/sh
            - -c
            - sh /home/openfuyao-system/entrypoint.sh -o install
          volumeMounts:
            - name: dev
              mountPath: /dev
            - name: host-time
              mountPath: /etc/localtime
              readOnly: true
            - name: root-mount
              mountPath: /mnt

      containers:
        - name: openfuyao-system-controller
          image: {{ .repo }}openfuyao-system-controller:{{ .tagVersion }}
          imagePullPolicy: IfNotPresent
          securityContext:
            privileged: true
          command:
            - /bin/sh
            - -c
            - while true; do sleep 3600; done
          volumeMounts:
            - name: dev
              mountPath: /dev
            - name: host-time
              mountPath: /etc/localtime
              readOnly: true
            - name: root-mount
              mountPath: /mnt

      volumes:
        - name: dev
          hostPath:
            path: /dev
        - name: host-time
          hostPath:
            path: /etc/localtime
        - name: root-mount
          hostPath:
            path: /
```

### 6.2 环境变量配置

| 环境变量 | 说明 | 默认值 |
|----------|------|--------|
| NODE_NAME | 节点名称 | 从 Downward API 获取 |
| OPENFUYAO_REGISTRY | 镜像仓库地址 | - |
| ENABLE_HTTPS | 是否启用 HTTPS | true |
| HELM_REPORITORY_URL | Helm 仓库地址 | - |
| OAUTH_CERTS_EXPIRATION_TIME | OAuth 证书有效期 | 876000h |
| HARBOR_ADMIN_PASSWORD | Harbor 管理员密码 | - |
| HARBOR_DATABASE_PASSWORD | Harbor 数据库密码 | - |
| HARBOR_REGISTRY_PASSWORD | Harbor 仓库密码 | - |
| HARBOR_REGISTRY_PV_SIZE | Harbor Registry PV 大小 | 10Gi |

---

## 7. 安装状态检查

### 7.1 预检查模块

```bash
function check_installation_status() {
    # 检查 console-service
    if kubectl get pod -n "${OPENFUYAO_SYSTEM_NAMESPACE}" | grep -q "${CONSOLE_SERVICE}"; then
        info_log "${CONSOLE_SERVICE} has been installed"
        CONSOLE_SERVICE_INSTALLED="true"
    fi

    # 检查 console-website
    if kubectl get pod -n "${OPENFUYAO_SYSTEM_NAMESPACE}" | grep -q "${CONSOLE_WEBSITE}"; then
        info_log "${CONSOLE_WEBSITE} has been installed"
        CONSOLE_WEBSITE_INSTALLED="true"
    fi

    # 检查 monitoring-service
    if kubectl get pod -n "${OPENFUYAO_SYSTEM_NAMESPACE}" | grep -q "${MONITORING_SERVICE}"; then
        info_log "${MONITORING_SERVICE} has been installed"
        MONITORING_SERVICE_INSTALLED="true"
    fi

    # ... 其他组件检查
}
```

### 7.2 依赖检查

```bash
function is_ingress_nginx_running() {
    local namespace="${INGRESS_NGINX_NAMESPACE}"
    local deployment="${INGRESS_NGINX_CONTROLLER}"

    if ! kubectl get deployment -n "${namespace}" "${deployment}" &>/dev/null; then
        error_log "ingress-nginx-controller deployment not found"
        return 1
    fi

    local ready_replicas
    ready_replicas=$(kubectl get deployment -n "${namespace}" "${deployment}" \
        -o jsonpath='{.status.readyReplicas}')

    local desired_replicas
    desired_replicas=$(kubectl get deployment -n "${namespace}" "${deployment}" \
        -o jsonpath='{.spec.replicas}')

    if [ "${ready_replicas}" == "${desired_replicas}" ]; then
        return 0
    else
        return 1
    fi
}
```

---

## 8. Harbor 本地仓库部署

### 8.1 PV 配置

```yaml
# harbor-local-pv.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: harbor-registry-pv
  labels:
    app: harbor
    component: registry
spec:
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: local-storage
  local:
    path: /data/harbor/registry
  nodeAffinity:
    required:
      nodeSelectorTerms:
        - matchExpressions:
            - key: fuyao-harbor-local-install-node
              operator: Exists
```

### 8.2 Harbor 安装

```bash
function install_helm_chart_repository() {
    if [ -n "${LOCAL_HARBOR_INSTALLED}" ]; then
        info_log "local_harbor has been installed, skip installation"
        return
    fi

    info_log "Start installing local_harbor"

    # 获取控制平面节点
    local node_name=$(kubectl get nodes -l node-role.kubernetes.io/control-plane \
        -o jsonpath='{.items[0].metadata.name}')

    # 标记节点
    kubectl label nodes "$node_name" "${LABEL_KEY}"="${node_name}"

    # 创建数据目录
    create_harbor_data_directories "$node_name"

    # 创建 PV
    kubectl apply -f ./resource/helm-chart-repository/harbor-local-pv.yaml

    # 下载 Chart
    download_charts_with_retry "${HARBOR_CHART_NAME}" "${HARBOR_CHART_VERSION}"

    # 安装 Harbor
    helm install "${HARBOR_RELEASE_NAME}" \
        "./${CHART_PATH}/${HARBOR_CHART_NAME}-${HARBOR_CHART_VERSION}.tgz" \
        -n "${OPENFUYAO_SYSTEM_NAMESPACE}" \
        -f ./resource/helm-chart-repository/harbor-local-values.yaml \
        --set persistence.persistentVolumeClaim.registry.size=${HARBOR_REGISTRY_PVC_SIZE} \
        --set persistence.persistentVolumeClaim.database.size=${HARBOR_DATABASE_PVC_SIZE} \
        --set harborAdminPassword=${HARBOR_ADMIN_PASSWORD}

    info_log "Completing the installation of local-harbor"
}
```

---

## 9. 监控栈部署

### 9.1 kube-prometheus 组件

```bash
function install_kube_prometheus() {
    if [ -n "${KUBE_PROMETHEUS_INSTALLED}" ]; then
        info_log "kube_prometheus has been installed, skip installation"
        return
    fi

    info_log "Start installing kube_prometheus"

    # 创建命名空间
    create_namespace "${MONITOR_NAMESPACE}"

    # 获取控制平面节点
    control_plane_nodes=$(kubectl get nodes -l node-role.kubernetes.io/control-plane \
        -o custom-columns='NAME:.metadata.name' | awk 'NR > 1')

    # 创建 etcd 证书 Secret
    create_etcd_certs_secret

    # 部署 Kubernetes 组件服务
    kubectl apply -f ./resource/kube-prometheus/kubernetes-components-service/

    # 更新镜像标签
    update_prometheus_image_tags

    # 部署 CRD
    kubectl apply --server-side -f ./resource/kube-prometheus/setup
    kubectl wait --for condition=Established --all CustomResourceDefinition \
        --namespace="${MONITOR_NAMESPACE}"

    # 部署监控组件
    kubectl apply -f ./resource/kube-prometheus/

    info_log "Completing the installation of kube-prometheus"
}
```

### 9.2 etcd 证书处理

```bash
function create_etcd_certs_secret() {
    local pki_path=$(kubectl describe cm kubeadm-config -n kube-system \
        | grep certificatesDir | awk '{print $2}')

    if [ -z "$pki_path" ]; then
        pki_path="/etc/kubernetes/pki"
    fi

    if [ -d "${pki_path}/etcd" ]; then
        kubectl create secret generic etcd-certs \
            --from-file=ca.crt=${pki_path}/etcd/ca.crt \
            --from-file=etcd.crt=${pki_path}/etcd/peer.crt \
            --from-file=etcd.key=${pki_path}/etcd/peer.key \
            --namespace="${MONITOR_NAMESPACE}"
    else
        # 使用 Job 在节点上创建 Secret
        create_etcd_certs_secret_job
    fi
}
```

---

## 10. 安全设计

### 10.1 敏感信息管理

```yaml
# Harbor 凭证 Secret
apiVersion: v1
kind: Secret
metadata:
  name: harbor-credentials
  namespace: openfuyao-system-controller
type: Opaque
data:
  HARBOR_ADMIN_PASSWORD:    SGFyYm9yQDEyMzQ1
  HARBOR_DATABASE_PASSWORD: ZGJSb290MTIzNDU=
  HARBOR_REGISTRY_PASSWORD: cmVnUm9vdDEyMzQ1
```

### 10.2 权限控制

```yaml
# initContainer 需要 privileged 权限
securityContext:
  privileged: true

# 需要访问宿主机资源
volumeMounts:
  - name: dev
    mountPath: /dev
  - name: root-mount
    mountPath: /mnt
```

---

## 11. 错误处理

### 11.1 日志模块

```bash
function _log() {
    local prefix="$1"
    shift
    echo "$(date +"[%Y-%m-%d %H:%M:%S,%N]") [${prefix}] $*"
}

function info_log() {
    _log "INFO" "$*"
}

function warning_log() {
    _log "WARNING" "$*"
}

function error_log() {
    _log "ERROR" "$*"
}

function fatal_log() {
    _log "FATAL" "$*"
    exit 1
}
```

### 11.2 重试机制

```bash
function wait_for_deployment() {
    local namespace=$1
    local deployment=$2
    local timeout=${3:-300}

    info_log "Waiting for deployment ${deployment} in ${namespace}"

    local start_time=$(date +%s)
    while true; do
        local current_time=$(date +%s)
        local elapsed=$((current_time - start_time))

        if [ $elapsed -ge $timeout ]; then
            fatal_log "Timeout waiting for deployment ${deployment}"
        fi

        local ready_replicas
        ready_replicas=$(kubectl get deployment -n "${namespace}" "${deployment}" \
            -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")

        local desired_replicas
        desired_replicas=$(kubectl get deployment -n "${namespace}" "${deployment}" \
            -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "1")

        if [ "${ready_replicas}" == "${desired_replicas}" ] && [ "${ready_replicas}" != "0" ]; then
            info_log "Deployment ${deployment} is ready"
            return 0
        fi

        sleep 5
    done
}
```
## 12. 总结
openfuyao-system-controller 是 openFuyao 平台的核心部署工具，具有以下特点：

| 特点 | 说明 |
|------|------|
| 一键部署 | 通过 initContainer 自动完成所有组件的安装 |
| 分层架构 | 按依赖关系分层部署，确保组件启动顺序 |
| 幂等性 | 支持重复执行，已安装组件自动跳过 |
| 灵活配置 | 支持在线/离线部署，支持 HTTPS/HTTP 切换 |
| 完整卸载 | 提供完整的卸载流程，清理所有资源 |
| 错误恢复 | 完善的日志和错误处理机制 |
        
