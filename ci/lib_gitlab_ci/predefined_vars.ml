(*****************************************************************************)
(*                                                                           *)
(* SPDX-License-Identifier: MIT                                              *)
(* Copyright (c) 2023 Nomadic Labs. <contact@nomadic-labs.com>               *)
(*                                                                           *)
(*****************************************************************************)

open If

let show = If.encode_var

let chat_channel = var "CHAT_CHANNEL"

let chat_input = var "CHAT_INPUT"

let chat_user_id = var "CHAT_USER_ID"

let ci = var "CI"

let ci_api_v4_url = var "CI_API_V4_URL"

let ci_api_graphql_url = var "CI_API_GRAPHQL_URL"

let ci_builds_dir = var "CI_BUILDS_DIR"

let ci_commit_author = var "CI_COMMIT_AUTHOR"

let ci_commit_before_sha = var "CI_COMMIT_BEFORE_SHA"

let ci_commit_branch = var "CI_COMMIT_BRANCH"

let ci_commit_description = var "CI_COMMIT_DESCRIPTION"

let ci_commit_message = var "CI_COMMIT_MESSAGE"

let ci_commit_ref_name = var "CI_COMMIT_REF_NAME"

let ci_commit_ref_protected = var "CI_COMMIT_REF_PROTECTED"

let ci_commit_ref_slug = var "CI_COMMIT_REF_SLUG"

let ci_commit_sha = var "CI_COMMIT_SHA"

let ci_commit_short_sha = var "CI_COMMIT_SHORT_SHA"

let ci_commit_tag = var "CI_COMMIT_TAG"

let ci_commit_tag_message = var "CI_COMMIT_TAG_MESSAGE"

let ci_commit_timestamp = var "CI_COMMIT_TIMESTAMP"

let ci_commit_title = var "CI_COMMIT_TITLE"

let ci_concurrent_id = var "CI_CONCURRENT_ID"

let ci_concurrent_project_id = var "CI_CONCURRENT_PROJECT_ID"

let ci_config_path = var "CI_CONFIG_PATH"

let ci_debug_trace = var "CI_DEBUG_TRACE"

let ci_debug_services = var "CI_DEBUG_SERVICES"

let ci_default_branch = var "CI_DEFAULT_BRANCH"

let ci_dependency_proxy_direct_group_image_prefix =
  var "CI_DEPENDENCY_PROXY_DIRECT_GROUP_IMAGE_PREFIX"

let ci_dependency_proxy_group_image_prefix =
  var "CI_DEPENDENCY_PROXY_GROUP_IMAGE_PREFIX"

let ci_dependency_proxy_password = var "CI_DEPENDENCY_PROXY_PASSWORD"

let ci_dependency_proxy_server = var "CI_DEPENDENCY_PROXY_SERVER"

let ci_dependency_proxy_user = var "CI_DEPENDENCY_PROXY_USER"

let ci_deploy_freeze = var "CI_DEPLOY_FREEZE"

let ci_deploy_password = var "CI_DEPLOY_PASSWORD"

let ci_deploy_user = var "CI_DEPLOY_USER"

let ci_disposable_environment = var "CI_DISPOSABLE_ENVIRONMENT"

let ci_environment_name = var "CI_ENVIRONMENT_NAME"

let ci_environment_slug = var "CI_ENVIRONMENT_SLUG"

let ci_environment_url = var "CI_ENVIRONMENT_URL"

let ci_environment_action = var "CI_ENVIRONMENT_ACTION"

let ci_environment_tier = var "CI_ENVIRONMENT_TIER"

let ci_release_description = var "CI_RELEASE_DESCRIPTION"

let ci_gitlab_fips_mode = var "CI_GITLAB_FIPS_MODE"

let ci_has_open_requirements = var "CI_HAS_OPEN_REQUIREMENTS"

let ci_job_id = var "CI_JOB_ID"

let ci_job_image = var "CI_JOB_IMAGE"

let ci_job_manual = var "CI_JOB_MANUAL"

