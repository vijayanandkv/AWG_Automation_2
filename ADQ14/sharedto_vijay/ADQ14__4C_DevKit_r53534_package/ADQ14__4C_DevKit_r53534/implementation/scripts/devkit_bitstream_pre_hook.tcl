# Downgrade timing loop check from error to warning to building with ADX
set_property SEVERITY {Warning} [get_drc_checks LUTLP-1]
