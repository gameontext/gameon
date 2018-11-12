{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "gameon-system.chart" -}}
{{- printf "%s-%s" $.Chart.Name $.Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Generate basic labels
*/}}
{{- define "gameon-system.labels" }}
    generator: helm
    date: {{ now | htmlDate }}
    chart: {{ template "gameon-system.chart" . }}
    release: {{ $.Release.Name }}
    heritage: {{ $.Release.Service }}
{{- end }}
