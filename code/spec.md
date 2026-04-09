
# **openfuyao-system-controller** 的完整规格说明
## openfuyao-system-controller 规格说明
### 一、组件定位
**openfuyao-system-controller** 是openFuyao平台的系统控制器，负责在**管理集群**上部署和管理openFuyao管理面基础设施组件。

**核心特征**：
- **部署目标**：管理集群（Management Cluster）
- **运行模式**：Deployment + InitContainer
- **主要功能**：安装、升级、维护openFuyao管理面组件
- **命名空间**：`openfuyao-system-controller`
### 二、架构设计
```
┌─────────────────────────────────────────────────────────────────────────────┐
│                   openfuyao-system-controller                                │
│                                                                              │
│  ┌────────────────────────────────────────────────────────────────────┐   │
│  │                      Controller Layer                                │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐            │   │
│  │  │ System       │  │ Component    │  │ Config       │            │   │
│  │  │ Controller   │  │ Controller   │  │ Controller   │   │
│  │  └──────────────┘  └──────────────┘  └──────────────┘            │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐            │   │
│  │  │ Health       │  │ Upgrade      │  │ Backup       │            │   │
│  │  │ Controller   │  │ Controller   │  │ Controller   │            │   │
│  │  └──────────────┘  └──────────────┘  └──────────────┘            │   │
│  └────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│  ┌────────────────────────────────────────────────────────────────────┐   │
│  │                       CRD Definitions                                │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐            │   │
│  │  │ SystemConfig │  │ Component    │  │ HealthCheck  │            │   │
│  │  │ CRD          │  │ CRD          │  │ CRD          │            │   │
│  │  └──────────────┘  └──────────────┘  └──────────────┘            │   │
│  └────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│  ┌────────────────────────────────────────────────────────────────────┐   │
│  │                    Reconciliation Logic                              │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐            │   │
│  │  │ Desired      │  │ Current      │  │ Reconcile    │            │   │
│  │  │ State        │  │ State        │  │ Actions      │            │   │
│  │  └──────────────┘  └──────────────┘  └──────────────┘            │   │
│  └────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│  ┌────────────────────────────────────────────────────────────────────┐   │
│  │                    Platform Services                                 │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐            │   │
│  │  │ Certificate  │  │ DNS          │  │ Storage      │            │   │
│  │  │ Management   │  │ Management   │  │ Management   │            │   │
│  │  └──────────────┘  └──────────────┘  └──────────────┘            │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐            │   │
│  │  │ RBAC         │  │ Network      │  │ Logging      │            │   │
│  │  │ Management   │  │ Policy       │  │ & Monitoring │            │   │
│  │  └──────────────┘  └──────────────┘  └──────────────┘            │   │
│  └────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
```
### 三、核心功能
#### 3.1 安装流程编排
**位置**：`install.sh` 脚本

**安装组件列表**：
1. **ingress-nginx**：Ingress控制器
2. **metrics-server**：指标服务
3. **kube-prometheus**：监控栈
   - prometheus-operator
   - prometheus
   - alertmanager
   - node-exporter
   - kube-state-metrics
4. **oauth-webhook**：认证Webhook
5. **helm-chart-repository**：Harbor配置
6. **user-manager**：用户管理

**安装流程**：
```bash
install.sh
├── install_installer_service()      # 安装installer-service
├── install_console_service()        # 安装console-service
├── install_kube_prometheus()        # 安装监控栈
├── install_ingress_nginx()          # 安装Ingress控制器
├── install_metrics_server()         # 安装指标服务
└── install_oauth_webhook()          # 安装认证Webhook
```
#### 3.2 资源管理
**资源目录结构**：
```
resource/
├── kube-prometheus/
│   ├── prometheus-prometheus.yaml
│   ├── alertmanager-alertmanager.yaml
│   └── ...
├── ingress-nginx/
│   └── ingress-nginx.yaml
├── metrics-server/
│   └── metrics-server.yaml
├── oauth-webhook/
│   └── oauth-webhook.yaml
└── helm-chart-repository/
    └── harbor-config.yaml
```

