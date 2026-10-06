# Hook de zap-baseline.py: antes de apagar ZAP, genera un reporte SARIF con la
# plantilla "sarif-json" del add-on oficial de reportes de ZAP.
# zap-baseline.py no tiene un flag para SARIF; así evitamos un conversor de terceros.
# GitHub Code scanning no lo acepta (las ubicaciones son URLs), pero sirve para
# plataformas que sí, y queda en el artifact zap-report.


def zap_pre_shutdown(zap):
    zap.reports.generate(
        title="ZAP baseline",
        template="sarif-json",
        reportdir="/zap/wrk",
        reportfilename="zap.sarif",
    )
