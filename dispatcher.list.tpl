# setid(int) destination(sip uri) flags(int,opt) priority(int,opt) attributes(str,opt)
{{ range $service := service "sip-b2bua" -}}
100 sip:{{ .Address }}:5080 2 0 socket=udp:{{ KAM_PRIVATE_IP }}:5066;{{ .Node }}
{{ end -}}