let ci_job_name = var "CI_JOB_NAME"

let ci_job_name_slug = var "CI_JOB_NAME_SLUG"

let ci_job_stage = var "CI_JOB_STAGE"

let ci_job_status = var "CI_JOB_STATUS"

let ci_job_timeout = var "CI_JOB_TIMEOUT"

let ci_job_token = var "CI_JOB_TOKEN"

let ci_job_url = var "CI_JOB_URL"

let ci_job_started_at = var "CI_JOB_STARTED_AT"

let ci_kubernetes_active = var "CI_KUBERNETES_ACTIVE"

let ci_node_index = var "CI_NODE_INDEX"

let ci_node_total = var "CI_NODE_TOTAL"

let ci_open_merge_requests = var "CI_OPEN_MERGE_REQUESTS"

let ci_pages_domain = var "CI_PAGES_DOMAIN"

let ci_pages_url = var "CI_PAGES_URL"

let ci_pipeline_id = var "CI_PIPELINE_ID"

let ci_pipeline_iid = var "CI_PIPELINE_IID"

let ci_pipeline_source = var "CI_PIPELINE_SOURCE"

let ci_pipeline_triggered = var "CI_PIPELINE_TRIGGERED"

let ci_pipeline_url = var "CI_PIPELINE_URL"

let ci_pipeline_created_at = var "CI_PIPELINE_CREATED_AT"

let ci_pipeline_name = var "CI_PIPELINE_NAME"

let ci_project_dir = var "CI_PROJECT_DIR"

let ci_project_id = var "CI_PROJECT_ID"

let ci_project_name = var "CI_PROJECT_NAME"

let ci_project_namespace = var "CI_PROJECT_NAMESPACE"

let ci_project_namespace_id = var "CI_PROJECT_NAMESPACE_ID"

let ci_project_path_slug = var "CI_PROJECT_PATH_SLUG"

let ci_project_path = var "CI_PROJECT_PATH"

let ci_project_repository_languages = var "CI_PROJECT_REPOSITORY_LANGUAGES"

let ci_project_root_namespace = var "CI_PROJECT_ROOT_NAMESPACE"

let ci_project_title = var "CI_PROJECT_TITLE"

let ci_project_description = var "CI_PROJECT_DESCRIPTION"

let ci_project_url = var "CI_PROJECT_URL"

let ci_project_visibility = var "CI_PROJECT_VISIBILITY"

let ci_project_classification_label = var "CI_PROJECT_CLASSIFICATION_LABEL"

let ci_registry = var "CI_REGISTRY"

let ci_registry_image = var "CI_REGISTRY_IMAGE"

let ci_registry_password = var "CI_REGISTRY_PASSWORD"

let ci_registry_user = var "CI_REGISTRY_USER"

let ci_repository_url = var "CI_REPOSITORY_URL"

let ci_runner_description = var "CI_RUNNER_DESCRIPTION"

let ci_runner_executable_arch = var "CI_RUNNER_EXECUTABLE_ARCH"

let ci_runner_id = var "CI_RUNNER_ID"

let ci_runner_revision = var "CI_RUNNER_REVISION"

let ci_runner_short_token = var "CI_RUNNER_SHORT_TOKEN"

let ci_runner_tags = var "CI_RUNNER_TAGS"

let ci_runner_version = var "CI_RUNNER_VERSION"

let ci_server_host = var "CI_SERVER_HOST"

let ci_server_name = var "CI_SERVER_NAME"

let ci_server_port = var "CI_SERVER_PORT"

let ci_server_protocol = var "CI_SERVER_PROTOCOL"

let ci_server_shell_ssh_host = var "CI_SERVER_SHELL_SSH_HOST"

let ci_server_shell_ssh_port = var "CI_SERVER_SHELL_SSH_PORT"

let ci_server_revision = var "CI_SERVER_REVISION"

let ci_server_tls_ca_file = var "CI_SERVER_TLS_CA_FILE"

let ci_server_tls_cert_file = var "CI_SERVER_TLS_CERT_FILE"