#### 3.3 镜像管理

**镜像地址特征**：
- **硬编码格式**：`cr.openfuyao.cn/openfuyao/<component>:<version>`
- **示例**：
  ```yaml
  # prometheus
  image: cr.openfuyao.cn/openfuyao/prometheus/prometheus:v2.52.0
  
  # ingress-nginx
  image: cr.openfuyao.cn/openfuyao/ingress-nginx/controller:v1.9.4
  ```

**镜像仓库替换**：
- 通过 `sed` 命令替换镜像仓库地址
- 支持离线环境部署
### 四、与CAPBKE的集成
#### 4.1 部署触发
**位置**：[ensure_addon_deploy.go:378](file:///d:/code/github/cluster-api-provider-bke/pkg/phaseframe/phases/ensure_addon_deploy.go#L378)
```go
func (e *EnsureAddonDeploy) addonBeforeCreateCustomOperate(addon *confv1beta1.Product) error {
    switch addon.Name {
    case constant.OpenFuyaoSystemController:
        return e.handleOpenFuyaoSystemController()
    // ...
    }
}
```
#### 4.2 部署前准备
**位置**：[ensure_addon_deploy.go:706](file:///d:/code/github/cluster-api-provider-bke/pkg/phaseframe/phases/ensure_addon_deploy.go#L706)

**核心步骤**：
1. **添加控制平面标签**：
```go
func (e *EnsureAddonDeploy) addControlPlaneLabels() error {
    // 为控制平面节点添加标签
    // 用于openfuyao-system组件调度
}
```

2. **下发Patch ConfigMap**：
```go
func (e *EnsureAddonDeploy) distributePatchCM() error {
    // 1. 从管理集群获取patch配置
    patchCM := &corev1.ConfigMap{}
    c.Get(ctx, client.ObjectKey{Namespace: "openfuyao-patch", Name: patchCMKey}, patchCM)
    
    // 2. 确保目标集群存在openfuyao-system-controller命名空间
    nsName := constant.OpenFuyaoSystemController
    clSet.CoreV1().Namespaces().Create(ctx, ns, metav1.CreateOptions{})
    
    // 3. 创建或更新patch configmap
    remoteCM := &corev1.ConfigMap{
        ObjectMeta: metav1.ObjectMeta{
            Name:      "patch-config",
            Namespace: nsName,
        },
        Data: map[string]string{"patch-data": data},
    }
    clSet.CoreV1().ConfigMaps(nsName).Create(ctx, remoteCM, metav1.CreateOptions{})
}
```
#### 4.3 健康检查
**位置**：[health.go:158](file:///d:/code/github/cluster-api-provider-bke/pkg/kube/health.go#L158)
```go
{
    Namespace: "openfuyao-system-controller",
    Prefixes:  []string{"openfuyao-system-controller-"},
}
```
### 五、与bke-manifests的对比
| 维度 | bke-manifests | openfuyao-system-controller |
|------|---------------|----------------------------|
| **定位** | 静态资源仓库 | 安装部署工具 |
| **部署目标** | 工作负载集群 | 管理集群 |
| **核心功能** | 存储Kubernetes部署清单(YAML) | 执行openFuyao管理面的安装/卸载 |
| **运行方式** | Sidecar模式，被动提供文件 | Deployment，主动执行安装脚本 |
| **镜像地址** | Go模板参数化 `{{ .repo }}image:tag` | 硬编码 `cr.openfuyao.cn/openfuyao/...` |
| **组件类型** | 集群基础组件 + 应用组件 | 管理面基础设施组件 |
| **版本管理** | 多版本并存 (v1.21, v1.23, v1.25...) | 单一版本 |
| **使用方式** | 被cluster-api-provider-bke读取渲染 | 被install.sh脚本直接kubectl apply |

### 六、部署架构
```
┌──────────────────────────────────────────────────────────────────┐
│                        管理集群                                  │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌─────────────────────────────────┐                             │
│  │  openfuyao-system-controller    │                             │
│  │  (安装器)                       │                             │
│  │  - 安装 installer-service       │                             │
│  │  - 安装 console-service         │                             │
│  │  - 安装 console-website         │                             │
│  │  - 安装 monitoring-service      │                             │
│  │  - 安装 kube-prometheus         │                             │
│  └─────────────────────────────────┘                             │
│                                                                  │
│  ┌─────────────────────────────────┐                             │
│  │  cluster-api-provider-bke       │◄─── bke-manifests (sidecar) │
│  │  (集群生命周期管理)             │      提供addon部署清单      │
│  └─────────────────────────────────┘                             │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
                              │
                              │ 创建工作负载集群
                              ▼
┌──────────────────────────────────────────────────────────────────┐
│                     工作负载集群                                 │
├──────────────────────────────────────────────────────────────────┤
│  部署的组件 (来自bke-manifests):                                 │
│  - calico                                                        │
│  - coredns                                                       │
│  - kube-proxy                                                    │
│  - ...                                                           │
└──────────────────────────────────────────────────────────────────┘
```
### 七、关键配置
#### 7.1 常量定义
**位置**：[constants.go:269-270](file:///d:/code/github/cluster-api-provider-bke/utils/capbke/constant/constants.go#L269-L270)
```go
const (
    // OpenFuyaoSystemPort defines the port of openfuyao system
    OpenFuyaoSystemPort = "31616"
    
    // OpenFuyaoSystemController defines the controller name of openfuyao system
    OpenFuyaoSystemController = "openfuyao-system-controller"
)
```
#### 7.2 Patch配置
**ConfigMap结构**：
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: patch-config
  namespace: openfuyao-system-controller
data:
  patch-data: |
    # 版本特定的配置补丁
    # 用于定制化部署
```
### 八、生命周期管理
#### 8.1 安装阶段
**阶段名称**：`EnsureAddonDeployName`

**执行顺序**：
1. 前置操作：`handleOpenFuyaoSystemController()`
   - 添加控制平面标签
   - 下发Patch ConfigMap
2. 部署Addon：应用YAML清单
3. 后置操作：健康检查
#### 8.2 升级阶段
**阶段名称**：`EnsureComponentUpgradeName`

**升级流程**：
1. 检查当前版本
2. 下载新版本资源
3. 应用更新
4. 验证升级结果
#### 8.3 删除阶段
**阶段名称**：`EnsureDeleteOrResetName`

**删除流程**：
1. 清理管理面组件
2. 删除命名空间
3. 清理残留资源
### 九、监控与运维
#### 9.1 健康状态
**监控指标**：
- Pod运行状态
- 服务可用性
- 资源使用率
- 组件版本
#### 9.2 日志管理
**日志级别**：
- Info：正常操作日志
- Warning：警告信息
- Error：错误信息
- Debug：调试信息
#### 9.3 故障排查
**常见问题**：
1. 镜像拉取失败
   - 检查镜像仓库地址
   - 验证网络连通性
2. 安装超时
   - 检查资源配额
   - 验证节点状态
3. 组件冲突
   - 检查已有组件
   - 验证版本兼容性
### 十、总结
**openfuyao-system-controller** 是openFuyao平台的核心基础设施组件，承担着管理面部署和维护的重要职责。它通过标准化的安装流程和配置管理，确保openFuyao管理面组件的可靠部署和运行。

**核心价值**：
1. **标准化部署**：提供一致的安装体验
2. **版本管理**：支持版本升级和回滚
3. **配置管理**：集中管理配置信息
4. **运维友好**：提供完善的监控和日志

**与bke-manifests的关系**：
- **bke-manifests**：材料库，提供工作负载集群的部署清单
- **openfuyao-system-controller**：安装工，负责管理面的部署和维护

两者协同工作，共同构建了完整的openFuyao集群管理平台。
        
