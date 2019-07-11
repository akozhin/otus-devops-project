{{- define "search-ui.fullname" -}}
{{- printf "%s-%s" .Release.Name .Chart.Name }}
{{- end -}}
