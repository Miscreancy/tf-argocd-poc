{{/* vim: set filetype=mustache: */}}
{{ define "kafka_source" }}
audit_input:
    type: kafka
    bootstrap_servers: {{ .Values.vector.kafka_source.bootstrap_servers }}
    group_id: {{ .Values.vector.kafka_source.group_id }}
    key_field: message_key
    decoding:
      codec: bytes
    sasl:
      enabled: true
      mechanism: PLAIN
      username: {{ .Values.vector.kafka_source.auth.username }}
      password: {{ .Values.vector.kafka_source.auth.password }}
    librdkafka_options:
      security.protocol: SASL_SSL
      enable.auto.offset.store: "false"
    session_timeout_ms: 45000
    auto_offset_reset: beginning
    topics: 
      - {{ .Values.vector.kafka_source.topic }}
{{- end }}

{{ define "vector_source" }}
audit_input:
    type: vector
    version: "2"
    address: 0.0.0.0:6000
{{- end }}
{{ define "controlplane_parser" }}
    .message, err = parse_json(.message)
    if err == null {
      .message.message_key, err = parse_json(.message_key)
      .message = merge!(.message, .message.message_key)
      if err != null {
        log("error parsing message.message_key: " + err, level: "error", rate_limit_secs: 1)
      }
      
      if .message.event != null {
        .message.event, err = parse_json(.message.event)
        if err == null {
          if .message.event.policy != null {
            .message.event.policy, err = parse_json(.message.event.policy)
            if err != null {
              log("error parsing message.event.policy: " + err, level: "error", rate_limit_secs: 1)
            }
          }
        } else {
          log("error parsing message.event: " + err, level: "error", rate_limit_secs: 1)
        }
      }
    } else {
      log("error parsing message: " + err, level: "error", rate_limit_secs: 1)
    }
{{- end -}}
{{ define "dataplane_parser" }}
        #log("Processing OPA decision log… ") 
{{- end -}}
{{ define "controlplane_event_cleaner_source" }}
          del(.message.headers)
          del(.message.message_key)
          .message.timestamp = to_timestamp!(.message.event_time, unit: "milliseconds")
          del(.message.event_time)
          del(.message.event_date)
          del(.message.source_type)
{{- end -}}
{{ define "dataplane_event_cleaner_source" }}
          del(.cloud.accountID)
          del(.cluster)
          del(.fluent_host)
          del(.fluent_tag)
          del(.fluent_ts)
          del(.kubernetes)
          del(.format)
          del(.format_specified)
          del(."k8s-app")
          del(."k8s-container_image")
          del(."k8s-container_name")
          del(."k8s-host")
          del(."k8s-labels-pod-template-hash")
          del(."k8s-namespace_name")
          del(."k8s-pod_name")
          del(.message_key)
          del(.event_time)
          del(.event_date)
          del(.source_type)
          del(.source_file)
          del(.stream)
          del(.raw_message) 
          del(.throttle_cap)
          del(.throttle_key)
          del(.metrics)
{{- end -}}
{{ define "cp_auth_manager_structuring" }}
          .message.schema_version = 1 # hardcode
          .message.system_type = "auth_manager" # hardcode
          .message.event_category = "Authorization" # hardcode
          .message.event_result = del(.message.action_result)
{{- end -}}
{{ define "dp_opa_structuring" }}
          .message.schema_version = 1 # hardcode
          .message.system_type = "OPA" # hardcode
          .message.event_category = "Authorization" # hardcode
          .message.event_id = .decision_id
          .message.timestamp = .time
          .message.org_id = .input.org_id
          .message.user_id = .input.user_id
          event_type, err = join(.input.actions, separator: ", ")
          if err != null {
             .message.event_type = event_type
          } else {
            .message.event_type = ""
          }
          .message.event_result = .result
          .message.user_ip = .requested_by
          . = .message
{{- end -}}