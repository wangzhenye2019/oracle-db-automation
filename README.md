# oracle-db-automation

> Oracle Database deployment, productized with Ansible.

这是一个参考 [fanderchan/dbbot](https://github.com/fanderchan/dbbot) 的 Oracle 数据库自动化部署项目。项目以 Ansible 为执行底座，围绕**可重复、幂等、可审计和安全默认值**组织 Oracle 19c/21c Linux x86_64 单实例部署流程。

## 支持范围

| 能力 | 首版状态 | 说明 |
| --- | --- | --- |
| Oracle 19c / 21c 单实例 | 支持 | 使用用户提供的 Oracle 安装介质，静默安装 |
| Oracle Linux / RHEL / Rocky / AlmaLinux 8/9 | 目标支持 | 需按 Oracle 版本和组织基线验证 |
| 软件安装、监听器、数据库创建 | 支持 | 通过 response file 与 DBCA 静默执行 |
| OS 参数、用户组、目录、limits | 支持 | 仅修改项目明确管理的配置片段 |
| 健康检查 | 支持 | 检查进程、监听端口、SQL*Plus 登录和数据库状态 |
| RAC / Data Guard / 滚动补丁 | 暂不支持 | 保留为后续独立拓扑模块 |
| 自动卸载或生产删除 | 默认禁止 | 需要另行设计并增加人工确认守卫 |

## 目录结构

```text
inventory/                 示例 inventory 与变量模板
playbooks/                 对外执行入口
roles/oracle_precheck/     控制机与目标机前置检查
roles/oracle_os/           Oracle 用户、组、目录、内核和 limits
roles/oracle_install/      Oracle 软件静默安装与 listener
roles/oracle_database/     DBCA 建库、开机自启和密码注入
roles/oracle_validate/     部署后健康检查
tests/                     不连接目标机的静态与安全测试
docs/                      设计与运维说明
files/                     可选的组织自定义模板；不放安装介质
```

## 前置条件

控制机需要 Python 3、Ansible Core 2.14+、SSH 客户端以及目标机的 sudo 权限。目标机需要兼容的 64 位 Linux、至少 8 GB 内存、足够的 `/u01` 空间，并由用户在控制机或内部制品库准备 Oracle 安装压缩包。Oracle 安装介质与许可证不随本仓库分发。

建议通过 Ansible Vault 或 CI/CD Secret 注入 `oracle_sys_password`、`oracle_system_password`、`oracle_sysdba_password` 等敏感变量。示例文件中的密码均为占位符，不应直接用于生产。

## 快速开始

复制示例配置并按实际环境修改：

```bash
cp inventory/hosts.example.ini inventory/hosts.ini
cp inventory/group_vars/oracle.example.yml inventory/group_vars/oracle.yml
```

先执行语法检查和 dry-run：

```bash
ansible-playbook -i inventory/hosts.ini playbooks/deploy_single_instance.yml --syntax-check
ansible-playbook -i inventory/hosts.ini playbooks/deploy_single_instance.yml --check --diff
```

确认变更范围后执行部署。安装介质可以是控制机本地路径 `oracle_install_media`，也可以是目标机已存在的路径；默认不会从公网下载软件：

```bash
ansible-playbook -i inventory/hosts.ini playbooks/deploy_single_instance.yml \
  -e oracle_install_media=/secure/artifacts/LINUX.X64_193000_db_home.zip \
  -e oracle_deploy_confirm=true \
  --ask-become-pass
```

部署完成后运行验证：

```bash
ansible-playbook -i inventory/hosts.ini playbooks/validate.yml
```

## 安全设计

项目不会把生产密码、私钥、安装介质、钱包或 token 提交到 Git。高风险部署必须显式设置 `oracle_deploy_confirm=true`；默认只允许 `--check` 或直接失败。软件包支持 SHA-256 校验，安装前校验失败会停止流程。数据库密码通过临时受限文件传递，并在任务结束时删除；生产环境仍建议使用 Vault 或外部 Secret 管理系统。

## 版本策略

项目首版聚焦单实例，使用变量覆盖适配 Oracle 19c/21c。所有新增拓扑应当新增独立入口 Playbook 和 role，不应在单实例流程中堆叠隐式分支。每次发布应记录 Ansible 版本、Oracle 版本、OS 版本和验证结果。

## 许可证

本项目原创代码采用 Apache-2.0，Oracle 软件及其安装介质遵循 Oracle 的许可条款，不因本项目而获得再分发授权。
