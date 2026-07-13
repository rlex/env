---
name: ansible
description: Ansible Development Standards
---
# Ansible Development Standards

**Document Version:** 2.0.0  
**Last Updated:** 2026-07-03  
**Target Audience:** Mid-level engineers developing enterprise Ansible automation  
**Purpose:** Core standards for production-grade Ansible roles, playbooks, and custom modules

---

## Table of Contents

1. [Introduction](#introduction)
2. [Core Principles](#core-principles)
3. [Development Environment](#development-environment)
4. [Role Development Standards](#role-development-standards)
5. [Playbook Design Standards](#playbook-design-standards)
6. [Task Writing Standards](#task-writing-standards)
7. [Custom Module Development](#custom-module-development)
8. [Kubernetes/OpenShift Patterns](#kubernetesopenshift-patterns)
9. [Error Handling Patterns](#error-handling-patterns)
10. [Variable Management](#variable-management)
11. [Collection Management](#collection-management)
12. [Testing Standards](#testing-standards)
13. [Documentation Requirements](#documentation-requirements)
14. [Quality Assurance](#quality-assurance)
15. [AAP Integration Guidelines](#aap-integration-guidelines)
16. [Quick Reference](#quick-reference)

---

## Introduction

### Purpose of This Document

This document establishes the standards and best practices for developing Ansible automation within our organization. These standards ensure:

- **Consistency** across all automation code
- **Reliability** in production environments
- **Maintainability** by current and future team members
- **Scalability** from single-host to multi-cluster operations
- **Safety** through proper error handling and validation

### Document Scope

**This document covers:**

- Ansible role development
- Playbook design patterns
- Custom module creation
- Kubernetes/OpenShift automation patterns
- Quality assurance processes

**This document does NOT cover:**

- Basic Ansible syntax (assumed knowledge)
- Inventory management (separate document)
- AAP administration (separate document)

### How to Use This Document

**Standards Level Indicators:**

- **MUST** / **REQUIRED** / **MANDATORY** - No exceptions, enforced by tooling
- **SHOULD** / **RECOMMENDED** - Follow unless you have documented justification
- **MAY** / **OPTIONAL** - Use at your discretion

**Document Navigation:**

- Use this document as a **reference** - not meant to be read cover-to-cover
- Search for specific topics when needed
- Refer to the [Comprehensive Guide](docs/ansible/COMPREHENSIVE-GUIDE.md) for detailed examples
- Use the [Quick Reference](#quick-reference) for common patterns

### Relationship to Other Documents

- **COMPREHENSIVE-GUIDE.md** - Detailed examples and deep dives
- **MIGRATION-GUIDE.md** - How to refactor existing playbooks
- **CODE-REVIEW-CHECKLIST.md** - PR review requirements
- **KUBERNETES-PATTERNS.md** - K8s/OpenShift specific patterns
- **AGENTS.md** - AI agent coding standards
- **CLAUDE.md** - Claude Code specific instructions

### Version Awareness

This document targets **ansible-core >= 2.18** with awareness of **ansible-core 2.19** breaking changes. Key version milestones:

| Version | Released | Key Changes |
|---------|----------|-------------|
| 2.18 | Nov 2024 | Current stable baseline; Windows Server 2025 support |
| 2.19 | Jul 2025 | Data Tagging overhaul, stricter templating engine, trust model for templates, deprecation tagging |

**ansible-core 2.19 Impact Summary:**

- **Data Tagging**: Variables and values carry extensible metadata tags (provenance, trust status, deprecation). Embedded templates in untrusted strings are no longer executed — a security improvement that may break brittle Jinja patterns.
- **Template Trust Model**: Strings from playbooks/vars files are trusted by default. Data from external sources (host facts, collection return values) is untrusted and will NOT be templated unless explicitly marked with `trust_as_template()`.
- **Stricter Type Handling**: `_AnsibleTaggedStr`, `_AnsibleTaggedInt`, `_AnsibleTaggedFloat` aliases exist. The `reveal_ansible_type` filter and `ansible_type` test plugin are available for debugging.
- **Module Argument Loading**: Refactored internally; network collections relying on `ansible.netcommon` must upgrade in lockstep with core.

**Upgrade Guidance:** When targeting 2.19, audit all Jinja expressions that rely on data from external sources (fetched files, API responses, command output). Pin collection versions and test against 2.19 in CI before adopting.

---

## Core Principles

### The Ansible Way vs Shell Scripting

**CRITICAL MINDSET SHIFT**: Ansible is **declarative**, not **imperative**. Stop thinking in terms of "run these commands in sequence" and start thinking in terms of "ensure this state exists."

**Wrong Way (Shell Script Thinking):**

```yaml
- name: Check if file exists
  shell: test -f /etc/config.conf
  register: file_check
  
- name: Create file if missing
  shell: touch /etc/config.conf
  when: file_check.rc != 0
```

**Right Way (Ansible Thinking):**

```yaml
- name: Ensure configuration file exists
  ansible.builtin.file:
    path: /etc/config.conf
    state: file
    mode: '0644'
```

> **Note on `state: touch`**: This updates mtime on existing files, making it NOT fully idempotent. Use `state: file` with explicit `mode` when you only need to ensure existence without modifying timestamps.

**Key Differences:**

| Shell Script Thinking | Ansible Thinking |
|----------------------|------------------|
| Execute commands sequentially | Declare desired state |
| Check before acting | Let modules handle checks |
| Manual error handling | Built-in idempotency |
| Text parsing and grep | Structured data handling |
| Exit codes | Module return values |

### Enterprise-Grade Automation Principles

**1. Idempotency First**

- Running the same playbook multiple times produces the same result
- No side effects from repeated execution
- Use `changed_when` and `failed_when` appropriately

**2. Safety Through Validation**

- Validate inputs before execution
- Check prerequisites (preflight checks)
- Verify results after execution
- Fail fast with clear error messages

**3. Observable Operations**

- Log important operations
- Provide progress indicators
- Report results clearly
- Enable debugging without code changes

**4. Defensive Programming**

- Expect failures and handle them gracefully
- Use timeouts for all external operations
- Implement retries for transient failures
- Clean up resources in all exit paths

**5. Maintainability**

- Code should be self-documenting
- Use meaningful names (tasks, variables, roles)
- Modular design (small, focused task files)
- Comprehensive comments for complex logic

### Quality Over Speed

**We prioritize:**

- Correctness over quick implementation
- Maintainability over cleverness
- Clarity over brevity
- Reliability over features

**This means:**

- Take time to write proper error handling
- Don't skip validation steps to save time
- Write tests even for "simple" roles
- Document as you develop, not after

---

## Development Environment

### Required Tools

**MUST install and configure:**

```bash
# Python virtual environment (REQUIRED)
python3.11 -m venv .venv
source .venv/bin/activate  # Always activate before work

# Ansible and tools
pip install ansible-core>=2.18
pip install ansible-lint>=25.0
pip install yamllint

# Python quality tools
pip install black>=25.0
pip install isort>=6.0
pip install flake8>=7.0
pip install mypy>=1.0

# Markdown linting
pip install pymarkdownlnt
```

### Virtual Environment Usage

**CRITICAL**: ALL Ansible and Python commands MUST use the virtual environment.

```bash
# Correct - using venv
.venv/bin/ansible-playbook playbook.yml
.venv/bin/ansible-lint

# Wrong - using system Python
ansible-playbook playbook.yml  # DON'T DO THIS
```

**Why this matters:**

- Consistent versions across team
- Isolated from system packages
- Reproducible in CI/CD and AAP Execution Environments

### ansible-navigator (RECOMMENDED)

Use `ansible-navigator` to run playbooks inside Execution Environments locally, bridging the gap between local development and AAP execution:

```bash
# Install
pip install ansible-navigator

# Run playbook in an EE
ansible-navigator run playbook.yml -m stdout --ee true

# Run with specific EE image
ansible-navigator run playbook.yml --eei quay.io/ansible/creator-ee:v0.20.0 -m stdout

# Interactive mode (default)
ansible-navigator run playbook.yml
```

**Benefits:**

- Validates that playbooks work in the same container environment as AAP
- Catches missing collection dependencies before deployment
- Supports `--mode stdout` for CI/CD and interactive mode for development

### Pre-commit Hooks

**SHOULD configure** pre-commit hooks to catch issues before commit:

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/ansible/ansible-lint
    rev: v25.7.0
    hooks:
      - id: ansible-lint
        args: ["--profile=production"]
        
  - repo: https://github.com/psf/black
    rev: 25.1.0
    hooks:
      - id: black
        language_version: python3.11
        
  - repo: https://github.com/PyCQA/isort
    rev: 6.0.0
    hooks:
      - id: isort
        
  - repo: https://github.com/adrienverge/yamllint
    rev: v1.35.1
    hooks:
      - id: yamllint
        args: ["-c", ".yamllint"]
```

Install hooks:

```bash
pip install pre-commit
pre-commit install
```

### Editor Configuration

**RECOMMENDED** editor settings (VSCode example):

```json
{
  "ansible.python.interpreterPath": "${workspaceFolder}/.venv/bin/python",
  "ansible.validation.enabled": true,
  "ansible.validation.lint.enabled": true,
  "ansible.validation.lint.path": "${workspaceFolder}/.venv/bin/ansible-lint",
  "python.defaultInterpreterPath": "${workspaceFolder}/.venv/bin/python",
  "python.linting.enabled": true,
  "python.linting.flake8Enabled": true,
  "python.formatting.provider": "black",
  "[yaml]": {
    "editor.formatOnSave": true,
    "editor.tabSize": 2
  },
  "[python]": {
    "editor.formatOnSave": true,
    "editor.tabSize": 4
  }
}
```

### Quality Check Workflow

**MUST run** before every commit:

> **IMPORTANT**: As of ansible-lint v25.7.0, you MUST run `ansible-lint` from the project root directory. Running from subdirectories (e.g., inside `roles/`) is unsupported and may silently report zero errors.

```bash
# All commands run from project root

# 1. Ansible linting (auto-discovers roles and playbooks)
.venv/bin/ansible-lint --profile=production

# 2. YAML linting
.venv/bin/yamllint roles/ playbooks/

# 3. Syntax check
.venv/bin/ansible-playbook --syntax-check playbooks/*.yml

# 4. Python quality (if custom modules/filters)
.venv/bin/black roles/*/library/
.venv/bin/isort roles/*/library/
.venv/bin/flake8 roles/*/library/
.venv/bin/mypy roles/*/library/

# 5. Markdown linting (if documentation changes)
pymarkdownlnt -d MD013 scan docs/
```

---

## Role Development Standards

### Role Structure

**REQUIRED** directory structure for all roles:

```text
<role_name>/
├── README.md                      # Role documentation (REQUIRED)
├── CHANGELOG.md                   # Version history (REQUIRED)
├── LICENSE                        # License file (REQUIRED)
├── requirements.yml               # Collection dependencies (if needed)
├── requirements.txt               # Python dependencies (if custom modules)
├── .ansible-lint                  # Role-specific lint config (OPTIONAL)
├── defaults/
│   └── main.yml                  # Default variables (REQUIRED)
├── vars/
│   └── main.yml                  # Internal constants (OPTIONAL)
├── meta/
│   ├── main.yml                  # Role metadata (REQUIRED)
│   └── argument_specs.yml        # Argument validation spec (RECOMMENDED)
├── molecule/                      # Molecule test scenarios (RECOMMENDED)
│   └── default/
│       ├── molecule.yml
│       ├── converge.yml
│       └── verify.yml
├── tasks/
│   ├── main.yml                  # Orchestrator (REQUIRED)
│   ├── preflight.yml             # Pre-flight checks (RECOMMENDED)
│   ├── prepare.yml               # Preparation steps (OPTIONAL)
│   ├── execute.yml               # Main execution (OPTIONAL)
│   ├── verify.yml                # Post-execution checks (RECOMMENDED)
│   ├── cleanup.yml               # Cleanup operations (OPTIONAL)
│   └── report.yml                # Result reporting (OPTIONAL)
├── handlers/
│   └── main.yml                  # Event handlers (OPTIONAL)
├── templates/                     # Jinja2 templates (OPTIONAL)
├── files/                        # Static files (OPTIONAL)
├── library/                      # Custom modules (OPTIONAL)
│   ├── <module_name>.py
│   └── README.md
└── filter_plugins/               # Custom filters (OPTIONAL)
    ├── <filter_name>.py
    └── README.md
```

> **Note:** The `validate.yml` task file is no longer needed when using `meta/argument_specs.yml` for argument validation (see [Role Argument Validation](#role-argument-validation) below). Ansible auto-inserts a validation task at role entry.

### Orchestrator Pattern (tasks/main.yml)

**MUST** use orchestrator pattern for `tasks/main.yml`:

```yaml
---
# Role: <role_name>
# Purpose: Brief description of what this role does
# Author: Your Name
# Last Updated: YYYY-MM-DD

# Phase 1: Preflight Checks
- name: "Phase 1: Preflight Checks"
  ansible.builtin.import_tasks: preflight.yml
  tags:
    - always
    - preflight
    - <role_name>

# Phase 2: Preparation
- name: "Phase 2: Preparation"
  ansible.builtin.import_tasks: prepare.yml
  tags:
    - preparation
    - <role_name>
  when: <role_name>_skip_preparation | default(false) | bool == false

# Phase 3: Execution
- name: "Phase 3: Execution"
  ansible.builtin.import_tasks: execute.yml
  tags:
    - execution
    - <role_name>

# Phase 4: Verification
- name: "Phase 4: Verification"
  ansible.builtin.import_tasks: verify.yml
  tags:
    - verification
    - <role_name>
  when: <role_name>_skip_verification | default(false) | bool == false

# Phase 5: Reporting
- name: "Phase 5: Reporting"
  ansible.builtin.import_tasks: report.yml
  tags:
    - reporting
    - <role_name>
  when: <role_name>_enable_reporting | default(true) | bool
```

**Key principles:**

- **Keep main.yml under 100 lines** - it should only orchestrate
- **Use import_tasks** for static includes, **include_tasks** for dynamic (see [import_tasks vs include_tasks](#import_tasks-vs-include_tasks))
- **Every phase is optional** except main execution
- **Use tags consistently** for selective execution
- **Document each phase** with clear comments

### import_tasks vs include_tasks

**MUST** understand the behavioral differences:

| Aspect | `import_tasks` | `include_tasks` |
|--------|---------------|-----------------|
| Resolution | Parse time (static) | Runtime (dynamic) |
| Tags | Propagate to imported tasks | Do NOT propagate to included tasks |
| `when:` on include | Applies to entire include | Applies per-task inside file |
| Variables | Available at play scope | Scoped to include context |
| `--list-tasks` | Shows all imported tasks | Shows only the include line |
| Loops | NOT supported | Supported |

**When to use `import_tasks`:**

- Task files are known at parse time
- You want tags to propagate
- You want `--list-tasks` to show all tasks

**When to use `include_tasks`:**

- Dynamic file selection (e.g., based on `ansible_os_family`)
- Need to loop over task files
- Need runtime variable evaluation for file selection

```yaml
# Static - use import_tasks
- name: Run preflight checks
  ansible.builtin.import_tasks: preflight.yml

# Dynamic - use include_tasks
- name: Include OS-specific tasks
  ansible.builtin.include_tasks: "{{ ansible_os_family | lower }}.yml"
```

> **Common pitfall:** Using `include_tasks` inside a `when:` block causes the `when` to apply to the include itself, not individual tasks within. If any included task should run conditionally, put `when:` on those tasks directly.

### Task File Organization

**SHOULD** organize task files by workflow phase:

**preflight.yml** - Environment and prerequisite checks:

```yaml
---
# Preflight checks: Verify environment is ready for role execution

- name: Check Ansible version
  ansible.builtin.assert:
    that:
      - ansible_version.full is version('2.18.0', '>=')
    fail_msg: "Ansible 2.18.0 or higher required"
    quiet: true
  tags: [version-check]

- name: Verify required commands are available
  ansible.builtin.command:
    cmd: "which {{ item }}"
  loop:
    - kubectl
    - oc
  changed_when: false
  failed_when: false
  register: command_check
  tags: [prerequisites]

- name: Fail if required commands missing
  ansible.builtin.fail:
    msg: "Required command '{{ item.item }}' not found in PATH"
  loop: "{{ command_check.results }}"
  when: item.rc != 0
  tags: [prerequisites]
```

### Role Argument Validation

**SHOULD** use `meta/argument_specs.yml` for variable validation instead of manual `assert` tasks. Ansible auto-inserts a validation task at role entry that checks all provided variables against the specification — fails fast with structured error messages before any role task runs.

**meta/argument_specs.yml:**

```yaml
---
argument_specs:
  main:
    short_description: Main role entry point
    description:
      - Full role execution with all phases
    options:
      <role_name>_namespace:
        type: str
        required: true
        description: Target Kubernetes namespace

      <role_name>_resource_name:
        type: str
        required: true
        description: Name of the resource to manage

      <role_name>_timeout:
        type: int
        required: false
        default: 300
        description: Operation timeout in seconds

      <role_name>_retry_count:
        type: int
        required: false
        default: 30
        description: Number of retries for transient failures

      <role_name>_retry_delay:
        type: int
        required: false
        default: 10
        description: Delay between retries in seconds

      <role_name>_enable_validation:
        type: bool
        required: false
        default: true
        description: Whether to run input validation phase

      <role_name>_enable_reporting:
        type: bool
        required: false
        default: true
        description: Whether to run reporting phase

      <role_name>_debug_mode:
        type: bool
        required: false
        default: false
        description: Enable debug output

      <role_name>_api_key:
        type: str
        required: false
        no_log: true
        description: API key for external service (sensitive)

      <role_name>_report_format:
        type: str
        required: false
        default: json
        choices:
          - json
          - yaml
          - text
        description: Output format for reports

  # Additional entry points can define their own specs
  cleanup:
    short_description: Cleanup-only execution
    options:
      <role_name>_cleanup_target:
        type: str
        required: true
        description: Resource to clean up
```

**Supported types:** `str`, `int`, `float`, `bool`, `list`, `dict`, `path`, `raw`, `jsonarg`, `json`, `bytes`, `bits`

**Key features:**

- `required: true` — fails immediately if missing
- `type` — enforces type coercion and validation
- `choices` — restricts to enumerated values
- `no_log: true` — prevents sensitive values from appearing in output
- `default` — documents default value (actual defaults stay in `defaults/main.yml`)
- Multiple entry points via separate spec names (e.g., `main`, `cleanup`, `backup`)

**Playbook-level argument specs** are also supported (ansible-core 2.18+) via `<playbook_name>.meta.yml`:

```yaml
# deploy_webservers.meta.yml
---
description: Deploy and configure webservers
argument_specs:
  deploy webservers:
    options:
      document_root:
        type: path
        required: true
        description: Path to web content
```

### Naming Conventions

**MUST** follow these naming conventions:

**Role Names:**

- Use snake_case: `portworx_upgrade`, `must_gather_log`
- Be descriptive: Name should indicate purpose
- Avoid abbreviations unless widely known

**Variable Names:**

- Prefix with role name: `<role_name>_variable_name`
- Use snake_case: `portworx_upgrade_timeout`
- Be descriptive: `portworx_upgrade_global_timeout` not `px_to`
- Boolean variables should read as predicates: `is_debug_enabled`, `has_replicas`, `enable_reporting`
- Private/internal variables use `__` double-underscore prefix: `__<role_name>_internal_state`

**Task Names:**

- Use action verbs: "Create", "Validate", "Check", "Update"
- Be specific: "Validate cluster connectivity" not "Check"
- Indicate what, not how: "Ensure pod is running" not "kubectl get pod"
- Use sentence case: "Check cluster status" not "check cluster status"

**Tag Names:**

- Use lowercase with hyphens: `pre-flight`, `post-check`
- Be consistent across roles
- Include role name tag: `portworx-upgrade`
- Use standard tags: `always`, `never`, `preparation`, `validation`, `execution`, `verification`, `reporting`

### Variable Management

**defaults/main.yml** - User-configurable variables:

```yaml
---
# <role_name> default variables
# These can be overridden by users

# General settings
<role_name>_namespace: "default"
<role_name>_timeout: 300  # seconds
<role_name>_retry_count: 30
<role_name>_retry_delay: 10  # seconds

# Feature flags
<role_name>_enable_validation: true
<role_name>_enable_verification: true
<role_name>_enable_reporting: true
<role_name>_debug_mode: false

# Operational settings
<role_name>_max_concurrent: 5
<role_name>_failure_threshold: 3
<role_name>_wait_for_ready: true

# Reporting settings
<role_name>_report_format: "json"  # json, yaml, text
<role_name>_report_destination: "/tmp/<role_name>-report.json"

# Sensitive variables - use no_log when referencing in tasks
# <role_name>_api_key: ""  # Set via vault or extra_vars, never in defaults
```

**vars/main.yml** - Internal constants (users should not change):

```yaml
---
# <role_name> internal variables
# DO NOT override these in playbooks
# The __ prefix signals these are private to the role

# Internal constants
__<role_name>_version: "1.0.0"
__<role_name>_supported_k8s_versions:
  - "1.28"
  - "1.29"
  - "1.30"
  - "1.31"

# Internal state variables
__<role_name>_temp_dir: "/tmp/ansible-<role_name>-{{ ansible_date_time.epoch }}"
__<role_name>_log_file: "{{ __<role_name>_temp_dir }}/execution.log"
```

**meta/main.yml** - Role metadata:

```yaml
---
galaxy_info:
  role_name: <role_name>
  namespace: your_namespace
  author: Your Name
  description: Brief description of role purpose
  company: Your Company
  license: Apache-2.0
  
  min_ansible_version: "2.18"
  
  platforms:
    - name: EL
      versions:
        - "8"
        - "9"
  
  galaxy_tags:
    - kubernetes
    - openshift
    - automation
    - infrastructure

dependencies: []
```

---

## Playbook Design Standards

### Playbook Structure

**MUST** follow this structure for all playbooks:

```yaml
---
# Playbook: <playbook_name>.yml
# Purpose: Brief description of what this playbook does
# Author: Your Name
# Last Updated: YYYY-MM-DD
#
# Usage:
#   ansible-playbook -i inventory playbook.yml
#   ansible-playbook -i inventory playbook.yml --tags preflight
#   ansible-playbook -i inventory playbook.yml --check

- name: Descriptive playbook name
  hosts: target_hosts
  gather_facts: true  # or false with justification
  become: false  # or true with justification
  
  # Variables specific to this playbook
  vars:
    playbook_variable: "value"
  
  # Files containing additional variables
  vars_files:
    - vars/common.yml
    - vars/environment.yml
  
  # Pre-execution tasks
  pre_tasks:
    - name: Display playbook information
      ansible.builtin.debug:
        msg: |
          Playbook: {{ ansible_play_name }}
          Target: {{ inventory_hostname }}
          User: {{ ansible_user_id }}
          Started: {{ ansible_date_time.iso8601 }}
      tags: [always]
    
    - name: Validate prerequisites
      ansible.builtin.assert:
        that:
          - ansible_version.full is version('2.18.0', '>=')
          - required_variable is defined
        fail_msg: "Prerequisites not met"
      tags: [always]
  
  # Role execution
  roles:
    - role: <role_name>
      vars:
        <role_name>_variable: "value"
      tags: [<role_name>]
  
  # Post-execution tasks
  post_tasks:
    - name: Display execution summary
      ansible.builtin.debug:
        msg: |
          Execution Status: {{ <role_name>_execution_status }}
          Duration: {{ execution_duration }}s
          Completed: {{ ansible_date_time.iso8601 }}
      tags: [always]
```

### Common Playbook Anti-Patterns to Avoid

**Anti-Pattern 1: Playbook as a Shell Script**

```yaml
# DON'T DO THIS
- name: Bad playbook
  hosts: localhost
  tasks:
    - shell: oc get pods -n openshift-storage
    - shell: oc get pv | grep -i portworx
    - shell: oc describe storagecluster
```

**Correct Approach:**

```yaml
# DO THIS
- name: Good playbook
  hosts: localhost
  tasks:
    - name: Get pods in storage namespace
      kubernetes.core.k8s_info:
        api_version: v1
        kind: Pod
        namespace: openshift-storage
      register: storage_pods
    
    - name: Get Portworx persistent volumes
      kubernetes.core.k8s_info:
        api_version: v1
        kind: PersistentVolume
        label_selectors:
          - "pv.kubernetes.io/provisioned-by=portworx"
      register: portworx_pvs
```

**Anti-Pattern 2: No Error Handling**

```yaml
# DON'T DO THIS
- name: Bad playbook
  hosts: localhost
  tasks:
    - name: Update resource
      kubernetes.core.k8s:
        definition: "{{ resource_def }}"
    
    - name: Wait for ready
      shell: sleep 30
```

**Correct Approach:**

```yaml
# DO THIS
- name: Good playbook
  hosts: localhost
  tasks:
    - name: Update resource with error handling
      block:
        - name: Update resource
          kubernetes.core.k8s:
            definition: "{{ resource_def }}"
            wait: true
            wait_timeout: 300
          register: update_result
        
        - name: Wait for pod to be ready
          kubernetes.core.k8s_info:
            api_version: v1
            kind: Pod
            namespace: "{{ namespace }}"
            name: "{{ pod_name }}"
          register: pod_status
          until:
            - pod_status.resources | length > 0
            - pod_status.resources[0].status.phase == 'Running'
          retries: 30
          delay: 10
      
      rescue:
        - name: Handle failure
          ansible.builtin.debug:
            msg: "Operation failed: {{ ansible_failed_result.msg }}"
        
        - name: Fail with clear message
          ansible.builtin.fail:
            msg: "Resource update failed"
```

---

## Task Writing Standards

### Mandatory Task Elements

**MUST** include these elements in every task:

1. **Meaningful name**: Describes what the task does
2. **FQCN**: Fully Qualified Collection Name for all modules
3. **Tags**: At least role name and phase tags
4. **changed_when/failed_when**: For shell/command tasks
5. **Error handling**: For operations that can fail

### FQCN Usage

**MUST** use Fully Qualified Collection Names:

```yaml
# Correct
- name: Create directory
  ansible.builtin.file:
    path: /tmp/work
    state: directory
    mode: '0755'

- name: Get pod information
  kubernetes.core.k8s_info:
    kind: Pod
    namespace: default

# Wrong
- name: Create directory
  file:  # Missing FQCN
    path: /tmp/work
    state: directory
```

### Idempotency with changed_when and failed_when

**MUST** define `changed_when` and `failed_when` for shell/command tasks:

**Read-only operations** - Never report as changed:

```yaml
- name: Get list of storage nodes
  ansible.builtin.command:
    cmd: oc get nodes -l node-role.kubernetes.io/storage='' --no-headers
  register: storage_nodes
  changed_when: false  # Read-only operation
  failed_when: storage_nodes.rc != 0
```

> **Note:** Prefer `ansible.builtin.command` over `ansible.builtin.shell` for simple commands without pipes or shell features. ansible-lint's `command-instead-of-shell` rule flags unnecessary shell usage. Use `shell` only when you need pipes, redirects, or `set -o pipefail`.

**Operations with grep** - Allow no-match exit code:

```yaml
- name: Check for running pods
  ansible.builtin.shell: |
    set -o pipefail &&
    oc get pods -n {{ namespace }} | grep Running
  args:
    executable: /bin/bash
  register: running_pods
  changed_when: false
  failed_when: running_pods.rc not in [0, 1]  # 1 = no matches, OK
```

**State-modifying operations** - Detect actual change:

```yaml
- name: Apply configuration
  ansible.builtin.command:
    cmd: oc apply -f /tmp/config.yaml
  register: apply_result
  changed_when: "'configured' in apply_result.stdout or 'created' in apply_result.stdout"
  failed_when: apply_result.rc != 0
```

### Loop Constructs

**Use `loop` with list** (preferred):

```yaml
- name: Create multiple directories
  ansible.builtin.file:
    path: "{{ item }}"
    state: directory
    mode: '0755'
  loop:
    - /tmp/dir1
    - /tmp/dir2
    - /tmp/dir3
```

**Use `loop` with complex data**:

```yaml
- name: Create users with specific settings
  ansible.builtin.user:
    name: "{{ item.name }}"
    uid: "{{ item.uid }}"
    groups: "{{ item.groups }}"
  loop:
    - name: alice
      uid: 1001
      groups: [admin, developers]
    - name: bob
      uid: 1002
      groups: [developers]
  loop_control:
    label: "{{ item.name }}"  # Cleaner output
```

### Retries and Timeouts

**SHOULD** implement retries for operations that may fail transiently:

```yaml
- name: Wait for API endpoint to be available
  ansible.builtin.uri:
    url: "{{ api_endpoint }}/health"
    method: GET
    status_code: 200
    timeout: 10
  register: health_check
  retries: 30
  delay: 10
  until: health_check.status == 200

- name: Wait for pod to be ready
  kubernetes.core.k8s_info:
    api_version: v1
    kind: Pod
    namespace: "{{ namespace }}"
    name: "{{ pod_name }}"
  register: pod_status
  retries: 60
  delay: 5
  until:
    - pod_status.resources | length > 0
    - pod_status.resources[0].status.phase == 'Running'
```

---

## Custom Module Development

### When to Create Custom Modules

**SHOULD** create custom modules when:

1. **Repeated complex shell commands**: Same multi-line shell script used in multiple roles
2. **External tool interaction**: Need to parse output from tools like `pxctl`, `etcdctl`
3. **Custom logic**: Behavior not available in existing modules
4. **Idempotency**: Need proper change detection for external state
5. **Error handling**: Need structured error handling for specific operations

**SHOULD NOT** create custom modules when:

1. Existing module can do the job
2. Simple shell command is sufficient
3. Operation is one-time use

### Module Structure Template

**MUST** follow this structure for all custom modules:

```python
#!/usr/bin/python
# -*- coding: utf-8 -*-

# Copyright: (c) 2025, Your Name <your.email@company.com>
# Apache License 2.0

from __future__ import absolute_import, division, print_function

__metaclass__ = type

DOCUMENTATION = r"""
---
module: module_name
short_description: Brief one-line description
description:
  - Detailed description of what the module does
  - Second line if needed
version_added: "1.0.0"
author:
  - Your Name (@github_username)
options:
  parameter_name:
    description:
      - Description of this parameter
    type: str
    required: true
  output_path:
    description:
      - Path for output file
    type: path
    required: false
    default: /tmp/output
requirements:
  - python >= 3.11
seealso:
  - module: ansible.builtin.file
"""

EXAMPLES = r"""
# Basic usage
- name: Basic example
  my_namespace.my_collection.module_name:
    parameter_name: value

# With optional parameters
- name: Advanced example
  my_namespace.my_collection.module_name:
    parameter_name: value
    output_path: /var/log/result
"""

RETURN = r"""
changed:
  description: Whether the module made changes
  type: bool
  returned: always
message:
  description: Human-readable message
  type: str
  returned: always
output_file:
  description: Path to the output file created
  type: str
  returned: on success
"""

from ansible.module_utils.basic import AnsibleModule


def run_module():
    module_args = dict(
        parameter_name=dict(type="str", required=True),
        output_path=dict(type="path", required=False, default="/tmp/output"),
    )

    module = AnsibleModule(
        argument_spec=module_args,
        supports_check_mode=True,
    )

    parameter_name = module.params["parameter_name"]
    output_path = module.params["output_path"]

    result = dict(
        changed=False,
        message="No changes made",
    )

    if module.check_mode:
        result["message"] = "Would process %s" % parameter_name
        module.exit_json(**result)

    try:
        # Module logic here
        result["changed"] = True
        result["message"] = "Processed %s" % parameter_name
        result["output_file"] = output_path
        module.exit_json(**result)

    except Exception as e:
        module.fail_json(msg="Module failed: %s" % str(e), **result)


def main():
    run_module()


if __name__ == "__main__":
    main()
```

---

## Kubernetes/OpenShift Patterns

### Stop Using `oc` Commands

**CRITICAL**: Stop using `shell: oc command` for everything. Use native Kubernetes modules.

### Common oc Command Translations

**Pattern 1: Getting Resources**

Wrong:

```yaml
- name: Get pods
  shell: oc get pods -n openshift-storage --no-headers
  register: pods
```

Correct:

```yaml
- name: Get pods in storage namespace
  kubernetes.core.k8s_info:
    api_version: v1
    kind: Pod
    namespace: openshift-storage
  register: pods
```

**Pattern 2: Updating Resources**

Wrong:

```yaml
- name: Patch deployment
  shell: |
    oc patch deployment {{ deploy_name }} -n {{ namespace }} \
      --patch '{"spec":{"replicas":{{ replica_count }}}}'
```

Correct:

```yaml
- name: Scale deployment
  kubernetes.core.k8s:
    api_version: apps/v1
    kind: Deployment
    name: "{{ deploy_name }}"
    namespace: "{{ namespace }}"
    definition:
      spec:
        replicas: "{{ replica_count }}"
```

**Pattern 3: Executing Commands in Pods**

Wrong:

```yaml
- name: Run command in pod
  shell: oc rsh -n {{ namespace }} {{ pod_name }} /bin/bash -c "{{ command }}"
  register: pod_output
```

Correct:

```yaml
- name: Execute command in pod
  kubernetes.core.k8s_exec:
    namespace: "{{ namespace }}"
    pod: "{{ pod_name }}"
    command: "{{ command }}"
  register: pod_output
```

### Working with Custom Resource Definitions (CRDs)

```yaml
- name: Get StorageCluster resource
  kubernetes.core.k8s_info:
    api_version: core.libopenstorage.org/v1
    kind: StorageCluster
    namespace: kube-system
    name: px-cluster
  register: storage_cluster

- name: Update StorageCluster image
  kubernetes.core.k8s:
    api_version: core.libopenstorage.org/v1
    kind: StorageCluster
    name: px-cluster
    namespace: kube-system
    definition:
      spec:
        image: "portworx/oci-monitor:{{ new_version }}"
```

### Pod Lifecycle Monitoring

```yaml
- name: Wait for pod to be running
  kubernetes.core.k8s_info:
    api_version: v1
    kind: Pod
    namespace: "{{ namespace }}"
    name: "{{ pod_name }}"
  register: pod_status
  until:
    - pod_status.resources | length > 0
    - pod_status.resources[0].status.phase == 'Running'
    - pod_status.resources[0].status.conditions | selectattr('type', 'equalto', 'Ready') | selectattr('status', 'equalto', 'True') | list | length > 0
  retries: 60
  delay: 10
```

### Multi-Cluster Patterns

```yaml
---
# Sequential cluster operations

- name: Multi-cluster operation
  hosts: k8s_clusters
  gather_facts: false
  serial: 1  # One cluster at a time
  
  tasks:
    - name: Execute operation on cluster
      ansible.builtin.include_role:
        name: cluster_operation
      vars:
        cluster_name: "{{ inventory_hostname }}"
```

---

## Error Handling Patterns

### Block/Rescue/Always Structure

**MUST** use block/rescue/always for operations that can fail and need cleanup or specific error handling:

```yaml
- name: Operation with comprehensive error handling
  block:
    # Try block - main operation
    - name: Execute primary operation
      kubernetes.core.k8s:
        definition: "{{ resource_definition }}"
      register: operation_result
    
    - name: Record success
      ansible.builtin.set_fact:
        operation_status: "success"
  
  rescue:
    # Rescue block - error handling
    - name: Log error details
      ansible.builtin.debug:
        msg: "Operation failed: {{ ansible_failed_result.msg }}"
    
    - name: Record failure
      ansible.builtin.set_fact:
        operation_status: "failed"
    
    - name: Fail with clear message
      ansible.builtin.fail:
        msg: "Operation failed: {{ ansible_failed_result.msg }}"
  
  always:
    # Always block - cleanup (ALWAYS runs)
    - name: Remove temporary files
      ansible.builtin.file:
        path: "{{ temp_dir }}"
        state: absent
      when: temp_dir is defined
```

> **Note:** Not every task needs block/rescue/always. Use it for operations that: (a) can fail and need cleanup, (b) need specific error recovery, or (c) must run cleanup regardless of success/failure. Simple tasks with proper `failed_when` are sufficient for straightforward operations.

### Timeout Handling

```yaml
- name: Operation with dual timeout mechanism
  vars:
    global_timeout: 2100  # 35 minutes
    inactivity_timeout: 2100
    start_time: "{{ ansible_date_time.epoch }}"
  
  block:
    - name: Monitor operation with timeouts
      block:
        - name: Check resource status
          kubernetes.core.k8s_info:
            api_version: v1
            kind: Pod
            namespace: "{{ namespace }}"
          register: resource_status
        
        - name: Check global timeout
          ansible.builtin.fail:
            msg: "Global timeout exceeded"
          when: (ansible_date_time.epoch | int) - (start_time | int) > global_timeout
      
      until: operation_complete
      retries: "{{ (global_timeout / 10) | int }}"
      delay: 10
```

---

## Variable Management

### Variable Precedence

**Understanding variable precedence** (lowest to highest):

1. role defaults
2. inventory group vars
3. inventory host vars
4. playbook vars
5. role vars
6. task vars
7. extra vars (command line)

**Key Takeaways**:

- `defaults/main.yml` - Lowest precedence, easily overridden
- `vars/main.yml` - High precedence, hard to override
- `extra_vars` - Highest precedence

### Variable Validation

**SHOULD** use `meta/argument_specs.yml` as the primary validation mechanism (see [Role Argument Validation](#role-argument-validation)).

For additional runtime validation beyond what argument specs cover (e.g., cross-variable constraints, external state checks), use `assert` tasks in `preflight.yml`:

```yaml
- name: Validate cross-variable constraints
  ansible.builtin.assert:
    that:
      - <role_name>_timeout > <role_name>_retry_delay
      - <role_name>_namespace != "kube-system" or <role_name>_allow_system_namespace | default(false)
    fail_msg: "Invalid variable combination"
```

### Sensitive Variables

**MUST** protect sensitive data:

```yaml
# In argument_specs.yml
<role_name>_api_key:
  type: str
  required: true
  no_log: true
  description: API key for external service

# In tasks - always use no_log for sensitive values
- name: Configure service with API key
  ansible.builtin.template:
    src: config.j2
    dest: /etc/service/config.yml
    mode: '0600'
  no_log: true  # Prevents {{ <role_name>_api_key }} from appearing in output
```

**Rules for sensitive data:**

- Never store passwords/API keys in `defaults/main.yml` — use Ansible Vault or pass via extra_vars
- Always use `no_log: true` on tasks that reference sensitive variables
- Use `no_log: true` in `argument_specs.yml` for sensitive options
- Set file permissions (`mode: '0600'`) on files containing secrets

---

## Collection Management

### Managing Collection Dependencies

**MUST** manage collection dependencies explicitly:

**requirements.yml** (at project root):

```yaml
---
collections:
  - name: kubernetes.core
    version: ">=3.0.0,<4.0.0"
  - name: community.general
    version: ">=9.0.0"
  - name: ansible.posix
    version: ">=1.5.0"

roles:
  - name: geerlingguy.docker
    version: "7.1.0"
```

**ansible.cfg** (at project root):

```ini
[defaults]
collections_paths = ./collections
roles_path = ./roles
gathering = explicit

[galaxy]
server_list = galaxy

[galaxy_server.galaxy]
url = https://galaxy.ansible.com/
```

### Best Practices

- **Pin versions** in `requirements.yml` — use version constraints (`>=2.0,<3.0`) for collections, exact versions for roles
- **Install before linting** — `ansible-galaxy collection install -r requirements.yml` before running `ansible-lint`
- **Separate files for AAP** — AAP expects `collections/requirements.yml` and `roles/requirements.yml` as separate files
- **Treat as first-class artifacts** — commit `requirements.yml` to version control, review in PRs
- **Verify before execution** — `ansible-galaxy collection verify` checks installed versions match requirements

```bash
# Install all dependencies
ansible-galaxy install -r requirements.yml

# Install collections only
ansible-galaxy collection install -r requirements.yml

# Install roles only
ansible-galaxy role install -r requirements.yml

# Force reinstall (update)
ansible-galaxy collection install -r requirements.yml --force
```

---

## Testing Standards

### ansible-lint Profiles

ansible-lint profiles gradually increase strictness. Understand the hierarchy:

| Profile | Focus | When to Use |
|---------|-------|-------------|
| `min` | Syntax errors only | Legacy code triage |
| `basic` | Common style/formatting | Starting point for new projects |
| `moderate` | Task naming, structure | Active development |
| `safety` | File permissions, package pinning | Pre-production |
| `shared` | changed_when, idempotency | Shared collections |
| `production` | All rules, strictest | AAP-certified content |

**Target `production` profile** for all new roles. Graduate existing roles through the hierarchy.

### Role Testing Workflow

**MUST** test roles through these phases:

**Phase 1: Syntax Validation**

```bash
ansible-playbook --syntax-check playbooks/test_role.yml
```

**Phase 2: Linting**

```bash
# Run from project root
.venv/bin/ansible-lint --profile=production
.venv/bin/yamllint roles/ playbooks/
```

**Phase 3: Check Mode (Dry Run)**

```bash
ansible-playbook -i inventory playbooks/test_role.yml --check
```

**Phase 4: Tag-Based Testing**

```bash
ansible-playbook -i inventory playbooks/test_role.yml --tags preflight
ansible-playbook -i inventory playbooks/test_role.yml --tags validation
```

**Phase 5: Full Execution**

```bash
ansible-playbook -i inventory/test playbooks/test_role.yml -vv
```

### Molecule Testing

**SHOULD** use Molecule for comprehensive role testing. Molecule creates disposable instances, runs roles, verifies idempotency, and tears down.

**Install:**

```bash
pip install molecule molecule-plugins[docker]
```

**Basic scenario structure:**

```text
<role_name>/
└── molecule/
    └── default/
        ├── molecule.yml      # Test configuration
        ├── converge.yml      # Playbook applying the role
        └── verify.yml        # Verification tasks
```

**molecule/default/molecule.yml:**

```yaml
---
dependency:
  name: galaxy
driver:
  name: docker
platforms:
  - name: rocky9
    image: "geerlingguy/docker-rockylinux9-ansible:latest"
    command: /usr/lib/systemd/systemd
    privileged: true
    pre_build_image: true
    tmpfs:
      - /run
      - /tmp
  - name: ubuntu2404
    image: "geerlingguy/docker-ubuntu2404-ansible:latest"
    command: /lib/systemd/systemd
    privileged: true
    pre_build_image: true
    tmpfs:
      - /run
      - /tmp
provisioner:
  name: ansible
  config_options:
    defaults:
      gathering: explicit
verifier:
  name: ansible
```

**molecule/default/converge.yml:**

```yaml
---
- name: Converge
  hosts: all
  tasks:
    - name: Include <role_name>
      ansible.builtin.include_role:
        name: <role_name>
```

**molecule/default/verify.yml:**

```yaml
---
- name: Verify
  hosts: all
  tasks:
    - name: Verify service is running
      ansible.builtin.service:
        name: "{{ item }}"
      check_mode: true
      register: service_status
      loop: "{{ expected_services }}"
      failed_when: service_status.status.ActiveState != 'active'
```

**Molecule workflow:**

```bash
# Run full test cycle (create, converge, verify, idempotence, destroy)
molecule test

# Development cycle
molecule create      # Spin up test instances
molecule converge    # Apply role
molecule verify      # Run verification
molecule idempotence # Re-run converge, expect zero changes
molecule destroy     # Tear down instances

# CI/CD integration (GitHub Actions example)
# .github/workflows/molecule.yml
name: Molecule Test
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: "3.11"
      - name: Install dependencies
        run: pip install molecule molecule-plugins[docker] ansible-lint
      - name: Run Molecule
        run: molecule test
```

**Best practices:**

- Test on multiple platforms (Rocky 9, Ubuntu 24.04, Debian 12)
- Always verify idempotency (Molecule runs converge twice by default)
- Use Docker for fast local testing, cloud drivers for infrastructure roles
- Integrate with CI/CD for automated testing on every commit

### Testing Checklist

**Before committing code:**

- [ ] Syntax check passes
- [ ] Ansible-lint passes (production profile)
- [ ] YAML lint passes
- [ ] Check mode runs without errors
- [ ] All tags work individually
- [ ] Full playbook runs successfully
- [ ] Error handling tested
- [ ] Molecule tests pass (if configured)
- [ ] Documentation updated
- [ ] CHANGELOG updated

---

## Documentation Requirements

### README.md Structure

**MUST** include these sections:

```markdown
# Ansible Role: <role_name>

## Description

Brief description of what this role does.

## Requirements

- Ansible Core: 2.18+
- Python: 3.11+
- Collections:
  - kubernetes.core (>= 3.0.0)

## Role Variables

### Required Variables

| Variable | Type | Description |
|----------|------|-------------|
| `<role_name>_namespace` | string | Kubernetes namespace |

### Optional Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `<role_name>_timeout` | int | 300 | Timeout in seconds |

### Sensitive Variables

| Variable | Type | Description |
|----------|------|-------------|
| `<role_name>_api_key` | string | API key (set via Vault or extra_vars) |

## Example Playbook

\`\`\`yaml
---
- name: Execute <role_name>
  hosts: localhost
  
  roles:
    - role: <role_name>
      vars:
        <role_name>_namespace: "my-namespace"
\`\`\`

## Testing

```bash
molecule test
```

## License

Apache-2.0
```

### CHANGELOG.md Format

```markdown
# Changelog

## [Unreleased]

### Added
- New features

### Changed
- Changes to existing functionality

### Fixed
- Bug fixes

## [1.0.0] - 2025-02-10

### Added
- Initial role implementation
```

---

## Quality Assurance

### Pre-commit Checklist

**MUST complete** before every commit:

- [ ] Code passes ansible-lint (production profile, from project root)
- [ ] Code passes yamllint
- [ ] Syntax check passes
- [ ] Python code formatted (if applicable)
- [ ] All tests pass
- [ ] Documentation updated
- [ ] CHANGELOG updated

### Code Review Requirements

**MUST pass** code review with:

- [ ] Proper FQCN usage
- [ ] Error handling implemented (block/rescue/always where needed)
- [ ] Variables properly scoped with role prefix
- [ ] Argument specs defined in meta/argument_specs.yml
- [ ] Tasks have meaningful names
- [ ] changed_when/failed_when defined for command/shell tasks
- [ ] no_log: true on sensitive data
- [ ] Documentation complete

---

## AAP Integration Guidelines

### Execution Environment Considerations

**Key differences from local development:**

- Code runs in containers, not on AAP host
- Dependencies must be in EE build
- No direct filesystem access
- Limited debugging capabilities

### Survey Variables vs Defaults

```yaml
# In role defaults/main.yml
<role_name>_namespace: "default"  # Can be overridden by survey

# In job template survey
- variable: <role_name>_namespace
  question: "Target Namespace"
  type: text
  required: true
```

### Brief AAP Notes

- **Execution Environments** replace direct system access
- **Credentials** injected at runtime
- **Job Templates** define playbook execution parameters
- **Surveys** collect user input before execution
- **Collection requirements** split into `collections/requirements.yml` and `roles/requirements.yml` for AAP auto-install

For detailed AAP configuration, see AAP administration documentation.

---

## Quick Reference

### Common Patterns Cheat Sheet

**Get Kubernetes Resource:**

```yaml
- name: Get resource
  kubernetes.core.k8s_info:
    api_version: v1
    kind: Pod
    namespace: default
  register: result
```

**Update Kubernetes Resource:**

```yaml
- name: Update resource
  kubernetes.core.k8s:
    api_version: apps/v1
    kind: Deployment
    name: my-app
    namespace: default
    definition:
      spec:
        replicas: 3
```

**Execute Command in Pod:**

```yaml
- name: Run command in pod
  kubernetes.core.k8s_exec:
    namespace: default
    pod: my-pod
    command: ls -la
  register: output
```

**Wait for Pod Ready:**

```yaml
- name: Wait for pod
  kubernetes.core.k8s_info:
    api_version: v1
    kind: Pod
    namespace: default
    name: my-pod
  register: pod
  until:
    - pod.resources[0].status.phase == 'Running'
  retries: 30
  delay: 10
```

**Error Handling Block:**

```yaml
- name: Operation with error handling
  block:
    - name: Main task
      ansible.builtin.command:
        cmd: /path/to/command
      register: cmd_result
      changed_when: cmd_result.rc == 0
  rescue:
    - name: Handle error
      ansible.builtin.debug:
        msg: "Failed: {{ ansible_failed_result.msg | default('unknown') }}"
  always:
    - name: Cleanup
      ansible.builtin.file:
        path: /tmp/file
        state: absent
```

### Command Reference

```bash
# Quality checks (from project root)
.venv/bin/ansible-lint --profile=production
.venv/bin/yamllint roles/ playbooks/
ansible-playbook --syntax-check playbook.yml

# Install dependencies
ansible-galaxy install -r requirements.yml

# Testing
ansible-playbook playbook.yml --check
ansible-playbook playbook.yml --tags preflight
ansible-playbook playbook.yml -vv

# Molecule testing
molecule test
molecule converge
molecule verify

# Python quality
.venv/bin/black roles/*/library/
.venv/bin/flake8 roles/*/library/

# EE-based testing
ansible-navigator run playbook.yml -m stdout --ee true
```

---

## Appendix: Standards Enforcement

### Mandatory Standards (MUST)

These are enforced by tooling and code review:

- Use FQCN for all modules
- Define changed_when/failed_when for shell/command
- Use block/rescue/always for operations needing cleanup or error recovery
- Follow role directory structure
- Include required documentation files
- Pass ansible-lint production profile (from project root)
- Pass syntax checks
- Use no_log: true for sensitive variables
- Pin collection and role versions in requirements.yml

### Recommended Standards (SHOULD)

These are best practices but may have justified exceptions:

- Use orchestrator pattern
- Implement preflight checks
- Use tag-based execution
- Define argument specs in meta/argument_specs.yml
- Create Molecule test scenarios
- Use kubernetes.core modules over oc commands
- Use ansible-navigator for EE validation
- Use ansible.builtin.command over ansible.builtin.shell for simple commands

### Optional Standards (MAY)

These are at developer discretion:

- Custom modules for complex operations
- Additional task file organization
- Extended monitoring patterns
- Performance optimizations
- Multiple Molecule scenarios per role

---

**Document Maintenance:**

This document should be reviewed quarterly and updated as standards evolve.

**Version History:**

- v2.0.0 (2026-07-03): Modernized for ansible-core 2.18/2.19 — added argument_specs.yml, Molecule testing, collection management, ansible-navigator, 2.19 data tagging awareness, no_log guidance, updated tool versions
- v1.0.0 (2025-02-10): Initial release

**Contributors:**

Platform Engineering Team

---

**End of Document**
