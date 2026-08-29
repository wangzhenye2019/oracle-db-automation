# 设计说明

## 执行模型

部署入口由 `playbooks/deploy_single_instance.yml` 提供。它先加载用户变量，要求非 dry-run 执行显式确认，然后依次执行前置检查、OS 基线、Oracle 软件安装、数据库初始化和部署后验证。每个阶段使用独立 role，便于按需复用和后续扩展 RAC、Data Guard 等拓扑。

## 幂等与回滚边界

软件安装以 `ORACLE_HOME/bin/sqlplus` 和安装标记为幂等判断；数据库创建以数据文件存在为幂等判断；OS 文件、目录、systemd 和监听器配置由 Ansible 管理。项目不会在失败时自动删除 Oracle Home 或数据库，因为数据库删除属于不可逆高风险操作。失败后应先保存 Ansible 输出和 Oracle installer/DBCA 日志，再依据实际阶段人工修复或重建目标机。

## 凭据边界

DBCA response file 在目标机 `/tmp` 下以 0600 创建，任务使用 `no_log`，完成后立即删除。生产环境应通过 Vault、CI Secret 或企业密码系统注入，而不是提交 `inventory/group_vars/oracle.yml`。仓库只保留 `oracle.example.yml`，真实配置文件已由 `.gitignore` 排除。

## 介质边界

Oracle 安装包必须由用户根据 Oracle 许可从官方渠道取得，并放置在目标机路径或内部制品库。项目不会自动从不受控公网地址下载介质；通过 `oracle_install_media_sha256` 可在解压前执行完整性校验。
