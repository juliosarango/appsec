# Hook de zap-baseline.py: antes de apagar ZAP, genera un reporte SARIF con la
# plantilla "sarif-json" del add-on oficial de reportes de ZAP.
# zap-baseline.py no tiene un flag para SARIF; así evitamos un conversor de terceros.


def zap_pre_shutdown(zap):
    zap.reports.generate(
        title="ZAP baseline",
        template="sarif-json",
        reportdir="/zap/wrk",
        reportfilename="zap.sarif",
    )