let ci_server_tls_key_file = var "CI_SERVER_TLS_KEY_FILE"

let ci_server_url = var "CI_SERVER_URL"

let ci_server_version_major = var "CI_SERVER_VERSION_MAJOR"

let ci_server_version_minor = var "CI_SERVER_VERSION_MINOR"

let ci_server_version_patch = var "CI_SERVER_VERSION_PATCH"

let ci_server_version = var "CI_SERVER_VERSION"

let ci_server = var "CI_SERVER"

let ci_shared_environment = var "CI_SHARED_ENVIRONMENT"

let ci_template_registry_host = var "CI_TEMPLATE_REGISTRY_HOST"

let gitlab_ci = var "GITLAB_CI"

let gitlab_features = var "GITLAB_FEATURES"

let gitlab_user_email = var "GITLAB_USER_EMAIL"

let gitlab_user_id = var "GITLAB_USER_ID"

let gitlab_user_login = var "GITLAB_USER_LOGIN"

let gitlab_user_name = var "GITLAB_USER_NAME"

let kubeconfig = var "KUBECONFIG"

let trigger_payload = var "TRIGGER_PAYLOAD"

let ci_merge_request_approved = var "CI_MERGE_REQUEST_APPROVED"

let ci_merge_request_assignees = var "CI_MERGE_REQUEST_ASSIGNEES"

let ci_merge_request_diff_base_sha = var "CI_MERGE_REQUEST_DIFF_BASE_SHA"

let ci_merge_request_diff_id = var "CI_MERGE_REQUEST_DIFF_ID"

let ci_merge_request_event_type = var "CI_MERGE_REQUEST_EVENT_TYPE"

let ci_merge_request_description = var "CI_MERGE_REQUEST_DESCRIPTION"

let ci_merge_request_description_is_truncated =
  var "CI_MERGE_REQUEST_DESCRIPTION_IS_TRUNCATED"

let ci_merge_request_id = var "CI_MERGE_REQUEST_ID"

let ci_merge_request_iid = var "CI_MERGE_REQUEST_IID"

let ci_merge_request_labels = var "CI_MERGE_REQUEST_LABELS"

let ci_merge_request_milestone = var "CI_MERGE_REQUEST_MILESTONE"

let ci_merge_request_project_id = var "CI_MERGE_REQUEST_PROJECT_ID"

let ci_merge_request_project_path = var "CI_MERGE_REQUEST_PROJECT_PATH"

let ci_merge_request_project_url = var "CI_MERGE_REQUEST_PROJECT_URL"

let ci_merge_request_ref_path = var "CI_MERGE_REQUEST_REF_PATH"

let ci_merge_request_source_branch_name =
  var "CI_MERGE_REQUEST_SOURCE_BRANCH_NAME"

let ci_merge_request_source_branch_protected =
  var "CI_MERGE_REQUEST_SOURCE_BRANCH_PROTECTED"

let ci_merge_request_source_branch_sha =
  var "CI_MERGE_REQUEST_SOURCE_BRANCH_SHA"

let ci_merge_request_source_project_id =
  var "CI_MERGE_REQUEST_SOURCE_PROJECT_ID"

let ci_merge_request_source_project_path =
  var "CI_MERGE_REQUEST_SOURCE_PROJECT_PATH"

let ci_merge_request_source_project_url =
  var "CI_MERGE_REQUEST_SOURCE_PROJECT_URL"

let ci_merge_request_squash_on_merge = var "CI_MERGE_REQUEST_SQUASH_ON_MERGE"

let ci_merge_request_target_branch_name =
  var "CI_MERGE_REQUEST_TARGET_BRANCH_NAME"

let ci_merge_request_target_branch_protected =
  var "CI_MERGE_REQUEST_TARGET_BRANCH_PROTECTED"

let ci_merge_request_target_branch_sha =
  var "CI_MERGE_REQUEST_TARGET_BRANCH_SHA"

let ci_merge_request_title = var "CI_MERGE_REQUEST_TITLE"
